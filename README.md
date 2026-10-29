# CredResolve — Recovery Performance Investigation

## 1. Project Overview

This project investigates the claim that **loan recovery improved by 11% month-on-month** using payment, account, borrower, campaign, call-center, and related operational datasets.

The objective is to determine what the available data supports, identify data-quality and attribution risks, examine observed payment trends, and recommend a defensible approach for measuring incremental recovery before committing a ₹10 crore investment.

The analysis combines Python-based data preparation, SQL quality checks, statistical comparisons, campaign-targeting analysis, audit reports, and a proposed production analytics architecture.

**Key conclusion:** The observed February-to-March increase in gross successful payment amount was approximately 11.03%. However, this does not establish an 11% improvement in the underlying recovery rate or incremental net recovery. Significant entity-linkage and measurement limitations prevent a definitive conclusion.

## 2. Business Questions

The investigation addresses the following questions:

- Did recovery genuinely improve by approximately 11% month-on-month?
- How reliable are the payment, account, and borrower records?
- Could portfolio composition or operational factors explain the observed trends?
- What associations exist between campaign targeting and subsequent successful payments?
- Which recovery metrics can be calculated reliably, and which require additional data?
- How should a ₹10 crore investment be evaluated when incremental recovery and cost attribution are uncertain?
- What production analytics controls are needed to improve data reliability and decision-making?

## 3. Repository Structure

```text
CredResolve_Assignment/
├── data/
│   ├── raw/                  # Source datasets and data dictionary
│   ├── staging/              # Intermediate transformation outputs
│   ├── golden/               # Validated candidate datasets
│   └── quarantine/           # Records requiring investigation
├── notebooks/
│   └── 01_data_profiling.ipynb
├── reports/
│   ├── executive_decision_memo.md
│   ├── investigation_notes.md
│   ├── metric_definitions_and_limits.md
│   ├── driver_analysis_and_investment_recommendation.md
│   ├── counterfactual_experiment_design.md
│   ├── production_analytics_architecture.md
│   ├── production_analytics_architecture.mmd
│   ├── recovery_performance_dashboard.png
│   └── supporting audit and analysis outputs
├── sql/
│   ├── 01_payment_quality_checks.sql
│   ├── 02_entity_integrity_checks.sql
│   ├── 03_campaign_targeting_analysis.sql
│   ├── 04_data_quality_monitoring.sql
│   └── README.md
├── src/
│   ├── build_golden_datasets.py
│   ├── build_part1_audit_outputs.py
│   ├── validate_golden_datasets.py
│   └── load_postgres.py
├── .gitignore
└── README.md
```

The `data/raw/` directory contains the source datasets supplied for the analysis. Intermediate outputs, candidate datasets, and quarantined records are kept separate to support traceability.

The `data/golden/` datasets are analytical candidates, not a claim that every entity relationship has been fully resolved. Known data-quality limitations are documented in the supporting reports.

## 4. Environment Setup

### Prerequisites

- Python 3.11 or another compatible Python version
- Git
- PostgreSQL, if executing the SQL scripts against PostgreSQL
- Python packages required by the notebook and scripts

The local virtual environment is not included in the repository. Create a new environment when setting up the project on another machine.

### Windows PowerShell

Run the following commands from the project root:

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install --upgrade pip
python -m pip install pandas numpy matplotlib jupyter
```

Install any additional packages required by the notebook or scripts if prompted. The commands above install common analysis dependencies; they are not a guarantee that every project component has been reproduced in a clean environment.

To open the profiling notebook:

```powershell
python -m jupyter notebook notebooks/01_data_profiling.ipynb
```

### PostgreSQL

The SQL scripts are intended for PostgreSQL. Configure a suitable database connection before running database-dependent steps.

Review `src/load_postgres.py` and `sql/README.md` for the expected loading and execution workflow. Use your own local credentials and environment variables; do not commit passwords, connection strings, or other secrets.

## 5. Rebuilding the Golden Candidate Datasets

Run the following commands from the project root after activating the Python environment:

```powershell
python src/build_golden_datasets.py
python src/validate_golden_datasets.py
```

The pipeline generates candidate datasets under `data/golden/` and writes a validation report to:

`reports/golden_dataset_validation_report.csv`

The pipeline summary is written to:

`reports/golden_pipeline_summary.json`

Additional audit outputs can be generated using:

```powershell
python src/build_part1_audit_outputs.py
```

Run the audit-output script according to the project's intended workflow and inspect its outputs before treating them as final results. If a script requires additional dependencies or configuration, resolve those requirements first.

### Data preparation principles

- Preserve original source files.
- Track duplicate records and conflicting identifiers explicitly.
- Separate staging, candidate, and quarantined records.
- Avoid deduplicating payments solely by payment reference when references are reused or associated with conflicting details.
- Avoid treating a current account or borrower snapshot as a historically accurate record.
- Preserve unresolved borrower-profile conflicts rather than choosing an unsupported authoritative profile.
- Keep financial amounts in their original precision; do not introduce floating-point rounding into financial reconciliation.

## 6. Key Findings

### Payment quality and entity integrity

- The raw payment dataset contains **25,500 rows** and **500 duplicate payment-ID groups**.
- The payment candidate contains **25,000 rows** with **25,000 unique payment IDs**.
- The candidate contains **368 missing payment references**.
- **24,617 payment candidate records** have borrower IDs that disagree with the current account master.
- Repeated payment references often have conflicting associated details, so reference-only deduplication is not a reliable reconciliation strategy.
- Borrower records contain substantial duplication and conflicting profiles. These conflicts remain unresolved in the candidate data.

These findings materially limit the reliability of payment-to-borrower attribution and any calculation requiring a verified borrower or account-level recovery outcome.

### February-to-March comparison

The observed gross successful payment amount increased by approximately **11.03%** from February to March.

However:

- The payment-level success share decreased by approximately **0.96 percentage points**.
- The account-level success share among accounts with payment activity decreased by approximately **0.16 percentage points**.
- The preliminary statistical tests for these success-share comparisons were not statistically significant at the 5% level.
- These measures are not equivalent to a verified whole-portfolio recovery rate.

**Interpretation:** The 11.03% increase refers to gross successful payment amount from February to March. It does not establish an 11% increase in recovery rate, net recovery, or incremental recovery attributable to an intervention.

### Coverage and attribution limitations

- The available payment records cover January through August, but August is only a partial month, with records through August 8.
- Currency semantics and timezone interpretation remain unresolved.
- Reversal records cannot be reliably linked to their original successful payments using the available references alone.
- Campaign targeting followed by a successful payment indicates an association, not necessarily a causal effect.
- Configured campaign channels do not necessarily establish which channel actually contacted a borrower.
- Agent, vendor, borrower, and account attribution is affected by conflicting or inconsistent identifiers.
- Client, geography, and language dimensions are not sufficiently available or reliable for defensible driver conclusions.

The findings and their supporting evidence are documented in the `reports/` directory.

## 7. Statistical Investigation and Campaign Analysis

The analysis compares observed payment trends and account-level outcomes while examining data-quality constraints and selected portfolio attributes.

The investigation includes:

- Monthly payment and account-level summaries
- Preliminary statistical tests
- Portfolio-mix standardization for available attributes
- Campaign-targeting and payment-window sensitivity analyses
- Entity-integrity and duplicate-record audits
- Data-quality monitoring queries

Portfolio standardization based on current snapshot attributes is exploratory. It does not establish historical portfolio composition or eliminate all confounding factors.

Campaign-window analyses are observational and may involve overlapping targeting records. They must not be interpreted as proof that a campaign caused a successful payment.

See the relevant CSV outputs and analysis notes in `reports/` for detailed results.

## 8. Investment Recommendation

**Do not commit the full ₹10 crore investment based solely on the observed gross-payment increase.**

A more defensible approach is to establish measurement reliability first and then evaluate interventions through a controlled experiment.

### Recommended sequence

1. **Establish trustworthy measurement.** Resolve payment identifiers, account and borrower attribution, reversal linkage, currency definitions, timestamps, and the recovery denominator.
2. **Define the outcome.** Specify a measurable recovery outcome, observation window, cost treatment, and rules for handling reversals and duplicate events.
3. **Run a randomized account-level experiment.** Compare business-as-usual recovery operations with a clearly defined targeting intervention. Where sample size permits, test materially different intervention types in separate arms.
4. **Measure incremental impact.** Estimate the difference in verified net recovery between treatment and control, including uncertainty and implementation costs.
5. **Scale only with evidence.** Expand investment only if the measured incremental benefit, expected costs, operational feasibility, and downside risk justify it.

The current evidence does not support a reliable numerical ROI, break-even estimate, or incremental net recovery forecast. Those estimates require validated recovery outcomes and cost data, together with a defensible counterfactual.

## 9. Production Analytics Design

The proposed architecture and supporting documentation describe controls for a more reliable recovery analytics workflow, including:

- Data ingestion and staging
- Data-quality and entity-integrity checks
- Candidate golden datasets and auditability
- PostgreSQL-based analytical checks
- Metric definitions and monitoring
- Controlled experiment measurement
- Reporting and decision support

The architecture is documented in:

- `reports/production_analytics_architecture.md`
- `reports/production_analytics_architecture.mmd`

The Mermaid file contains the architecture diagram source.

## 10. Main Deliverables

| Deliverable | Location |
|---|---|
| Profiling notebook | `notebooks/01_data_profiling.ipynb` |
| Golden candidate datasets | `data/golden/` |
| Data-quality and entity audits | `reports/` |
| Golden dataset build and validation scripts | `src/` |
| PostgreSQL analysis scripts | `sql/` |
| Statistical comparison outputs | `reports/statistical_test_summary.csv` |
| Payment quality report | `reports/payment_quality_report.csv` |
| Borrower quality report | `reports/borrower_quality_report.csv` |
| Counterfactual experiment design | `reports/counterfactual_experiment_design.md` |
| Driver analysis and investment recommendation | `reports/driver_analysis_and_investment_recommendation.md` |
| Executive decision memo | `reports/executive_decision_memo.md` |
| Recovery performance dashboard | `reports/recovery_performance_dashboard.png` |
| Production analytics architecture | `reports/production_analytics_architecture.md` and `.mmd` |

## 11. Final Conclusion

The available data supports an approximately 11.03% increase in gross successful payment amount from February to March. It does **not** establish a sustained 11% improvement in underlying recovery performance.

Material data-quality, entity-linkage, reversal, coverage, and attribution limitations prevent a reliable estimate of verified incremental net recovery. The appropriate next step is to improve measurement reliability and run a controlled experiment before making a large investment decision.

This investigation therefore distinguishes observed trends from verified recovery outcomes and causal impact, providing a transparent basis for further analysis and investment evaluation.
