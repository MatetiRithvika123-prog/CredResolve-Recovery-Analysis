
from pathlib import Path
import json
import pandas as pd


# ------------------------------------------------------------
# Paths
# This script assumes it is run from the project root.
# ------------------------------------------------------------

ROOT = Path(__file__).resolve().parents[1]
RAW_DIR = ROOT / "data" / "raw"
GOLDEN_DIR = ROOT / "data" / "golden"
REPORTS_DIR = ROOT / "reports"

GOLDEN_DIR.mkdir(parents=True, exist_ok=True)
REPORTS_DIR.mkdir(parents=True, exist_ok=True)


def require_columns(df, columns, dataset_name):
    """Fail clearly when the input schema is unexpected."""
    missing = sorted(set(columns) - set(df.columns))
    if missing:
        raise ValueError(
            f"{dataset_name} is missing required columns: {missing}"
        )


def load_csv(filename):
    path = RAW_DIR / filename
    if not path.exists():
        raise FileNotFoundError(f"Required raw file not found: {path}")
    return pd.read_csv(path)


def save_candidate(df, filename, dataset_name, source_rows):
    """Save a candidate and record basic reconciliation metrics."""
    path = GOLDEN_DIR / filename
    df.to_csv(path, index=False)

    primary_key = {
        "accounts": "account_id",
        "borrowers": "borrower_id",
        "payments": "payment_id",
    }[dataset_name]

    summary = {
        "dataset": dataset_name,
        "source_rows": int(source_rows),
        "candidate_rows": int(len(df)),
        "candidate_unique_primary_keys": int(df[primary_key].nunique()),
        "candidate_duplicate_primary_key_rows": int(
            df[primary_key].duplicated(keep=False).sum()
        ),
        "output_file": str(path.relative_to(ROOT)),
    }
    return summary


def build_accounts():
    raw = load_csv("accounts.csv")
    require_columns(
        raw,
        [
            "account_id", "borrower_id", "principal_amount",
            "outstanding_amount", "opened_at"
        ],
        "accounts.csv",
    )

    df = raw.copy()
    df["opened_at"] = pd.to_datetime(df["opened_at"], errors="coerce")

    df["borrower_id_missing"] = (
        df["borrower_id"].isna()
        | df["borrower_id"].astype("string").str.strip().eq("")
    )
    df["opened_at_invalid"] = df["opened_at"].isna()
    df["outstanding_exceeds_principal"] = (
        pd.to_numeric(df["outstanding_amount"], errors="coerce")
        > pd.to_numeric(df["principal_amount"], errors="coerce")
    )

    # Account IDs were unique in the source audit; fail instead of
    # silently choosing a record if this assumption changes.
    if df["account_id"].duplicated().any():
        raise ValueError("Duplicate account_id values found in accounts.csv")

    return df, len(raw)


def build_borrowers():
    raw = load_csv("borrowers.csv")
    require_columns(
        raw,
        [
            "borrower_id", "name", "phone", "email",
            "city", "state"
        ],
        "borrowers.csv",
    )

    # Remove exact duplicate rows only. Conflicting profiles remain.
    df = raw.drop_duplicates().copy()

    profile_columns = ["name", "phone", "email", "city", "state"]

    # Group-level conflict flags: each remaining row for a conflicting
    # borrower is flagged; this does not select an authoritative profile.
    distinct_profiles = (
        df.groupby("borrower_id", dropna=False)[profile_columns]
        .nunique(dropna=False)
    )
    conflict_ids = distinct_profiles.index[
        distinct_profiles.gt(1).any(axis=1)
    ]

    df["borrower_profile_conflict"] = df["borrower_id"].isin(conflict_ids)
    df["phone_missing"] = (
        df["phone"].isna()
        | df["phone"].astype("string").str.strip().eq("")
    )
    df["email_missing"] = (
        df["email"].isna()
        | df["email"].astype("string").str.strip().eq("")
    )

    # Do not force one row per borrower: the raw data contains conflicting
    # profiles and lacks an authoritative version/effective-date rule.
    return df, len(raw)


def build_payments():
    raw = load_csv("payments.csv")
    require_columns(
        raw,
        [
            "payment_id", "account_id", "borrower_id",
            "payment_reference", "event_at", "amount", "payment_status"
        ],
        "payments.csv",
    )

    df = raw.copy()

    # Reconcile duplicate payment IDs using the audited rule:
    # prefer a populated payment reference, then keep the first row.
    # The source audit found no conflicts in the other checked fields
    # within duplicate payment-ID groups. If that changes, stop for review.
    duplicate_groups = df[df.duplicated("payment_id", keep=False)]

    conflict_columns = [
        col for col in [
            "account_id", "borrower_id", "event_at", "amount",
            "payment_status", "method", "provider"
        ] if col in df.columns
    ]

    if not duplicate_groups.empty:
        conflicts = (
            duplicate_groups.groupby("payment_id")[conflict_columns]
            .nunique(dropna=False)
            .gt(1)
            .any(axis=1)
        )
        if conflicts.any():
            examples = conflicts[conflicts].index[:10].tolist()
            raise ValueError(
                "Conflicting duplicate payment IDs require review. "
                f"Example IDs: {examples}"
            )

    df["_reference_populated"] = (
        df["payment_reference"].notna()
        & df["payment_reference"].astype("string").str.strip().ne("")
    )
    df = df.sort_values(
        ["_reference_populated"],
        ascending=False,
        kind="stable",
    )
    df = df.drop_duplicates("payment_id", keep="first")
    df = df.drop(columns="_reference_populated")

    df["event_at"] = pd.to_datetime(df["event_at"], errors="coerce")

    # Account master has one row per account_id.
    accounts = load_csv("accounts.csv")
    require_columns(accounts, ["account_id", "borrower_id"], "accounts.csv")

    if accounts["account_id"].duplicated().any():
        raise ValueError("Cannot join payments: account_id is not unique")

    account_lookup = accounts[["account_id", "borrower_id"]].rename(
        columns={"borrower_id": "account_master_borrower_id"}
    )

    df = df.merge(
        account_lookup,
        on="account_id",
        how="left",
        validate="many_to_one",
        indicator="_account_join",
    )

    df["account_id_valid"] = df["_account_join"].eq("both")
    df["borrower_id_mismatch"] = (
        df["borrower_id"].notna()
        & df["account_master_borrower_id"].notna()
        & df["borrower_id"].ne(df["account_master_borrower_id"])
    )
    df["payment_reference_missing"] = (
        df["payment_reference"].isna()
        | df["payment_reference"].astype("string").str.strip().eq("")
    )
    df["event_at_invalid"] = df["event_at"].isna()

    df = df.drop(columns=["_account_join"])

    return df, len(raw)


def main():
    summaries = []

    accounts, source_count = build_accounts()
    summaries.append(
        save_candidate(
            accounts, "accounts_golden_candidate.csv",
            "accounts", source_count
        )
    )

    borrowers, source_count = build_borrowers()
    summaries.append(
        save_candidate(
            borrowers, "borrowers_golden_candidate.csv",
            "borrowers", source_count
        )
    )

    payments, source_count = build_payments()
    summaries.append(
        save_candidate(
            payments, "payments_golden_candidate.csv",
            "payments", source_count
        )
    )

    summary_path = REPORTS_DIR / "golden_pipeline_summary.json"
    summary_path.write_text(
        json.dumps(summaries, indent=2),
        encoding="utf-8",
    )

    print("Golden candidate pipeline completed.")
    for item in summaries:
        print(
            f"{item['dataset']}: "
            f"{item['source_rows']:,} source rows -> "
            f"{item['candidate_rows']:,} candidate rows; "
            f"{item['candidate_unique_primary_keys']:,} unique keys"
        )
        print(f"  Output: {item['output_file']}")

    print(f"Summary: {summary_path.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
