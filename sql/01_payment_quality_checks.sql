
-- CredResolve Assignment
-- File: 01_payment_quality_checks.sql
-- Purpose: Payment data-quality checks and monthly performance metrics.
-- Database: PostgreSQL
--
-- Expected tables:
--   staging.payments_raw
--   golden.payments_golden_candidate
--
-- Load the CSV files into these tables before running the queries.
-- Preserve the original raw data; these queries do not modify data.


-- ============================================================
-- 1. RAW PAYMENT VOLUME AND UNIQUE PAYMENT IDS
-- ============================================================

SELECT
    COUNT(*) AS raw_rows,
    COUNT(DISTINCT payment_id) AS unique_payment_ids,
    COUNT(*) - COUNT(DISTINCT payment_id) AS excess_rows_by_payment_id
FROM staging.payments_raw;


-- ============================================================
-- 2. DUPLICATE PAYMENT ID GROUPS
-- Review conflicting records before deduplication.
-- ============================================================

SELECT
    payment_id,
    COUNT(*) AS records_in_group,
    COUNT(DISTINCT account_id) AS distinct_accounts,
    COUNT(DISTINCT borrower_id) AS distinct_borrowers,
    COUNT(DISTINCT payment_status) AS distinct_statuses,
    COUNT(DISTINCT amount) AS distinct_amounts
FROM staging.payments_raw
GROUP BY payment_id
HAVING COUNT(*) > 1
ORDER BY records_in_group DESC, payment_id;


-- ============================================================
-- 3. MISSING PAYMENT REFERENCES
-- ============================================================

SELECT
    COUNT(*) AS total_records,
    COUNT(*) FILTER (
        WHERE payment_reference IS NULL
           OR BTRIM(payment_reference::text) = ''
    ) AS missing_reference_records,
    ROUND(
        (
            100.0 * COUNT(*) FILTER (
                WHERE payment_reference IS NULL
                   OR BTRIM(payment_reference::text) = ''
            ) / NULLIF(COUNT(*), 0)
        )::numeric,
        2
    ) AS missing_reference_pct
FROM golden.payments_golden_candidate;


-- ============================================================
-- 4. BORROWER ID MISMATCHES
-- Uses the quality flag created by the Python pipeline.
-- ============================================================

SELECT
    COUNT(*) AS candidate_rows,
    COUNT(*) FILTER (
        WHERE borrower_id_mismatch IS TRUE
    ) AS borrower_mismatch_rows,
    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE borrower_id_mismatch IS TRUE
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS borrower_mismatch_pct
FROM golden.payments_golden_candidate;


-- ============================================================
-- 5. PAYMENT STATUS COUNTS
-- ============================================================

SELECT
    payment_status,
    COUNT(*) AS payment_records,
    COUNT(DISTINCT payment_id) AS unique_payment_ids
FROM golden.payments_golden_candidate
GROUP BY payment_status
ORDER BY payment_records DESC;


-- ============================================================
-- 6. MONTHLY PAYMENT PERFORMANCE
-- SUCCESS status is not necessarily verified net recovery.
-- Amount currency is currently unconfirmed.
-- ============================================================

WITH monthly AS (
    SELECT
        DATE_TRUNC('month', event_at)::date AS month,
        COUNT(*) AS payment_records,

        COUNT(*) FILTER (
            WHERE payment_status = 'SUCCESS'
        ) AS successful_payment_count,

        SUM(amount) FILTER (
            WHERE payment_status = 'SUCCESS'
        ) AS gross_successful_amount

    FROM golden.payments_golden_candidate
    WHERE event_at IS NOT NULL
    GROUP BY DATE_TRUNC('month', event_at)::date
),
with_previous AS (
    SELECT
        *,
        LAG(gross_successful_amount) OVER (
            ORDER BY month
        ) AS previous_gross_amount,

        LAG(successful_payment_count) OVER (
            ORDER BY month
        ) AS previous_successful_count

    FROM monthly
)
SELECT
    month,
    payment_records,
    successful_payment_count,
    ROUND(
        100.0 * successful_payment_count
        / NULLIF(payment_records, 0),
        2
    ) AS payment_success_share_pct,

    ROUND(gross_successful_amount::numeric, 2)
        AS gross_successful_amount,

    ROUND(
        (
            100.0 * (
                gross_successful_amount - previous_gross_amount
            ) / NULLIF(previous_gross_amount, 0)
        )::numeric,
        2
    ) AS gross_amount_mom_change_pct,

    ROUND(
        (
            100.0 * (
                successful_payment_count - previous_successful_count
            ) / NULLIF(previous_successful_count, 0)
        )::numeric,
        2
    ) AS successful_count_mom_change_pct

FROM with_previous
ORDER BY month;


-- ============================================================
-- 7. SUCCESS AND REVERSAL STATUS OVERLAP
-- Shared references are not proof that transactions are linked.
-- ============================================================

SELECT
    payment_reference,
    COUNT(*) AS records,
    COUNT(*) FILTER (
        WHERE payment_status = 'SUCCESS'
    ) AS success_records,
    COUNT(*) FILTER (
        WHERE payment_status = 'REVERSED'
    ) AS reversed_records,
    COUNT(DISTINCT account_id) AS distinct_accounts
FROM golden.payments_golden_candidate
WHERE payment_reference IS NOT NULL
  AND BTRIM(payment_reference::text) <> ''
GROUP BY payment_reference
HAVING
    COUNT(*) FILTER (
        WHERE payment_status = 'SUCCESS'
    ) > 0
    AND
    COUNT(*) FILTER (
        WHERE payment_status = 'REVERSED'
    ) > 0
ORDER BY records DESC, payment_reference;
