
-- CredResolve Assignment
-- File: 02_entity_integrity_checks.sql
-- Purpose: Account, borrower, and cross-table integrity checks.
-- Database: PostgreSQL
--
-- These queries are read-only. They flag questionable relationships
-- rather than silently repairing them.


-- ============================================================
-- 1. ACCOUNT MASTER: UNIQUENESS AND MISSING BORROWERS
-- ============================================================

SELECT
    COUNT(*) AS account_rows,
    COUNT(DISTINCT account_id) AS unique_account_ids,
    COUNT(*) FILTER (
        WHERE borrower_id IS NULL
           OR BTRIM(borrower_id::text) = ''
    ) AS missing_borrower_ids
FROM golden.accounts_golden_candidate;


-- ============================================================
-- 2. ACCOUNTS WITH OUTSTANDING AMOUNT ABOVE PRINCIPAL
-- This may reflect interest or fees; it is a review flag,
-- not proof of an invalid account.
-- ============================================================

SELECT
    COUNT(*) AS total_accounts,
    COUNT(*) FILTER (
        WHERE outstanding_amount > principal_amount
    ) AS outstanding_above_principal,
    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE outstanding_amount > principal_amount
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS percentage_of_accounts
FROM golden.accounts_golden_candidate;


-- ============================================================
-- 3. BORROWER MASTER: DUPLICATE IDS
-- Conflicting profiles must not be collapsed arbitrarily.
-- ============================================================

SELECT
    borrower_id,
    COUNT(*) AS profile_rows,
    COUNT(DISTINCT name) AS distinct_names,
    COUNT(DISTINCT phone) AS distinct_phones,
    COUNT(DISTINCT email) AS distinct_emails,
    COUNT(DISTINCT city) AS distinct_cities,
    COUNT(DISTINCT state) AS distinct_states
FROM golden.borrowers_golden_candidate
GROUP BY borrower_id
HAVING COUNT(*) > 1
ORDER BY profile_rows DESC, borrower_id;


-- ============================================================
-- 4. PAYMENT CANDIDATE: ACCOUNT IDS NOT IN ACCOUNT MASTER
-- ============================================================

SELECT
    p.account_id,
    COUNT(*) AS payment_records
FROM golden.payments_golden_candidate p
LEFT JOIN golden.accounts_golden_candidate a
    ON p.account_id = a.account_id
WHERE a.account_id IS NULL
GROUP BY p.account_id
ORDER BY payment_records DESC, p.account_id;


-- ============================================================
-- 5. PAYMENT BORROWER ID VS ACCOUNT MASTER BORROWER ID
-- Report counts; do not overwrite either source identifier.
-- ============================================================

SELECT
    COUNT(*) AS payment_rows,
    COUNT(*) FILTER (
        WHERE p.borrower_id IS NULL
           OR a.borrower_id IS NULL
    ) AS rows_with_missing_side_of_mapping,
    COUNT(*) FILTER (
        WHERE p.borrower_id IS NOT NULL
          AND a.borrower_id IS NOT NULL
          AND p.borrower_id <> a.borrower_id
    ) AS borrower_mismatch_rows
FROM golden.payments_golden_candidate p
JOIN golden.accounts_golden_candidate a
    ON p.account_id = a.account_id;


-- ============================================================
-- 6. STATUS HISTORY BORROWER MISMATCHES
-- Account status history can contain multiple events per account.
-- Do not deduplicate this table by account_id.
-- ============================================================

SELECT
    COUNT(*) AS history_rows,
    COUNT(*) FILTER (
        WHERE h.borrower_id IS NULL
           OR a.borrower_id IS NULL
    ) AS rows_with_missing_side_of_mapping,
    COUNT(*) FILTER (
        WHERE h.borrower_id IS NOT NULL
          AND a.borrower_id IS NOT NULL
          AND h.borrower_id <> a.borrower_id
    ) AS borrower_mismatch_rows
FROM staging.account_status_history h
JOIN golden.accounts_golden_candidate a
    ON h.account_id = a.account_id;


-- ============================================================
-- 7. REFERENTIAL INTEGRITY SUMMARY
-- Payments should reference known accounts.
-- ============================================================

SELECT
    COUNT(*) AS payment_rows,
    COUNT(*) FILTER (
        WHERE a.account_id IS NOT NULL
    ) AS rows_with_known_account,
    COUNT(*) FILTER (
        WHERE a.account_id IS NULL
    ) AS rows_with_unknown_account
FROM golden.payments_golden_candidate p
LEFT JOIN golden.accounts_golden_candidate a
    ON p.account_id = a.account_id;
