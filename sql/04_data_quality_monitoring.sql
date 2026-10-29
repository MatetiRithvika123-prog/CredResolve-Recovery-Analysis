
-- CredResolve Assignment
-- File: 04_data_quality_monitoring.sql
-- Database: PostgreSQL
-- Purpose: Reconciliation, freshness, uniqueness and anomaly checks.
--
-- These queries are read-only monitoring checks.
-- Thresholds should be approved before production deployment.


-- ============================================================
-- 1. SOURCE-TO-GOLDEN ROW COUNT RECONCILIATION
-- ============================================================

SELECT
    'payments_raw' AS dataset,
    COUNT(*) AS row_count,
    COUNT(DISTINCT payment_id) AS distinct_primary_keys
FROM staging.payments_raw

UNION ALL

SELECT
    'payments_golden_candidate' AS dataset,
    COUNT(*) AS row_count,
    COUNT(DISTINCT payment_id) AS distinct_primary_keys
FROM golden.payments_golden_candidate

UNION ALL

SELECT
    'accounts_golden_candidate' AS dataset,
    COUNT(*) AS row_count,
    COUNT(DISTINCT account_id) AS distinct_primary_keys
FROM golden.accounts_golden_candidate;


-- ============================================================
-- 2. GOLDEN PAYMENT UNIQUENESS CHECK
-- Expected: no duplicate payment IDs in the candidate.
-- ============================================================

SELECT
    payment_id,
    COUNT(*) AS row_count
FROM golden.payments_golden_candidate
GROUP BY payment_id
HAVING COUNT(*) > 1
ORDER BY row_count DESC, payment_id;


-- ============================================================
-- 3. REQUIRED PAYMENT FIELD COMPLETENESS
-- Do not treat a missing reference as proof of an invalid payment.
-- ============================================================

SELECT
    COUNT(*) AS total_rows,

    COUNT(*) FILTER (
        WHERE payment_id IS NULL
    ) AS missing_payment_ids,

    COUNT(*) FILTER (
        WHERE account_id IS NULL
    ) AS missing_account_ids,

    COUNT(*) FILTER (
        WHERE event_at IS NULL
    ) AS missing_event_timestamps,

    COUNT(*) FILTER (
        WHERE payment_status IS NULL
    ) AS missing_payment_statuses,

    COUNT(*) FILTER (
        WHERE amount IS NULL
    ) AS missing_amounts,

    COUNT(*) FILTER (
        WHERE payment_reference IS NULL
           OR BTRIM(payment_reference::text) = ''
    ) AS missing_payment_references

FROM golden.payments_golden_candidate;


-- ============================================================
-- 4. MONTHLY PAYMENT STATUS DISTRIBUTION
-- ============================================================

WITH monthly_status AS (
    SELECT
        DATE_TRUNC('month', event_at)::date AS month,
        payment_status,
        COUNT(*) AS record_count
    FROM golden.payments_golden_candidate
    WHERE event_at IS NOT NULL
    GROUP BY DATE_TRUNC('month', event_at)::date, payment_status
)
SELECT
    month,
    payment_status,
    record_count,
    ROUND(
        (
            100.0 * record_count
            / NULLIF(SUM(record_count) OVER (PARTITION BY month), 0)
        )::numeric,
        2
    ) AS monthly_status_share_pct
FROM monthly_status
ORDER BY month, payment_status;

-- ============================================================
-- 5. INVALID OR NON-POSITIVE PAYMENT AMOUNTS
-- Review against approved business rules; do not assume currency.
-- ============================================================

SELECT
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (
        WHERE amount IS NULL
    ) AS missing_amounts,
    COUNT(*) FILTER (
        WHERE amount <= 0
    ) AS non_positive_amounts
FROM golden.payments_golden_candidate;


-- ============================================================
-- 6. ACCOUNT MASTER KEY AND TIMESTAMP CHECKS
-- ============================================================

SELECT
    COUNT(*) AS total_accounts,
    COUNT(DISTINCT account_id) AS distinct_account_ids,
    COUNT(*) FILTER (
        WHERE opened_at IS NULL
    ) AS missing_or_invalid_opened_at,
    COUNT(*) FILTER (
        WHERE borrower_id_missing IS TRUE
    ) AS missing_borrower_id_flagged,
    COUNT(*) FILTER (
        WHERE outstanding_exceeds_principal IS TRUE
    ) AS outstanding_above_principal_flagged
FROM golden.accounts_golden_candidate;


-- ============================================================
-- 7. BORROWER PROFILE CONFLICT MONITOR
-- Candidate rows may contain multiple profiles per borrower.
-- ============================================================

SELECT
    COUNT(*) AS candidate_rows,
    COUNT(DISTINCT borrower_id) AS distinct_borrower_ids,
    COUNT(*) FILTER (
        WHERE borrower_profile_conflict IS TRUE
    ) AS rows_flagged_for_profile_conflict,
    COUNT(*) FILTER (
        WHERE phone_missing IS TRUE
    ) AS rows_flagged_for_missing_phone,
    COUNT(*) FILTER (
        WHERE email_missing IS TRUE
    ) AS rows_flagged_for_missing_email
FROM golden.borrowers_golden_candidate;


-- ============================================================
-- 8. RECOMMENDED PRODUCTION ALERTS (DOCUMENTATION)
-- Implement approved thresholds in the scheduler/orchestrator.
--
-- Critical:
--   - Duplicate Golden primary keys
--   - Unexpected missing account/payment IDs
--   - Unapproved schema or status changes
--   - Sudden unexplained row-count drops
--
-- Warning:
--   - Higher missing-reference rate
--   - Large shifts in payment status mix
--   - Increased identity mismatches
--   - Late-arriving data beyond the agreed SLA
--
-- Alert thresholds and SLAs must be agreed with stakeholders.
-- ============================================================
