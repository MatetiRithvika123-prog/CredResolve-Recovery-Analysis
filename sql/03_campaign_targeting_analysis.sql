
-- CredResolve Assignment
-- File: 03_campaign_targeting_analysis.sql
-- Database: PostgreSQL
-- Purpose: Targeting-to-payment association and attribution overlap.
--
-- IMPORTANT:
-- These queries measure association, not causal impact.
-- A targeting event is not proof that contact occurred.
-- A SUCCESS payment is not verified net recovery.
-- Validate timestamp and business definitions before production use.


-- ============================================================
-- 1. TARGETING VOLUME BY MONTH AND STATUS
-- ============================================================

SELECT
    DATE_TRUNC('month', target_date)::date AS target_month,
    status,
    COUNT(*) AS targeting_events,
    COUNT(DISTINCT account_id) AS distinct_accounts,
    COUNT(DISTINCT campaign_id) AS distinct_campaigns
FROM staging.daily_targeting
GROUP BY 1, 2
ORDER BY 1, 2;


-- ============================================================
-- 2. CAMPAIGN CONFIGURATION SUMMARY
-- Configured channel does not necessarily mean actual channel.
-- ============================================================

SELECT
    c.channel AS configured_channel,
    COUNT(DISTINCT c.campaign_id) AS campaign_count,
    COUNT(t.target_id) AS targeting_events,
    COUNT(DISTINCT t.account_id) AS distinct_targeted_accounts
FROM staging.campaigns c
LEFT JOIN staging.daily_targeting t
    ON c.campaign_id = t.campaign_id
GROUP BY c.channel
ORDER BY targeting_events DESC;


-- ============================================================
-- 3. TARGET EVENTS FOLLOWED BY SUCCESS PAYMENTS
-- One target event counts if the same account has at least one
-- SUCCESS payment in the following 30 days.
--
-- This is an association measure. Overlapping events may match
-- the same payment, and payments may occur without targeting.
-- ============================================================

WITH target_events AS (
    SELECT
        target_id,
        account_id,
        target_date::timestamp AS target_timestamp,
        campaign_id
    FROM staging.daily_targeting
    WHERE target_date IS NOT NULL
),
target_outcomes AS (
    SELECT
        t.target_id,
        t.account_id,
        t.campaign_id,
        EXISTS (
            SELECT 1
            FROM golden.payments_golden_candidate p
            WHERE p.account_id = t.account_id
              AND p.payment_status = 'SUCCESS'
              AND p.event_at > t.target_timestamp
              AND p.event_at <= t.target_timestamp + INTERVAL '30 days'
        ) AS followed_by_success
    FROM target_events t
)
SELECT
    COUNT(*) AS targeting_events,
    COUNT(*) FILTER (
        WHERE followed_by_success
    ) AS events_followed_by_success,
    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE followed_by_success
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS event_to_success_association_pct
FROM target_outcomes;


-- ============================================================
-- 4. ASSOCIATION BY CONFIGURED CAMPAIGN CHANNEL
-- Do not interpret this as channel effectiveness or ROI.
-- ============================================================

WITH target_outcomes AS (
    SELECT
        t.target_id,
        c.channel AS configured_channel,
        EXISTS (
            SELECT 1
            FROM golden.payments_golden_candidate p
            WHERE p.account_id = t.account_id
              AND p.payment_status = 'SUCCESS'
              AND p.event_at > t.target_date::timestamp
              AND p.event_at <=
                  t.target_date::timestamp + INTERVAL '30 days'
        ) AS followed_by_success
    FROM staging.daily_targeting t
    JOIN staging.campaigns c
        ON t.campaign_id = c.campaign_id
    WHERE t.target_date IS NOT NULL
)
SELECT
    configured_channel,
    COUNT(*) AS targeting_events,
    COUNT(*) FILTER (
        WHERE followed_by_success
    ) AS events_followed_by_success,
    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE followed_by_success
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS event_to_success_association_pct
FROM target_outcomes
GROUP BY configured_channel
ORDER BY event_to_success_association_pct DESC;


-- ============================================================
-- 5. TARGETING EVENTS MATCHED TO MULTIPLE CAMPAIGNS
-- Finds successful payments that could be associated with more
-- than one campaign in a 30-day post-target window.
-- ============================================================

WITH payment_target_matches AS (
    SELECT DISTINCT
        p.payment_id,
        t.campaign_id
    FROM golden.payments_golden_candidate p
    JOIN staging.daily_targeting t
        ON p.account_id = t.account_id
       AND p.event_at > t.target_date::timestamp
       AND p.event_at <=
           t.target_date::timestamp + INTERVAL '30 days'
    WHERE p.payment_status = 'SUCCESS'
      AND p.event_at IS NOT NULL
      AND t.target_date IS NOT NULL
)
SELECT
    payment_id,
    COUNT(DISTINCT campaign_id) AS matching_campaigns
FROM payment_target_matches
GROUP BY payment_id
HAVING COUNT(DISTINCT campaign_id) > 1
ORDER BY matching_campaigns DESC, payment_id;


-- ============================================================
-- 6. CAMPAIGN REFERENCE VALIDATION
-- ============================================================

SELECT
    COUNT(*) AS targeting_rows,
    COUNT(*) FILTER (
        WHERE c.campaign_id IS NULL
    ) AS missing_campaign_references
FROM staging.daily_targeting t
LEFT JOIN staging.campaigns c
    ON t.campaign_id = c.campaign_id;
