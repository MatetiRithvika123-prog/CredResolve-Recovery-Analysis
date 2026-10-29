# CredResolve Assignment — SQL Repository

## Overview

This repository contains PostgreSQL-compatible queries for investigating payment performance, validating entity relationships, assessing targeting-to-payment associations, and monitoring data quality.

The SQL is designed to preserve the distinction between observed payment outcomes and verified net recovery. The queries are read-only and do not modify source data.

## Repository Structure

| File | Purpose |
|---|---|
| `01_payment_quality_checks.sql` | Duplicate payment IDs, missing references, payment status counts, monthly metrics, and SUCCESS/REVERSED reference overlap |
| `02_entity_integrity_checks.sql` | Account uniqueness, borrower profile conflicts, and cross-table borrower/account integrity |
| `03_campaign_targeting_analysis.sql` | Targeting trends, configured channel comparisons, post-target payment associations, and attribution overlap |
| `04_data_quality_monitoring.sql` | Row-count reconciliation, key uniqueness, field completeness, status distribution, and quality monitoring |

## Execution Order

1. Load the original CSV files into staging tables without changing their source values.
2. Create the Golden candidate tables using the documented Python transformations.
3. Verify that table and column names match those referenced in the SQL scripts.
4. Run `01_payment_quality_checks.sql`.
5. Run `02_entity_integrity_checks.sql`.
6. Run `03_campaign_targeting_analysis.sql`.
7. Run `04_data_quality_monitoring.sql`.

## Expected Schemas

The scripts expect PostgreSQL schemas named `staging` and `golden`.

Examples of expected tables include:

- `staging.payments_raw`
- `staging.daily_targeting`
- `staging.campaigns`
- `staging.account_status_history`
- `golden.payments_golden_candidate`
- `golden.accounts_golden_candidate`
- `golden.borrowers_golden_candidate`

These tables must be created and populated before the queries can execute. The SQL files alone do not load the CSV files or create the schemas.

## Interpretation and Limitations

- `SUCCESS` is a recorded payment status, not independently verified net recovery.
- Currency and timezone semantics remain unconfirmed.
- Payment references are not reliable standalone deduplication keys.
- Payment reversal linkage remains unresolved.
- Borrower IDs conflict extensively across datasets.
- Configured campaign channels are not verified actual contact channels.
- Targeting-to-payment associations do not establish causality or return on investment.
- August 2026 contains only partial-month data and should not be compared directly with complete months.

## Production Recommendations

Before production use, add automated tests, approved business definitions, schema validation, scheduled execution, threshold-based alerts, query-performance review, and documented data lineage. Critical identity and transaction-linkage failures should be visible to dashboard consumers rather than silently corrected.
