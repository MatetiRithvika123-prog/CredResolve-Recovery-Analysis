# Executive Decision Memo
## CredResolve — Recovery Performance Investigation

**Decision requested:** Validate recovery measurement and run a controlled targeting pilot before committing the full ₹10 Cr investment.

### Executive conclusion

The available payment data does not establish that underlying recovery improved by 11% month-on-month. Gross successful payment amount increased by 11.03% from February to March 2026, and successful payment count increased by 11.29%. However, payment-level success share fell from 71.52% to 70.56%, while account-level success share fell from 72.19% to 72.04%. Neither success-share difference was statistically significant in the preliminary two-proportion tests (p = 0.3850 and p = 0.8899, respectively). These tests do not establish causality and have independence and confounding limitations.

The amount increase is a descriptive result, not proof of a sustained improvement in recovery. Gross successful payment amount fell 7.29% in April, rose 5.20% in May, fell 4.72% in June, and rose 6.65% in July. August covers only part of the month and should not be compared directly with full months.

### What the data supports

- **Fact:** February-to-March gross successful payment amount increased 11.03%; successful payment count increased 11.29%.
- **Fact:** Payment-level success share decreased 0.96 percentage points; account-level success share decreased 0.16 percentage points.
- **Fact:** Holding each of loan type, risk segment, or current DPD-band mix fixed separately changed monthly success-share estimates by no more than 0.08 percentage points in the tested standardization. These are payment-weighted analyses using current account snapshots, not historical portfolio states.
- **Correlation, not causation:** 7.12% of targeting events were followed by a SUCCESS-status payment within 30 days. Target events overlap; payments can occur without targeting; configured campaign channel is not verified actual contact.
- **Hypothesis to test:** Better targeting may improve recovery efficiency, but current observational data cannot establish incremental impact or ROI.

### Data reliability and decision risks

The payment candidate contains 25,000 unique payment IDs after duplicate handling. The raw payment file had 500 duplicate payment-ID groups; 368 candidate records have missing payment references. Borrower IDs conflict with account-master mappings in 24,617 payment records.There are 1,254 REVERSED records in the candidate dataset. Reliable linkage from these records to the corresponding original successful payments remains unresolved; therefore, net recovery cannot yet be verified. Currency and timezone semantics are unconfirmed.

Other critical issues include conflicting borrower profiles, inconsistent agent master records, and call-attempt/call relationships that cannot safely be joined on call_id alone. These defects can bias borrower, agent, channel, and campaign attribution. A SUCCESS status is not yet equivalent to verified net recovery.

### Recommended investment approach

Do not allocate the full ₹10 Cr based on the current 11% claim. First fund data-quality remediation, transaction reconciliation, and measurement controls. Then run a randomized account-level experiment comparing improved targeting with the existing process, stratified by pre-treatment portfolio risk and DPD. Use a pre-specified follow-up window and verified net recovery per randomized account as the primary outcome. Monitor incremental cost, customer complaints, wrong-party contacts, and opt-outs.

Scale only when the experiment shows a sufficiently precise positive incremental net recovery, a credible positive return after costs, and no unacceptable customer-harm increase. Until transaction linkage, currency, and metric definitions are approved, any ROI or break-even estimate would be speculative.

### Required next steps

1. Approve definitions for gross recovery, net recovery, reversals, currency, and attribution.
2. Resolve identity and transaction-linkage defects; publish data-quality gates and lineage.
3. Establish a baseline and calculate experiment sample size using historical variance and a minimum business-relevant effect.
4. Run the controlled pilot; report confidence intervals, costs, operational risks, and customer outcomes.
5. Revisit the ₹10 Cr allocation using measured incremental economics rather than observational attribution.

**Confidence:** Moderate that the observed payment metrics do not substantiate a general, sustained 11% recovery improvement; low that the current data can identify the best investment option or its ROI.
