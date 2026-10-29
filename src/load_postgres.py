from pathlib import Path
import csv
import getpass
import duckdb
import psycopg
from psycopg import sql

ROOT = Path(__file__).resolve().parents[1]
DB_NAME = "credresolve_assignment"
USER = "postgres"
PASSWORD = getpass.getpass("PostgreSQL password: ")

def pg_type(dtype):
    t = dtype.upper()
    if "BOOL" in t:
        return "BOOLEAN"
    if "TIMESTAMP WITH TIME ZONE" in t:
        return "TIMESTAMPTZ"
    if "TIMESTAMP" in t:
        return "TIMESTAMP"
    if t == "DATE":
        return "DATE"
    if t.startswith("DECIMAL") or t.startswith("NUMERIC"):
        return t
    if t in ("BIGINT", "UBIGINT", "HUGEINT"):
        return "NUMERIC(38,0)"
    if t in ("INTEGER", "UINTEGER"):
        return "INTEGER"
    if t in ("SMALLINT", "TINYINT", "USMALLINT", "UTINYINT"):
        return "SMALLINT"
    if t in ("DOUBLE", "FLOAT", "REAL", "FLOAT4", "FLOAT8"):
        return "DOUBLE PRECISION"
    return "TEXT"

def create_table(cur, schema, table, columns):
    cur.execute(
        sql.SQL("DROP TABLE IF EXISTS {}.{} CASCADE").format(
            sql.Identifier(schema), sql.Identifier(table)
        )
    )
    definitions = sql.SQL(", ").join(
        sql.SQL("{} {}").format(sql.Identifier(name), sql.SQL(dtype))
        for name, dtype in columns
    )
    cur.execute(
        sql.SQL("CREATE TABLE {}.{} ({})").format(
            sql.Identifier(schema), sql.Identifier(table), definitions
        )
    )

def load_csv(cur, db, file, schema, table, all_text=False):
    # Infer typed columns with DuckDB; raw schema retains text values.
    if all_text:
        with file.open("r", encoding="utf-8-sig", newline="") as f:
            headers = next(csv.reader(f))
        columns = [(h, "TEXT") for h in headers]
    else:
        path = file.resolve().as_posix().replace("'", "''")
        description = db.execute(
            f"DESCRIBE SELECT * FROM read_csv_auto('{path}', "
            "header=true, sample_size=-1)"
        ).fetchall()
        columns = [(row[0], pg_type(row[1])) for row in description]

    create_table(cur, schema, table, columns)
    copy_sql = sql.SQL(
        "COPY {}.{} FROM STDIN WITH (FORMAT CSV, HEADER TRUE, NULL '')"
    ).format(sql.Identifier(schema), sql.Identifier(table))

    with cur.copy(copy_sql) as copy:
        copy.write(file.read_text(encoding="utf-8-sig").encode("utf-8"))

    count = cur.execute(
        sql.SQL("SELECT COUNT(*) FROM {}.{}").format(
            sql.Identifier(schema), sql.Identifier(table)
        )
    ).fetchone()[0]
    print(f"Loaded {schema}.{table}: {count:,} rows")

def main():
    raw_dir = ROOT / "data" / "raw"
    staging_dir = ROOT / "data" / "staging"
    golden_dir = ROOT / "data" / "golden"

    if not raw_dir.exists() or not golden_dir.exists():
        raise FileNotFoundError(
            "Expected data/raw and data/golden under project root: " + str(ROOT)
        )

    db = duckdb.connect()
    conn = psycopg.connect(
        host="localhost",
        port=5432,
        dbname=DB_NAME,
        user=USER,
        password=PASSWORD,
    )

    try:
        with conn.cursor() as cur:
            for schema in ("raw", "staging", "golden"):
                cur.execute(
                    sql.SQL("CREATE SCHEMA IF NOT EXISTS {}").format(
                        sql.Identifier(schema)
                    )
                )

            # Raw source copies: all columns TEXT; original CSV files stay untouched.
            for file in sorted(raw_dir.glob("*.csv")):
                load_csv(cur, db, file, "raw", file.stem.lower(), all_text=True)

            # Typed staging tables from source CSVs.
            for file in sorted(raw_dir.glob("*.csv")):
                load_csv(cur, db, file, "staging", file.stem.lower())

            # SQL repository expects this explicit raw-payment table name.
            payments_file = raw_dir / "payments.csv"
            if payments_file.exists():
                load_csv(cur, db, payments_file, "staging", "payments_raw")

            # Reconciled staging candidates, if present.
            if staging_dir.exists():
                for file in sorted(staging_dir.glob("*.csv")):
                    load_csv(cur, db, file, "staging", file.stem.lower())

            # Golden candidates used by the SQL repository.
            for file in sorted(golden_dir.glob("*.csv")):
                load_csv(cur, db, file, "golden", file.stem.lower())

        conn.commit()
        print("\nSUCCESS: CSV tables loaded into PostgreSQL.")
        print("Raw CSV files were not modified.")
    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()
        db.close()

if __name__ == "__main__":
    main()
