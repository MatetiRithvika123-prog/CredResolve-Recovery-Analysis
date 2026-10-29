# Recovery Analytics Metric Definitions and Data Limitations

## 1. Purpose

These are independently proposed operational definitions for the CredResolve assignment. They are not confirmed company definitions because the supplied data dictionary contains column names and data types but no authoritative business definitions. Confirm definitions with Operations and Finance before using them for compensation, vendor comparisons, or investment decisions.

The central distinction is between **contact activity, promise-to-pay activity, gross successful-payment events, and reconciled net cash recovery**. These measures are not interchangeable.

## 2. Independent Metric Definitions

| Metric | Proposed independent definition | Numerator / Denominator | Current-data status and limitations |
|---|---|---|---|
| **Contact rate** | Unique eligible accounts with at least one verified successful contact during the measurement period divided by all eligible accounts assigned for contact during that period. Report attempt-level contact rate separately. | Numerator: unique eligible accounts with verified contact. Denominator: all eligible accounts assigned for contact. | **Not reliably calculable yet.** Call records and dispositions exist, but disposition semantics and borrower identity links require validation. A call attempt, ringing status, or answered status alone does not prove successful borrower contact. |
| **Right-party contact (RPC) rate** | Unique eligible accounts with at least one verified contact with the borrower or an authorized party divided by all eligible accounts assigned for contact. Also report RPC per successful contact attempt as a separate operational measure. | Numerator: unique accounts with verified RPC. Denominator: eligible accounts assigned for contact. Secondary measure: verified RPC attempts divided by eligible contact attempts. | **Not reliably calculable.** No confirmed RPC flag or definition exists in the supplied data dictionary. Do not infer RPC from generic dispositions or call-answer status. |
| **Promise-to-pay (PTP) rate** | Unique accounts with at least one valid, recorded promise to pay during the measurement window divided by unique accounts with verified RPC in that window. Also report PTP accounts divided by all eligible assigned accounts as a funnel measure. | Primary numerator: unique accounts with valid PTP. Primary denominator: unique accounts with verified RPC. Secondary denominator: all eligible assigned accounts. | **Not reliably calculable.** `promises_to_pay` exists, but RPC denominator and PTP validity rules are unconfirmed. Count distinct valid promises or accounts according to the chosen definition, not raw event rows. |
| **PTP kept rate** | Valid promises whose due dates have passed and that were fulfilled by the agreed due date or pre-defined grace period divided by all valid promises due in the measurement window whose observation window is complete. Report account-level results separately where appropriate. | Numerator: matured valid promises fulfilled according to the agreed rule. Denominator: all matured valid promises with a complete outcome window. | **Not safely calculable from `status=KEPT` alone.** Validate against reconciled net payments and due dates. Define partial-payment treatment, grace periods, cancellations, split payments, and multiple promises per account. Exclude promises that have not matured. |
| **Recovery rate** | Reconciled net cash recovered during the period divided by the agreed collectible amount due for the same eligible portfolio and period. If the business uses opening overdue balance or another denominator, report that definition separately and explain the difference. | Numerator: reconciled net collections. Denominator: explicitly defined eligible collectible amount due. | **Not reliably calculable.** Currency/unit is undocumented, reversals cannot be linked reliably, and the correct portfolio denominator and as-of date are not established. Do not label gross `SUCCESS` amounts as net recovery. |
| **Recovery per account** | Reconciled net cash recovered and attributable to the defined cohort divided by all eligible accounts in that cohort. Report recovery per contacted account or RPC account separately as diagnostic measures. | Numerator: reconciled net collections attributable to the cohort. Denominator: all eligible accounts in the same cohort. | **Partially calculable only after payment reconciliation and cohort definition.** Using only accounts with payment records or successful payments creates selection bias and does not measure recovery across the whole eligible portfolio. |
| **Recovery per agent-hour** | Reconciled net recovery attributable under an approved attribution rule divided by productive agent-hours for the same cohort and period. Report paid or scheduled hours separately if relevant. | Numerator: reconciled net collections attributable to the work cohort. Denominator: consistently defined productive agent-hours. | **Not yet reliable.** Agent master records conflict heavily by `agent_id`; sessions overlap for some agents, and productive-hour rules and attribution are not defined. Resolve agent history and session overlaps first. Define treatment of breaks, training, idle time, and after-call work. |
| **Cost per ₹ recovered** | Fully loaded collection operating cost divided by reconciled net recovery in confirmed INR. For intervention evaluation, also calculate incremental intervention cost divided by incremental reconciled net recovery relative to a control group. | Numerator: fully loaded collection cost or incremental intervention cost, depending on the measure. Denominator: reconciled net recovery in INR or incremental net recovery versus control. | **Not calculable from supplied files.** INR currency and cost tables/fields are not confirmed. Obtain vendor, labor, messaging, field, technology, and implementation costs. If incremental recovery is zero or negative, the ratio is undefined or not decision-useful; report net benefit and uncertainty. |
| **Channel conversion** | For each channel, unique eligible accounts actually exposed to that channel that achieve a pre-defined downstream outcome within a fixed attribution window divided by all eligible accounts actually exposed to that channel. Report separate stages for verified contact, RPC, valid PTP, kept PTP, and reconciled net recovery. | Numerator: unique exposed accounts achieving the specified outcome. Denominator: unique eligible accounts actually exposed to the channel. | **Association only at present.** A campaign's configured channel is not proof of actual exposure. Message/call events can be duplicated or linked to multiple accounts, and overlapping campaign attribution exists. Use randomized holdouts or pre-registered attribution rules to estimate causal impact. |

## 3. Required Measurement Rules

1. Use immutable source IDs and preserve raw files. Never overwrite raw records.
2. Separate event counts, unique entities, gross successful-payment amounts, and reconciled net recovery.
3. Treat `SUCCESS`, `PAID`, `KEPT`, `DELIVERED`, `CLICKED`, and `CONTACTED` as source-system statuses—not independently verified outcomes—until their semantics are confirmed.
4. Resolve payment reversals and duplicates before reporting net recovery. Payment references are not safe unique keys in this dataset.
5. Use effective-dated borrower/account/agent relationships. Current master snapshots must not be assumed to represent historical relationships.
6. Define timezone, currency, reporting calendar, eligible portfolio, DPD bands, and attribution windows before production reporting.
7. Report the numerator, denominator, exclusions, measurement period, and confidence interval for every rate.
8. Use the same eligibility rules, time windows, and metric definitions when comparing periods.
9. For borrower-level outcomes, use a validated account-level or borrower-level unit of analysis. Do not treat multiple events from the same account as independent borrowers.
10. Distinguish descriptive associations from causal effects. A before/after change alone does not prove that a channel, campaign, vendor, or agent caused the change.

## 4. Assignment Claim: “Recovery Improved by 11% Month-on-Month”

### 4.1 What the observed payment data shows

The available payment data supports a narrower statement: the gross amount on rows marked `SUCCESS` increased by approximately **11.03% from February to March 2026**. Successful-payment count increased by **11.29%**, while payment-level success share decreased from **71.52% to 70.56%**.

| Measure | February 2026 | March 2026 | Observed change |
|---|---:|---:|---:|
| Successful-payment count | 2,268 | 2,524 | +11.29% |
| Gross amount on successful-payment rows | 170,142,453.76 | 188,912,374.02 | +11.03% |
| Payment-level success share | 71.52% | 70.56% | −0.96 percentage points |

The payment-level difference in success share is not statistically significant under the simple independent-proportion test (**p = 0.3850**). The account-level activity-cohort check is also not statistically significant (**p = 0.890**). These tests address success-share measures, not net recovery.

The gross successful-payment amount also did not increase consistently month after month: it fell approximately 7.29% from March to April, rose 5.20% from April to May, fell 4.72% from May to June, and rose 6.65% from June to July. August is partial through August 8 and should not be compared directly with full months without an explicit adjustment.

### 4.2 Why the 11% net-recovery claim is not verified

The following limitations prevent the gross amount increase from proving an equivalent increase in net recovery:

- Payment currency and amount units are undocumented; amounts must not automatically be labelled INR.
- The source contains 25,500 payment rows and 25,000 candidate unique payment IDs, with 500 duplicate-ID groups.
- There are 1,254 `REVERSED` records, but reliable links to the corresponding successful payments are not established.
- There are 3,746 repeated payment references, and 3,408 repeated-reference groups contain conflicting details. Payment references alone are not safe deduplication keys.
- 24,617 candidate payment rows have borrower IDs that mismatch the current account master.
- Payment events run from January 1 through August 8, 2026. The available event data does not provide a complete 12-month period.

**Conclusion:** the observed February-to-March increase in gross successful-payment amount is +11.03%. However, this does **not** establish that net recovery improved by 11% or that the improvement was sustained. The correct finding is **“not verified from available evidence,”** not “definitely false” and not “proven true.” A defensible alternative net-recovery percentage cannot be calculated until payment identities, reversals, currency, denominator, and comparison-period definitions are reconciled.

## 5. Requirements for a Fair Comparison

Before calculating or reporting a percentage change:

1. **Fix the metric.** Do not interchange gross successful-payment amount, successful-payment count, payment success share, and net recovery.
2. **Fix the cohort.** Apply the same eligible-account definition and comparable portfolio coverage in both periods.
3. **Fix the time basis.** Compare equal-duration periods or use a justified adjustment for partial periods. Do not compare partial August directly with a full month.
4. **Reconcile cash.** Deduplicate using validated payment IDs and business rules; link reversals/refunds to original payments; validate currency and amount units.
5. **Validate attribution.** Repair payment-to-account and account-to-borrower relationships before calculating borrower-level outcomes or segmentation.
6. **Control mix and seasonality.** Show unadjusted results and a justified standardized or experimental estimate. Current one-variable standardization on loan type, risk segment, and DPD changed monthly payment success share by no more than about 0.08 percentage points. This is not a full multivariable decomposition and does not establish net-recovery uplift.
7. **Quantify uncertainty.** Provide confidence intervals and an appropriate test for the actual outcome and unit of analysis. Do not treat correlated payment events as independent borrower observations.
8. **Separate association from causation.** A before/after increase alone does not prove an intervention caused the change. Use a randomized control or a clearly defended quasi-experimental design to estimate incremental recovery.

## 6. Investment Decision Limitation

The supplied data does not include reliable intervention costs, cost per contact, cost per field visit, channel-level incremental recovery, or a causal control group. Therefore, a defensible point estimate for incremental recovery, ROI, and break-even cannot be calculated from the supplied files alone.

Recommend a controlled pilot and show ROI as a scenario formula until Finance supplies validated inputs:

- **Incremental net recovery** = treatment-group net recovery − estimated control counterfactual net recovery, scaled only to the intended eligible population and supported by the experimental design.
- **Net benefit** = incremental net recovery − incremental fully loaded intervention cost.
- **ROI** = net benefit ÷ incremental fully loaded intervention cost.
- **Break-even** = the point where incremental net recovery equals incremental fully loaded intervention cost.
- **Downside case** = a conservative uplift estimate (including the lower confidence bound where appropriate), higher implementation costs, slower adoption, and any deterioration in reversals, complaints, opt-outs, or other guardrails.

Report the assumed scale-up population and time horizon alongside any ROI estimate. Do not extrapolate a short pilot to the full portfolio without stating and defending the assumptions.

Do not present an invented ROI or guaranteed uplift as a measured result. Confirm currency, cost allocation, eligibility rules, payment reconciliation, and the experimental counterfactual before making a major investment decision.
