# CredResolve Assignment — Investigation Notes

## 1. Payment Data Quality

**Dataset:** `payments.csv`

### Finding 1: Repeated Payment IDs
- Raw records: 25,500
- Unique payment IDs: 25,000
- Repeated payment ID groups: 500
- Conflicting business fields across repeated IDs: 0

**Proposed treatment:** Retain one record per `payment_id`, preferring a populated `payment_reference` when available.

### Finding 2: Missing Payment References
- 14 repeated payment ID groups contain one record with a missing reference and another with a populated reference.
- The checked business fields are consistent within these groups.


### Validation Status

The initial payment deduplication audit identified 25,500 raw rows and 25,000 unique payment IDs. The candidate dataset retains one record per payment ID, with 500 excess rows identified for review.

Subsequent checks identified unresolved borrower-ID mismatches, missing payment references, and incomplete reversal attribution. The candidate has 25,000 rows, including 24,617 payment/account borrower-ID mismatches and 368 missing payment references.

**Treatment:** Preserve raw data, retain documented candidate-selection logic, and flag unresolved attribution. Do not treat a SUCCESS status as proof of net recovery.

**Status:** Deduplication and initial quality checks completed; final net-recovery validation remains unresolved.


### Important Limitation
A payment record marked `SUCCESS` does not, by itself, establish the final net recovered amount. Reversals and other payment events must be investigated before calculating recovery.

### Evidence Files
- `data_inventory.csv`
- `data_quality_initial.csv`
- `payment_id_reconciliation.csv`
- `payment_dedup_audit.csv`

*Update these notes as the investigation progresses. Final conclusions will be documented after validation.*

## 2. Payment Reversal Linkage — Validated Candidate-Data Findings

- Reversed payment records: 1,254.
- Reversed records with non-missing payment references: 1,232.
- Successful payment records: 17,534.
- Shared payment references between SUCCESS and REVERSED records: 315.
- Shared-reference matches with the same account: 0.
- Shared-reference matches with both the same account and amount: 0.

**Treatment:** Do not associate reversed records with successful payments using `payment_reference` alone.

**Limitation:** The linkage between successful and reversed payments remains unresolved. Net recovery cannot be reliably calculated until reversal attribution, payment identity, currency, and event-time semantics are validated.

**Status:** Candidate-data checks completed; final net-recovery validation remains unresolved.


## Calls Dataset: Duplicate ID Investigation

- Raw call records: 91,350.
- Unique call IDs in raw data: 90,000.
- Exact duplicate excess rows removed from the candidate: 1,271.
- Missing agent IDs reconciled after matching all other fields: 68.
- Candidate rows after reconciliation: 90,011.
- Unique call IDs after reconciliation: 90,000.
- Unresolved duplicate-ID groups: 11, containing event timestamps separated by 1–5 days.

**Treatment:** Retain the 11 unresolved groups because the available source does not establish whether the records represent separate events or reused identifiers. Preserve the raw source unchanged.

**Timestamp limitation:** UTC conversion assumes the row-level timezone field represents the local timezone of the event. Confirm this assumption against source documentation before treating normalized timestamps as authoritative.

**Impact:** Call-level metrics should use the reconciled candidate with explicit handling of unresolved IDs. Call attempts must not be joined to calls on `call_id` alone where that join creates row expansion or conflicting entity attribution.

**Status:** Duplicate handling completed provisionally; the 11 unresolved groups and timezone semantics require documented limitations.



## Payments Dataset: Account-Borrower Relationship Audit

- Candidate payment records examined: 25,000.
- Payment account IDs absent from `accounts.csv`: 0.
- Payment records with a conflicting non-null borrower ID relative to the account master: 24,617 (98.47%).
- Conflicting payment borrower IDs that appear on at least one account record: 22,502.
- Conflicts by payment status: SUCCESS 17,279; FAILED 3,617; PENDING 2,486; REVERSED 1,235.
- Only one successful payment in the candidate has a borrower ID matching the borrower recorded for its account.

**Interpretation:** Matching account IDs do not establish correct borrower attribution. The available evidence does not explain the conflicting borrower relationships.

**Treatment:** Preserve payment and account borrower IDs separately. Flag mismatches and do not silently overwrite identifiers or infer a corrected relationship.

**Impact:** Borrower-level recovery analysis is unreliable until attribution is reconciled. Account-level payment analysis also requires careful treatment of reversals, currency, timestamps, and denominators.

**Status:** Quantified candidate-data finding; root cause remains unresolved.


## Recovery trend: provisional conclusion

- The deduplicated payment candidate contains 17,534 SUCCESS records.
- Only 1 successful payment has a borrower ID matching the borrower recorded for its account; 17,533 do not match.
- Gross successful-payment amount increased by 11.03% in March 2026 versus February 2026, but declined in February and April and fluctuated in subsequent complete months.
- August data ends on August 8 and must not be compared directly with a complete calendar month.
- The data does not establish the amount currency, payment-event timezone, complete reversal linkage, or an appropriate recovery-rate denominator.
- Conclusion: the supplied data supports a provisional March gross-payment increase of 11.03%, but does not substantiate a general claim that recovery improved by 11% month-on-month.
- Confidence: low for a net-recovery or recovery-rate conclusion until the payment/borrower relationship, reversal treatment, event-time conventions, and denominator are validated.

### Account status history — initial audit

- Source: `account_status_history.csv`
- Raw records: 60,000
- `history_id` is unique; no missing values were found in the eight source columns.
- All 60,000 history rows match an existing `account_id` in `accounts.csv`.
- 59,035 history rows (98.39%) have a non-null `borrower_id` that differs from the corresponding non-null borrower ID in the account master.
- The account master borrower ID is missing for 962 history rows, preventing a direct borrower-ID consistency check for those rows.
- `event_at` and `recorded_at` parse successfully, but 30,191 records have `recorded_at` before `event_at` and 29,809 have it after. Differences are bounded to approximately ±24 hours. Their semantics remain unconfirmed.
- All seven observed statuses and all five sources are retained. The history table is not deduplicated by `account_id`, because multiple events per account are expected.
- Treatment: preserve raw timestamps and identifiers; flag relationship inconsistencies; do not infer borrower identity or ingestion delay without source documentation.
- Severity: preliminary analyst assessment; confirm against business definitions and source-system documentation.

### Agent sessions — initial audit

- Source: `agent_sessions.csv`
- Total records: 15,000; unique session IDs: 15,000; no missing values.
- The dataset contains 1,000 distinct agent IDs, 1,500 device IDs, and two timezone labels: UTC and Asia/Kolkata.
- Login and logout timestamps parse successfully. No session has logout before login or zero duration.
- Session duration ranges from 30 to approximately 600 minutes; mean duration is 315.48 minutes.
- 215 sessions start before the preceding session for the same agent ends. These overlaps are flagged for investigation, not automatically removed.
- Logged-in duration is not assumed to equal productive work time. Agent productivity and recovery per agent-hour require validated activity and payment attribution.
- Timestamp timezone semantics and overlapping-session causes remain unconfirmed.
- Severity and interpretation are preliminary analyst assessments.

### Agent master — identity integrity audit

- Source: `agents.csv`
- Raw records: 30,000; distinct `agent_id` values: 1,000.
- Exact duplicate rows: 0.
- All 1,000 agent IDs have variation in every other examined field: employee_code, agent_name, vendor_id, team, status, joined_at, and updated_at.
- Employee codes are also non-unique: 1,099 distinct employee codes across 30,000 rows.
- 4,078 rows have `updated_at` earlier than `joined_at`. Both timestamp columns parse successfully, but their chronology requires investigation.
- All session agent IDs match an ID present in the agent master; however, this does not establish reliable person-level identity because each agent ID has conflicting master records.
- Treatment: preserve raw records; do not deduplicate, select a latest record, or infer historical vendor/team/status assignments without a documented versioning or effective-date rule.
- Impact: agent-level and vendor-level recovery attribution is unreliable until identity and historical assignment mappings are resolved.
- Severity: critical, preliminary analyst assessment.
