# Part 1 — Golden Dataset Methodology and Cleaning Trail

## 1. Status and purpose

The purpose of this process is to create a more reliable analytical layer from the company-provided raw data.

The output is a **candidate Golden Dataset**, not a claim that every source record is correct. Raw source files are preserved. Records with unresolved conflicts are flagged or separated for review rather than silently corrected.

## 2. Data flow

**Raw Records → Staging and Cleaning → Rejected/Quarantined or Corrected Records → Golden Dataset Candidate**

- Raw input files are stored in `data/raw/`.
- Candidate analytical datasets are stored in `data/golden/`.
- Records requiring investigation are stored in `data/quarantine/`.
- Cleaning impact counts are documented in `reports/part1_cleaning_impact.csv`.

The quarantine files preserve records that should not be trusted for a particular analysis until the relevant issue is resolved. A quarantined record is not automatically proof of an invalid business event.

## 3. Source-of-truth decisions

- **Payments:** `payments.csv` is the source of payment-event records. A `SUCCESS` status alone does not prove verified net recovery because reversal linkage and borrower attribution remain uncertain.
- **Accounts:** `accounts.csv` is used as the current reference for account IDs and current borrower IDs. It does not necessarily prove historical account ownership.
- **Borrowers:** `borrowers.csv` contains repeated and conflicting profiles. Exact duplicate rows can be removed, but conflicting profiles are flagged rather than choosing an arbitrary profile.
- **Agents:** Current agent attributes are not assumed to represent an agent's historical identity, team, vendor or employment status when reliable effective-dated history is unavailable.
- **Events and histories:** Event timestamps and recorded timestamps are treated as distinct fields unless their meanings are confirmed by the source.

## 4. Entity resolution and payment attribution

Entity resolution means checking whether records from different tables refer to the same account, borrower, payment or agent.

- `payment_id` is used as the payment-event deduplication key.
- A repeated `payment_reference` alone is not treated as proof that two rows represent the same payment.
- Payment `account_id` values are checked against the account master.
- Payment `borrower_id` values are compared with the current account-master borrower ID.
- Borrower-ID mismatches are flagged and exported to `data/quarantine/payments_borrower_attribution_mismatch.csv`.
- Unknown account IDs, if present, are exported to `data/quarantine/payments_unknown_account_id.csv`.
- Payments with unresolved borrower attribution must not be used as confidently attributed borrower-level outcomes until the mismatch is reconciled.

## 5. Deduplication logic

### Payments

The candidate dataset contains one row per `payment_id`. Where duplicate IDs exist, the existing pipeline prefers a row with a populated payment reference and preserves original order as the tie-breaker.

Excess rows are preserved in `data/quarantine/payments_duplicate_id_excess_rows.csv`. They should be reviewed before being treated as definitively erroneous, especially if fields conflict.

A repeated payment reference is not sufficient reason to delete a payment because references may be reused or inconsistent.

### Borrowers

Exact duplicate rows are removed. Conflicting borrower profiles are retained and flagged because the source does not establish which profile is authoritative.

### Accounts

`account_id` is expected to be unique. Duplicate account IDs should trigger an error for investigation rather than silently selecting an arbitrary row.

### Other event tables

Calls, call attempts, messages, promises to pay and other event datasets have their own identifiers and reconciliation rules. The payment deduplication rule must not be applied automatically to every table.

## 6. Missing-data treatment and exclusions

- Missing payment references are flagged but retained because a missing reference alone does not prove a payment is invalid.
- Missing borrower IDs are not fabricated.
- Conflicting borrower IDs are not automatically overwritten with the current account-master value.
- Records with unresolved relationships are excluded from analyses that require verified attribution, while remaining available for investigation where appropriate.
- Raw records are preserved; cleaning decisions are applied to derived outputs.
- Exclusions are purpose-specific. A payment may be retained in a payment-event dataset but excluded from a borrower-level or causal recovery calculation.

## 7. Timestamp treatment

Timestamps are parsed to identify invalid or unparseable values.

The supplied payment timestamps are timezone-naive. The correct source timezone has not been confirmed. Therefore, successful parsing does not establish the correct timezone, and the pipeline does not claim to convert these timestamps reliably to UTC.

Comparisons involving the exact local hour, calendar day, or ordering of events across datasets remain limited until timezone conventions and event-time definitions are confirmed.

## 8. Historical changes

The agent dataset contains changing attributes without a reliable effective-dated identity history. Account-status history also has inconsistent relationships and timing.

Current snapshots cannot reliably reconstruct every historical state. These limitations are documented instead of inventing historical values.

## 9. Quantified cleaning impact

The current analysis identified the following impacts:

- Payment source rows: 25,500.
- Candidate payment rows: 25,000.
- Excess duplicate payment-ID rows: 500.
- Candidate payments with borrower-ID mismatches: 24,617.
- Candidate payments with unknown account IDs: 0.
- Candidate payments missing payment references: 368.
- Candidate payment timestamps flagged as invalid or unparseable: 0.
- Account source and candidate rows: 30,000 and 30,000.
- Borrower source and candidate rows: 30,600 and 30,000.

These counts must be interpreted carefully. Zero unknown account IDs does not mean borrower attribution is correct. Zero invalid timestamps means the timestamps passed parsing checks, not that their timezone is known.

The detailed counts and treatments are recorded in `reports/part1_cleaning_impact.csv`.

## 10. Assumptions and unresolved limitations

1. `payment_id` is intended to identify one payment event; duplicate groups still require review if conflicting fields exist.
2. Preferring a populated payment reference is only a duplicate-row tie-breaker, not proof of payment validity.
3. The account master is a current reference and may not establish historical borrower ownership.
4. The currency of payment amounts has not been confirmed. Amounts must not be labelled INR or used for cost-per-rupee calculations without confirmation.
5. Reversal/refund linkage, timezone semantics, historical account ownership and agent effective dates require clarification from the data owner.
6. Results using unresolved records must be labelled provisional and accompanied by relevant quality warnings.

## 11. Reproducibility

The supporting audit script is intended to create the exception files and cleaning-impact report from the existing raw and candidate datasets.

Run the script from the project root using:

`python src/build_part1_audit_outputs.py`

The script must not modify the original raw data or silently rebuild the existing candidate datasets.

## 12. Conclusion

The cleaning process reduces duplicate records and identifies important attribution and data-quality issues. However, the candidate Golden Dataset is not fully verified because borrower attribution, reversal linkage, currency and timezone semantics remain unresolved.

The dataset is suitable for documented exploratory analysis with appropriate caveats. Analyses requiring verified borrower-level or net-recovery outcomes must wait until the relevant issues are reconciled.