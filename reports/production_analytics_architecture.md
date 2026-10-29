# Production Analytics Architecture

## Layer responsibilities

1. **Raw:** retain source files unchanged, record ingestion metadata, and preserve source versions.
2. **Staging:** validate schemas, parse types and timestamps, retain source identifiers, and detect schema drift.
3. **Clean:** apply documented deduplication rules, normalize only where semantics are confirmed, and flag unresolved conflicts.
4. **Golden:** publish entity and event datasets with stable keys, explicit source-of-truth decisions, and lineage.
5. **Feature:** derive time-aware DPD bands, account cohorts, targeting exposures, contact history, and payment features.
6. **Metrics:** maintain version-controlled definitions, denominators, exclusions, attribution windows, and currency rules.
7. **Dashboard:** show validated trends, segment comparisons, data-quality warnings, and decision-useful confidence ranges.

## Required controls

- Preserve raw inputs and make transformations reproducible and idempotent.
- Use database constraints and stable event/entity keys; never deduplicate solely on a repeated payment reference.
- Quarantine conflicting records for review instead of silently choosing an arbitrary winner.
- Treat event time separately from ingestion/recorded time; confirm timezone semantics before cross-source time comparisons.
- Reconcile source row counts, accepted rows, rejected rows, and duplicate groups at each pipeline stage.
- Version business metrics and record the source fields, joins, filters, and exclusions behind every reported result.
- Process late-arriving data with controlled incremental loads and repeatable backfills.
- Monitor freshness, schema drift, null rates, uniqueness, referential integrity, unexpected status distributions, and metric anomalies.
- Restrict sensitive borrower data, apply role-based access, and log access and changes.
- Block publication of high-risk metrics when critical identity or payment-linkage checks fail.

## Current assignment-specific launch gates

- Borrower IDs conflict extensively across several datasets.
- Agent IDs do not reliably identify a single agent profile.
- Payment reversals cannot yet be linked confidently to original transactions.
- Currency and timezone semantics are not fully established.
- Call attempts cannot safely be joined to calls on call_id alone.
- Configured campaign channels must not be treated as verified actual contact channels.

These issues should be displayed as limitations and validation gates, not hidden by the dashboard.
