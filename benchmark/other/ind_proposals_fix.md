# Technical Proposals for Indicator Logic Correction

This document provides concrete, technical recommendations to resolve the performance deviations identified in the `ind_benchmark.md` report. These fixes focus on indicator-specific logic and universe definitions, preserving the global harmonization layer which is performing well for other metrics.

## 1. Completion Rate (`COMP_LVL`) - Lower Secondary Overestimation

### Problem
Internal estimates for Honduras (~83%) and Paraguay (~99%) are significantly higher than official benchmarks (~37% and ~73%).

### Root Cause: Late-Completion Bias
The current logic in `R/indicators/household/completion.R` uses a fixed reference age group of **20-29** for lower secondary.
*   **Methodological Error:** UIS/GEM methodology defines the completion rate based on the age group **3 to 5 years above the intended graduation age** for that level.
*   **Impact:** In HND and PRY, there is significant over-age enrollment. By looking at 20-29 year olds, we are capturing "lifetime completion" rather than "timely completion." This inflates the rate by including individuals who finished lower secondary much later than intended.

### Proposed Fix
1.  **Dynamic Reference Ages:** Modify `reference_age_groups` in `completion.R` to be country-specific or at least aligned with the ISCED graduation age.
2.  **Specific Adjustment:**
    *   For **Primary**: Shift from 15-24 to **14-16** (or Graduation Age + 3).
    *   For **Lower Secondary**: Shift from 20-29 to **17-19** (or Graduation Age + 3).
    *   This will align the estimator with the "near-on-time" completion concept used in official benchmarks.

---

## 2. Out-of-School Rate (`OOS_LVL`) - extreme Bounds (0% and 65%)

### Problem
The estimator returns exactly **0.00%** for HND/PRY (implying 100% attendance) and **~65%** for ARG (implying massive dropout).

### Root Cause A: Attendance Definition (Argentina)
In `attendance.R` and the crosswalk, the Argentina `attending_currently_h` variable is built using a complex rule: `ESTADO|CH08|NIVEL_ED`.
*   **Logic Flaw:** If a child is of primary age (6-11) but is attending a level that doesn't map perfectly to "primary" in the `NIVEL_ED` recode, the current logic may be flagging them as "not attending primary," and thus "out-of-school."
*   **Impact:** This severely underestimates attendance and overestimates OOS.

### Root Cause B: NA Handling (Honduras & Paraguay)
For HND and PRY, the 0.00% OOS rate implies that *not a single child* was found with `attending_currently_h == 0`.
*   **Logic Flaw:** This usually occurs when the harmonization script or the indicator `eligible_condition` filters out all non-attending individuals (e.g., if OOS status is only asked of those who say they are attending).
*   **Impact:** Only "in-school" children remain in the denominator, forcing the rate to 100%.

### Proposed Fixes
1.  **Universe Correction (OOS):** Modify `estimate_out_of_school` to ensure the denominator is built strictly on **Age** (`age_h`), regardless of whether the attendance variables are missing or not.
2.  **Inclusion of All Attendance (ARG):** Redefine the `indicator_condition` for OOS: A child is "In School" if they attend **ANY** level (Primary, Secondary, or even Pre-primary/Higher). OOS should be the complement of "Attending anything," not just "Attending the correct level."
3.  **NA Audit:** In `02_harmonize`, ensure that if `attending_currently` is missing, it is preserved as `NA` and handled correctly by `weighted_rate`, rather than being defaulted to "1" or filtered out of the denominator.

---

## 3. Repetition Rate (`REP_RATE`) - Data Sparsity

### Problem
The indicator is missing for most years/countries in the benchmark.

### Root Cause: Missing Raw Mappings
The `crosswalk.csv` shows `structural_missing` for repetition in ARG and PRY. Only HND has a mapping (`ED11`).

### Proposed Fix
1.  **Proxy Repetition:** For countries without a direct "Are you repeating?" question, implement a proxy logic: `Is Repeating = (Current Grade == Previous Year Grade)`. 
2.  **Harmonization expansion:** Investigate if Argentina's `NIVEL_ED` or Paraguay's `ED08` can be compared across time/waves to identify repeaters, though this may require longitudinal IDs which the EPH lacks.

---

## Summary of Logic Adjustments (Non-Harmonization)
| Indicator | Issue | Strategy |
|---|---|---|
| **COMP_LVL** | Overestimation | Narrow age universe to +3y from graduation age. |
| **OOS_LVL** | 0% / 65% Bounds | Base denominator on Age only; define OOS as complement of "Any Attendance." |
| **ATTEND_LVL** | Level mismatch | Allow over-age/under-age attendance to count in the numerator for the specific level. |
