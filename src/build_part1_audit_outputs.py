
"""Create Part 1 cleaning-traceability outputs."""
from pathlib import Path
import pandas as pd

ROOT = Path(__file__).resolve().parents[1]
RAW = ROOT / "data" / "raw"
GOLDEN = ROOT / "data" / "golden"
QUARANTINE = ROOT / "data" / "quarantine"
REPORTS = ROOT / "reports"

QUARANTINE.mkdir(parents=True, exist_ok=True)
REPORTS.mkdir(parents=True, exist_ok=True)

# 1. Preserve excess rows from duplicate payment IDs.
raw = pd.read_csv(RAW / "payments.csv", dtype={"payment_id": "string"})

required = {"payment_id", "payment_reference"}
if not required.issubset(raw.columns):
    raise ValueError(f"payments.csv must contain {required}")

raw["_source_row_number"] = range(2, len(raw) + 2)
raw["_reference_populated"] = (
    raw["payment_reference"].notna()
    & raw["payment_reference"].astype("string").str.strip().ne("")
)

ordered = raw.sort_values(
    "_reference_populated", ascending=False, kind="stable"
)
keep_index = ordered.drop_duplicates("payment_id", keep="first").index
excess = raw.loc[~raw.index.isin(keep_index)].copy()

excess["disposition"] = "QUARANTINED_DUPLICATE_PAYMENT_ID_EXCESS_ROW"
excess["disposition_reason"] = (
    "Another row with the same payment_id was retained. "
    "Review the duplicate group before reuse."
)
excess.drop(columns=["_reference_populated"]).to_csv(
    QUARANTINE / "payments_duplicate_id_excess_rows.csv",
    index=False
)

# 2. Export borrower-attribution mismatches for investigation.
golden = pd.read_csv(
    GOLDEN / "payments_golden_candidate.csv",
    dtype={"payment_id": "string"}
)

if "borrower_id_mismatch" not in golden.columns:
    raise ValueError(
        "borrower_id_mismatch is missing. Check the existing pipeline output."
    )

mismatch_flag = (
    golden["borrower_id_mismatch"]
    .fillna(False)
    .astype(bool)
)
mismatch = golden[mismatch_flag].copy()
mismatch["disposition"] = "QUARANTINED_FOR_BORROWER_ATTRIBUTION"
mismatch["disposition_reason"] = (
    "Payment borrower_id conflicts with the current account-master "
    "borrower_id. Reconcile before borrower-level attribution."
)
mismatch.to_csv(
    QUARANTINE / "payments_borrower_attribution_mismatch.csv",
    index=False
)

# 3. Export unknown account IDs, if any.
if "account_id_valid" in golden.columns:
    valid_account = (
        golden["account_id_valid"].fillna(False).astype(bool)
    )
    invalid_account = golden[~valid_account].copy()
else:
    invalid_account = pd.DataFrame(columns=list(golden.columns))

invalid_account["disposition"] = "QUARANTINED_UNKNOWN_ACCOUNT_ID"
invalid_account["disposition_reason"] = (
    "Payment account_id does not match the account master."
)
invalid_account.to_csv(
    QUARANTINE / "payments_unknown_account_id.csv",
    index=False
)

# 4. Compare raw and candidate row counts.
accounts_raw = pd.read_csv(RAW / "accounts.csv")
borrowers_raw = pd.read_csv(RAW / "borrowers.csv")
accounts_candidate = pd.read_csv(
    GOLDEN / "accounts_golden_candidate.csv"
)
borrowers_candidate = pd.read_csv(
    GOLDEN / "borrowers_golden_candidate.csv"
)

missing_refs = (
    golden["payment_reference_missing"].fillna(False).astype(bool).sum()
    if "payment_reference_missing" in golden.columns else 0
)
invalid_times = (
    golden["event_at_invalid"].fillna(False).astype(bool).sum()
    if "event_at_invalid" in golden.columns else 0
)

rows = [
    [
        "Payments total rows", len(raw), len(golden),
        len(raw) - len(golden),
        "Excess rows removed from candidate by payment_id deduplication."
    ],
    [
        "Payment duplicate-ID excess rows",
        int(raw["payment_id"].duplicated().sum()),
        len(excess), len(excess),
        "Excess rows saved for review; not counted as independent events."
    ],
    [
        "Payment borrower-ID mismatches", "Not applicable",
        len(mismatch), len(mismatch),
        "Flagged; borrower attribution remains unresolved."
    ],
    [
        "Payment unknown account IDs", "Not applicable",
        len(invalid_account), len(invalid_account),
        "Zero means account IDs match, not that borrower attribution is correct."
    ],
    [
        "Payment missing references", "Not applicable",
        int(missing_refs), int(missing_refs),
        "Retained; missing reference alone does not prove invalidity."
    ],
    [
        "Payment invalid/unparseable timestamps", "Not applicable",
        int(invalid_times), int(invalid_times),
        "A valid parse does not prove the timezone is known."
    ],
    [
        "Account rows", len(accounts_raw), len(accounts_candidate),
        len(accounts_raw) - len(accounts_candidate),
        "Account IDs must be unique; investigate duplicates."
    ],
    [
        "Borrower rows after exact-row deduplication",
        len(borrowers_raw), len(borrowers_candidate),
        len(borrowers_raw) - len(borrowers_candidate),
        "Exact duplicates removed; conflicting profiles require review."
    ]
]

impact = pd.DataFrame(rows, columns=[
    "dataset_or_issue",
    "raw_rows_or_count",
    "candidate_or_exception_rows",
    "quantified_impact",
    "treatment_or_interpretation"
])
impact["status"] = "Measured"
impact.to_csv(REPORTS / "part1_cleaning_impact.csv", index=False)

print("Part 1 audit outputs created.")
print(f"Payments: {len(raw):,} raw -> {len(golden):,} candidate")
print(f"Duplicate excess rows: {len(excess):,}")
print(f"Borrower mismatches: {len(mismatch):,}")
print(f"Unknown account IDs: {len(invalid_account):,}")
print("See data/quarantine/ and reports/part1_cleaning_impact.csv")
