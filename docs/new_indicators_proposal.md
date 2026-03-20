# Proposal for Indicator Methodological Adjustments

Building upon the canonical specifications in `gem_method_indicator.md`, this document provides actionable recommendations and methodological adjustments based on the comprehensive benchmark comparison between our internal household-survey estimators and the official UNESCO/World Bank data (including WIDE bulk data).

## 1. Analysis of Benchmark Deviations

The recent execution of our `ind_benchmark.py` comparison revealed the following regarding our core household indicators, aggregated perfectly by Country, Year, and Level:

### 1.1 Completion Rate (`COMP_LVL`)
*   **Primary Level:**
    *   **Observation:** Estimates for Argentina (2021-2023) and Honduras (2021-2023) show a "Good" match (deviations < 5%). Paraguay shows a "Review" status (deviations ~9-12%).
    *   **Diagnosis:** This is generally an Acceptable deviation. Minor differences are expected when comparing directly computed survey data against UNESCO/World Bank estimates, which often employ cross-survey interpolation and minor smoothing models.
*   **Lower Secondary Level:**
    *   **Observation:** **High Deviation** across Honduras and Paraguay (differences of 25% to 48%). For Argentina, it remains Good.
    *   **Diagnosis:** The internal calculation for lower secondary completion in HND and PRY is yielding significantly higher rates (~83% for HND, ~99% for PRY) compared to the official benchmarks (~37% for HND, ~73% for PRY). This points to a severe misalignment in defining the correct graduation age cohort for lower secondary in these two countries.

### 1.2 Literacy Rate (`LIT_RATE`)
*   **Observation:** The mean absolute difference across all measured years (Honduras and Paraguay) is essentially **0.0000**.
*   **Diagnosis:** This is a **Perfect** match. The harmonization of literacy variables (`ED01` for Honduras, `ED02` for Paraguay) accurately reflects the canonical logic.
*   **Recommendation:** No changes required.

### 1.3 Out-of-School Rate (`OOS_LVL`)
*   **Observation:** Massive numerical mismatch for all records (e.g., 318,905 vs 0.0000).
*   **Diagnosis:** 
    1.  **Metric Mismatch:** The primary benchmark used (World Bank `SE.PRM.UNER`) represents the *absolute number* of out-of-school children, while our internal script calculates the *rate* (a share between 0 and 1).
    2.  **Internal Calculation Failure:** Despite the metric mismatch, the internal estimate for Honduras and Paraguay yielded exactly `0.0000` (meaning exactly 0% out of school). For Argentina, it yielded an unusually high ~65%. Both of these extreme bounds indicate a fundamental logic failure in the harmonization of `attending_currently_h` or the eligible universe filter for these countries.

### 1.4 Missing Benchmarks (`ATTEND_LVL`, `REP_RATE`, `Upper Secondary`)
*   **Observation:** Attendance Rates, Repetition Rates, and Upper Secondary metrics are absent from the final benchmark report.
*   **Diagnosis:** Despite being mapped in our python script, the World Bank and WIDE databases often have sparse coverage for these specific indicators in recent years (2021-2024). For instance, World Bank often lacks recent survey-based repetition data, and WIDE's upper-secondary metrics are inconsistently published.

## 2. Proposed Adjustments

### 2.1 Adjustments to Formula and Universe Construction

**Lower Secondary Completion (`COMP_LVL`)**
*   **Current Issue:** Massive overestimation in HND and PRY.
*   **Proposed Fix:** Re-evaluate the `age_universe` parameter used in `run_completion_estimation` for the `lower_secondary` tier. Ensure it strictly aligns with the ISCED mapping for graduation age + 3 to 5 years. If the official graduation age is 15, the cohort should be 18-20. An overestimation this large implies we are evaluating an older cohort where delayed completion has artificially inflated the rate.

**Out-of-School Rate (`OOS_LVL`)**
*   **Current Issue:** Returns 0% (HND/PRY) or 65% (ARG).
*   **Proposed Fix:** 
    *   Verify the definition of $O_i=1$. A child is out of school if they are *not attending* primary, secondary, or higher education. 
    *   Ensure pre-primary attendance is correctly classified according to the latest VIEW guidelines.

### 2.2 Adjustments to the Harmonization Layer (`02_harmonize`)

*   **Honduras (`EPHPM`) & Paraguay (`EPHC`) `attending_currently_h`:**
    *   A 0.000 out-of-school rate means no child was found with `attending_currently_h == 0` within the target age subset. The missing value (NA) handling in the harmonization scripts must be reviewed. Non-responses or skip-logic blanks must not be erroneously filled as "attending."
*   **Argentina (`EPH`) Age Filters & Attendance:**
    *   The 65% OOS rate for Argentina suggests that the level assignment (`NIVEL_ED`) is dropping valid students. The `CH08` mapping must be revisited to ensure all valid primary school codes are captured.
