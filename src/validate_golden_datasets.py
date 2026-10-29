
from pathlib import Path
import pandas as pd

ROOT = Path(__file__).resolve().parents[1]
GOLDEN = ROOT / "data" / "golden"
REPORTS = ROOT / "reports"
REPORTS.mkdir(parents=True, exist_ok=True)


def load(name):
    path = GOLDEN / name
    if not path.exists():
        raise FileNotFoundError(f"Missing candidate: {path}")
    return pd.read_csv(path)


accounts = load("accounts_golden_candidate.csv")
borrowers = load("borrowers_golden_candidate.csv")
payments = load("payments_golden_candidate.csv")

checks = [
    ("Accounts rows", len(accounts), 30_000),
    ("Unique account IDs", accounts["account_id"].nunique(), 30_000),
    ("Missing account borrower IDs",
     int(accounts["borrower_id_missing"].sum()), 455),
    ("Outstanding exceeds principal",
     int(accounts["outstanding_exceeds_principal"].sum()), 13_029),
    ("Borrower candidate rows", len(borrowers), 30_000),
    ("Unique borrower IDs", borrowers["borrower_id"].nunique(), 11_015),
    ("Payment candidate rows", len(payments), 25_000),
    ("Unique payment IDs", payments["payment_id"].nunique(), 25_000),
    ("Missing payment references",
     int(payments["payment_reference_missing"].sum()), 368),
    ("Payment borrower mismatches",
     int(payments["borrower_id_mismatch"].sum()), 24_617),
    ("Invalid payment timestamps",
     int(payments["event_at_invalid"].sum()), 0),
]

results = []

for label, actual, expected in checks:
    results.append({
        "check": label,
        "actual_value": int(actual),
        "expected_value": int(expected),
        "passed": actual == expected,
    })

results.append({
    "check": "Borrower profile-conflict rows (informational)",
    "actual_value": int(borrowers["borrower_profile_conflict"].sum()),
    "expected_value": None,
    "passed": None,
})

report = pd.DataFrame(results)
output_path = REPORTS / "golden_dataset_validation_report.csv"
report.to_csv(output_path, index=False)

print(report.to_string(index=False))
failed = report[
    report["passed"].eq(False)
]

if not failed.empty:
    raise AssertionError(
        "Validation failed: "
        + ", ".join(failed["check"].tolist())
    )

print(f"\nSaved validation report: {output_path.relative_to(ROOT)}")
print("All expected validation checks passed.")
