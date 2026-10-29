# Counterfactual Experiment: Improved Borrower Targeting

## 1. Business question
Does an improved borrower-targeting strategy increase verified net
recovery compared with the existing targeting process?

## 2. Current observational evidence
In the available data, 3,202 of 45,000 targeting events (7.12%) were
followed by a SUCCESS-status payment within 30 days. This is an
observational association, not a causal effect. Targeting events can
overlap, payments may occur without targeting, and one payment can
match multiple targeting events.

## 3. Proposed design
- Population: eligible accounts meeting pre-defined operational,
  legal, and policy criteria.
- Unit of randomization: account, with a stable assignment throughout
  the experiment to reduce cross-group contamination.
- Treatment: the proposed improved targeting strategy.
- Control: the existing targeting strategy.
- Allocation: 50% treatment and 50% control, subject to a power analysis.
- Randomization: stratify by pre-treatment DPD band, risk segment,
  and loan type where feasible.
- Follow-up: a fixed 30-day window from assignment, defined before launch.
- Analysis: intention-to-treat; compare all accounts as randomized.

## 4. Primary outcome
Verified net recovery amount per randomized account during follow-up,
using an approved currency and transaction definition. Deduct confirmed
reversals and refunds when reliable transaction linkage is available.

## 5. Secondary outcomes
- Share of randomized accounts with at least one verified recovery.
- Gross and net recovered amount per account.
- Cost per unit of verified net recovery.
- Contact, delivery, engagement, and promise-to-pay outcomes, reported
  separately and not treated as proof of recovery.
- Complaints, opt-outs, wrong-party contacts, and other customer-harm
  indicators.

## 6. Confounders and threats to validity
- Portfolio composition and DPD/risk differences.
- Existing collection activity and borrower self-selection.
- Seasonality, payday timing, and changes in collection policy.
- Multiple targeting events and overlapping attribution windows.
- Cross-channel contact and treatment/control contamination.
- Incorrect account/borrower links and unresolved payment reversals.
- Agent/vendor identity conflicts and uncertain timezone semantics.

## 7. Identification strategy
Random assignment identifies the intention-to-treat effect if assignment
is implemented correctly, outcomes are measured comparably, and
interference between accounts is limited. Pre-specify eligibility,
assignment, outcomes, follow-up, exclusions, and analysis before launch.
Use confidence intervals and a power calculation based on historical
outcome variance and a minimum business-relevant effect.

## 8. Data and implementation requirements
- Stable account-level experiment ID and treatment assignment.
- Assignment timestamp and versioned targeting policy.
- Immutable targeting/contact event log with actual channel and outcome.
- Reliable payment transaction IDs and confirmed reversal/refund links.
- Agreed currency, timezone, and recovery metric definitions.
- Data-quality checks for duplicate events, missing assignments,
  cross-group exposure, and outcome completeness.

## 9. Limitations and launch gate
The current data does not establish a reliable causal effect of targeting.
Borrower identifiers conflict extensively across datasets, payment reversal
linkage is unresolved, and configured campaign channel is not verified
actual contact. Validate these issues and approve metric definitions
before using the experiment to support a financial investment decision.

## 10. Decision rule
Scale only if the treatment produces a positive, sufficiently precise
increase in verified net recovery, the estimated incremental benefit
exceeds incremental cost under an approved financial model, and customer
harm does not worsen beyond pre-defined limits. Otherwise, refine or stop.
