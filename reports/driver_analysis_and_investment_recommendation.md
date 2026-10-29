# Recovery Driver Analysis and ₹10 Cr Investment Recommendation

## 1. Executive conclusion

The available data does **not establish a sustained 11% improvement in net recovery**, and it does not support a causal ranking of the six investment options. This is not proof that improvement did not occur; it means the supplied data and current data-quality limitations are insufficient to verify the claim.

**Recommendation:** do not commit the full ₹10 Cr to one intervention based on the current analysis. First complete a measurement-readiness gate, then run a time-boxed randomized pilot comparing better borrower targeting with business as usual. If feasible, test digital/WhatsApp and voice as separately randomized arms rather than bundling interventions. This is a decision under uncertainty—not a claim that targeting has already been proven superior.

Release scale-up funding only after the pilot demonstrates incremental, reconciled net recovery, acceptable fully loaded unit economics, and no material deterioration in customer-protection guardrails.

## 2. Driver analysis and evidence classification

The classifications below describe what the supplied data supports. **Fact** means directly observed in the supplied files; **Strong evidence** means the analysis meaningfully supports a bounded conclusion; **Correlation** means an observed association that is not established as causal; and **Hypothesis** means a plausible explanation that requires additional data or testing. “Not measurable” means the available data cannot support a defensible assessment.

| Required driver | Observed evidence | Classification and conclusion | What is needed next |
|---|---|---|---|
| Portfolio mix | One-variable-at-a-time standardization on loan type, risk segment, and DPD band changed monthly payment success share by no more than about 0.08 percentage points. | **Strong evidence, narrowly scoped:** these individual mix shifts do not appear to explain the observed monthly movement in payment success share under the chosen method. This is not a full multivariable decomposition and does not explain net recovery. | Re-run using validated event-to-account links, as-of attributes, interactions, and a clearly defined net-recovery outcome. |
| DPD | The account file contains DPD, but it is a current snapshot; historical account/state joins have severe borrower-ID mismatches. | **Not established:** the supplied data does not reliably show whether DPD changes explain monthly performance. | Reconstruct effective-dated DPD at the event date and validate account identity. |
| Client | No explicit client identifier was identified in the supplied files/data dictionary. | **Fact about data availability:** client-level performance is not measurable from the current files. | Obtain a verified client/servicer identifier and its history, if applicable. |
| Geography | Borrower records contain city/state, but borrower-account relationships in event data are unreliable. | **Hypothesis only:** geographic differences cannot be ranked defensibly from current joins. | Repair identity links and validate geography as of the relevant event date before comparing areas. |
| Language | No explicit preferred-language field was identified. | **Fact about data availability:** language effects are not measurable. Do not infer language from a person's name or location. | Collect or obtain a governed, verified preferred-language field. |
| Agent | `agents.csv` contains 30,000 rows but only 1,000 distinct `agent_id` values. Attributes conflict for repeated IDs, and there is no clear effective-date/version rule. | **Fact:** the agent master is internally inconsistent. **Conclusion:** agent-level performance comparisons are not defensible yet. | Reconstruct effective-dated agent records and reconcile employee, team, vendor, and status history. |
| Agent tenure | `joined_at` conflicts across records for the same agent IDs. | **Not measurable reliably:** tenure-based comparisons would depend on an unresolved agent history. | Establish a validated hire/join date and effective-dated agent identity. |
| Campaign | Campaign and daily targeting records exist, but targeting statuses do not establish a verified recovery outcome. | **Correlation at most:** campaign exposure/status can be described, but current data does not establish campaign-caused recovery. | Define exposure and attribution windows in advance, deduplicate overlapping exposures, and use a suitable control group. |
| Channel | Configured campaign channels and SMS, WhatsApp, call, and field event tables exist. Configured channel is not proof of actual borrower exposure; message IDs sometimes link to multiple accounts. | **Correlation at most:** channel performance cannot be interpreted causally with the current identity and exposure issues. | Reconcile account-level exposure, distinguish sent/delivered/engaged events, and run a controlled comparison. |
| Telephony vendor | Vendor IDs exist, but agent/vendor assignments conflict and vendor names recur across different IDs. | **Fact:** vendor attribution is not clean enough for a reliable vendor ranking. | Use stable vendor IDs, validate actual call routing/exposure, and compare randomized or appropriately matched cohorts. |
| Calling time | Call timestamps exist, but timezone semantics are unconfirmed and timestamp inconsistencies remain. | **Hypothesis:** time-of-day effects are not established. | Confirm timestamp semantics and borrower-local timezone; then compare outcomes per eligible attempt while controlling for relevant segment and DPD. |
| Attempt frequency | `call_attempts` contains 120,000 unique attempt IDs. Joins to calls on `call_id` expand rows and some key attributes disagree. | **Fact:** the join is unsafe without reconciliation. **Conclusion:** diminishing returns and contact-fatigue effects are not established. | Reconcile call/attempt cardinality and identities, then analyze outcomes by prior attempt count with contact-frequency safeguards. |
| Borrower segment | Risk segment exists on accounts, but event-level identity links are unreliable and current snapshots may not reflect historical segment. | **Preliminary only:** segment differences cannot be treated as historical or causal findings. | Reconstruct as-of segment and compare within appropriate DPD and loan-type strata using validated identities. |

## 3. Material data-quality findings that limit conclusions

- **Payment duplicates:** 25,500 source rows reduce to 25,000 candidate unique payment IDs, with 500 duplicate-ID groups. The candidate dataset is not automatically a fully reconciled payment ledger.
- **Payment references:** 3,746 repeated references were observed; 3,408 repeated-reference groups have conflicting details. Do not deduplicate on `payment_reference` alone.
- **Reversals:** 1,254 records have status `REVERSED`, but reliable links from reversals to the corresponding successful payments are not established. Net recovery therefore cannot be reliably reconstructed from these records alone.
- **Payment/account identity:** 24,617 candidate payment rows have borrower IDs that mismatch the current account master. This is a critical limitation for borrower-level attribution and segmentation.
- **Account master:** 13,029 accounts have outstanding greater than principal, and 455 borrower IDs are missing. These observations require business-rule validation; they should not be silently corrected.
- **Borrower master:** 30,600 rows contain only 11,015 distinct borrower IDs. Conflicting profiles should be retained for investigation rather than arbitrarily collapsed.
- **Status-history timestamps:** 30,191 rows have `recorded_at` before `event_at`, while 29,809 have it after. This pattern may reflect timestamp semantics or timezone issues, but it does not by itself prove ingestion latency.
- **Contact-channel records:** SMS/WhatsApp event and message/account relationships contain duplicate or cross-account conflicts. `DELIVERED`, `CLICKED`, `CONTACTED`, `PAID`, and `KEPT` are not, by themselves, proof of reconciled cash recovery.
- **Coverage:** payment events run through 2026-08-08. August is partial, and the available payment events do not cover a complete 12-month period.
- **Missing measures:** reliable intervention costs, confirmed payment currency, explicit language, client identifier, and verified timezone definitions were not established from the supplied files.

These are not minor caveats: they directly limit the ability to attribute payments to borrowers, calculate net recovery, compare agents/vendors/channels, and verify an asserted improvement.

## 4. Recommendation for the ₹10 Cr investment decision

### Recommended approach: staged investment, not immediate full deployment

**Gate 0 — measurement readiness**

Before using the analysis to commit material funding:

1. Confirm payment currency, timestamp/timezone semantics, business definitions, and the authoritative payment ledger.
2. Reconcile successful payments and reversals; document treatment of pending, failed, duplicate, and disputed transactions.
3. Repair account/borrower identity links and reconstruct effective-dated account, agent, and vendor histories.
4. Define the eligible portfolio, attribution window, exclusions, cost allocation, and customer-protection guardrails.

**Pilot — targeting versus current process**

Randomize eligible accounts at account level to business-as-usual control and a better-targeting treatment, stratifying using validated as-of DPD, risk segment, and loan type. Where operationally feasible, add separately randomized digital/WhatsApp and/or voice arms. Avoid bundling multiple interventions if the goal is to learn which one creates incremental value.

**Primary outcome**

Use **incremental reconciled net recovery per eligible account** over a pre-specified follow-up period. Predefine how successful payments, fees, refunds, reversals, and attribution windows are treated.

Secondary measures can include verified right-party contact (RPC), kept promises to pay validated against the payment ledger, cost per incremental rupee recovered, operational capacity, complaints, and opt-outs. Contact and promise statuses must not be substituted for cash recovery.

**Scale gate**

Scale only if the pilot's pre-specified analysis supports positive incremental net recovery, the lower confidence bound meets the agreed decision threshold, fully loaded unit economics meet Finance's hurdle, and complaint/opt-out/consumer-protection guardrails do not worsen materially.

### Why this is the defensible choice

- Better targeting can be tested without assuming current channel associations are causal.
- Randomization provides a counterfactual and helps separate intervention effects from portfolio mix, seasonality, and regression to the mean.
- A staged pilot preserves the option to invest later in telephony, staffing, AI voice, digital channels, or field operations once incremental effects and fully loaded costs are measured.
- Current evidence does not establish that field operations, voice, WhatsApp, agents, or any specific vendor delivers the best ROI.

This recommendation is **not** a finding that targeting has the highest expected ROI. It is the most defensible next decision given the current uncertainty and measurement limitations.

## 5. ROI, cost, break-even, downside, and confidence

### Why numeric ROI is not reported

A defensible numeric ROI or break-even estimate cannot be calculated from the supplied files because verified net recovery, validated currency, intervention cost, and causal uplift are not available. Do not fabricate an uplift percentage, assume that the full ₹10 Cr is spent immediately, or treat gross successful payment amounts as net recovery.

Finance and Operations should supply the intended budget allocation, implementation costs, recurring costs, and capacity assumptions. Once the pilot estimates incremental recovery, calculate:

- **Incremental net recovery:** treatment net recovery minus the estimated control counterfactual, scaled only to the intended eligible population and supported by the experimental design.
- **Net benefit:** incremental net recovery minus fully loaded incremental intervention cost.
- **ROI:** net benefit divided by fully loaded incremental intervention cost.
- **Break-even:** the point where incremental net recovery equals fully loaded incremental intervention cost.
- **Downside case:** a conservative uplift estimate (including the lower confidence bound where appropriate), higher implementation costs, slower adoption, and any deterioration in reversals, complaints, opt-outs, or other guardrails.

Report the assumed scale-up population and time horizon alongside any ROI estimate. Do not extrapolate a short pilot to the full portfolio without stating and defending the extrapolation assumptions.

### Decision confidence

- **High confidence:** current data quality is inadequate for a causal agent/vendor/channel ranking, and the 11% claim is not established as a sustained improvement in net recovery by the available evidence.
- **Moderate confidence:** payment/identity reconciliation and controlled measurement should precede a major investment decision.
- **Low confidence:** which of the six investment options will ultimately maximize ROI. The current dataset cannot answer that causal question.

## 6. Minimum pilot design

- Randomize at account level, not event level, and preserve assignment even if the borrower is unreachable (intention-to-treat analysis).
- Stratify using validated as-of DPD, risk segment, and loan type; use geography or prior contact intensity only if their data is sufficiently reliable.
- Pre-register the primary metric, treatment exposure, attribution window, exclusions, sample-size/power calculation, analysis method, and stopping rules.
- Reconcile account-level exposure and payments/reversals before outcome scoring; prevent overlapping treatments from contaminating the comparison.
- Monitor complaints, opt-outs, vulnerable borrowers, contact-frequency limits, and regulatory compliance as explicit guardrails.
- Document limitations and do not describe an association as causal unless the design and analysis support that claim.

## 7. Final answer to Question 2

The supplied data does not identify a defensible causal explanation for the claimed 11% improvement. The strongest bounded result is that the tested one-variable portfolio-mix adjustments (loan type, risk segment, and DPD band) changed monthly payment success share by no more than about 0.08 percentage points under the current method. That result does not establish the cause of overall recovery movement. Several other drivers—especially agent, vendor, channel, geography, and borrower segment—remain unresolved because identity links, historical attributes, exposure definitions, or timestamps are unreliable or unavailable.

Therefore, the correct conclusion is **not that no driver mattered**, but that the available data cannot reliably distinguish causal drivers from data-quality artifacts and confounding. Repair measurement first, then use a controlled pilot to determine which intervention produces incremental net recovery.


## Final Decision and Investment Guardrails

### Decision

Do not commit the full ₹10 Cr to a single intervention based on the current observational data. First establish reliable payment attribution, net recovery, costs, and outcome denominators. Then run a controlled pilot of improved borrower targeting against business-as-usual operations.

### Proposed investment sequence

1. **Measurement readiness:** reconcile borrower and payment identities, reversal linkage, currency, event timestamps, and cost data.
2. **Controlled targeting pilot:** randomize eligible accounts into treatment and control groups before intervention. Define eligibility, assignment, outcome window, and exclusions in advance.
3. **Evaluation:** compare incremental reconciled net recovery, cost per rupee recovered, and operational and customer guardrails.
4. **Scale decision:** expand only if results are robust, economically viable, and consistent with customer-protection requirements.

### Financial limitations

The current evidence does not support a reliable numerical estimate of incremental recovery, ROI, or break-even time. Do not present an invented financial return as a forecast. Calculate these only after obtaining verified INR-denominated net recovery, intervention costs, eligible portfolio size, and a defensible control-group estimate.

### Confidence

- High confidence that current data-quality limitations prevent a reliable causal investment ranking.
- Moderate confidence that identity reconciliation and controlled measurement are necessary prerequisites.
- Low confidence in which intervention will deliver the highest incremental ROI until tested.

### Downside and safeguards

The pilot may produce no measurable improvement, increase costs, or create customer-experience risks. Predefine a budget cap, minimum detectable effect, evaluation window, stop criteria, and customer-protection guardrails. Do not scale on contact, message delivery, or PTP status alone; use reconciled net recovery.
