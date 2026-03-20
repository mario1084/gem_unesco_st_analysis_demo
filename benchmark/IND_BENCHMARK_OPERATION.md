# ind_benchmark.py — Comprehensive Indicator Benchmark Comparison

**Purpose:** Compare internal pipeline indicator estimates against authoritative UNESCO/World Bank benchmarks to validate calculation logic and identify methodological deviations.

**Input:** `output/indicators/all_indicators_combined.csv` (computed by `R/pipeline/04_indicators.R`)
**Benchmark Data:** `data/benchmark/{uis,wide,learning_finance}_benchmarks.csv`
**Output:** `benchmark/ind_benchmark.md` (comprehensive comparison report)

---

## Execution Flow

### 1. Load Internal Indicators
```python
internal_df = pd.read_csv('output/indicators/all_indicators_combined.csv')
```
- Reads all computed indicators: household_core, learning_layer, admin_reference, finance_layer
- Columns required: `country_code`, `survey_year`, `indicator_id`, `indicator_family`, `rate` or `estimate`, `cohort_type`, `disaggregation_level`

### 2. Load Benchmark References
```python
wb_df = pd.read_csv('data/benchmark/uis_benchmarks.csv')
wide_df = pd.read_csv('data/benchmark/wide_benchmarks.csv')
lf_df = pd.read_csv('data/benchmark/learning_finance_benchmarks.csv')
```
Three authoritative sources with different granularity:

| Source | Coverage | Advantage | Limitation |
|---|---|---|---|
| **WIDE** | ARG, HND, PRY (2019-2024) | Microdata-based; includes sex/location/wealth disaggregation | Limited to survey years |
| **World Bank (UIS API)** | 190+ countries (2010-2024) | Comprehensive time coverage; updated regularly | Administrative data (may inflate) |
| **Learning/Finance** | 100+ countries; learning (2015-2024), finance (2000-2024) | Official indicators from UNESCO/OECD | Sparse for some countries |

### 3. Aggregate National-Level Internal Indicators
```python
int_agg = int_nat.groupby(['country_code', 'survey_year', 'indicator_id', 'level',
                           'indicator_family', 'cohort_type'], dropna=False)['val'].mean()
```
- Filters to national-level disaggregation (excludes sex, location, wealth breakdowns)
- Groups by country/year/indicator/level/family
- Preserves `cohort_type` to distinguish standard vs. harmonized series
- Takes mean to handle rare duplicates in internal data

### 4. Prepare Benchmark Data

#### WIDE Preparation
```python
wide_comp_agg = wide_df[wide_df['category'] == 'Location'].copy()
```
- Uses broadest category ('Location') to ensure one row per country/year/metric
- Columns: `comp_prim_v2_m`, `comp_lowsec_v2_m`, `comp_upsec_v2_m`, `eduout_prim_m`, `eduout_lowsec_m`
- These are microdata-driven rates (0-1 scale)

#### World Bank Preparation
```python
wb_df['country_code'] = wb_df['country_code_uis'].map({'AR': 'ARG', 'HN': 'HND', 'PY': 'PRY'})
```
- Maps 2-letter ISO codes to 3-letter pipeline codes
- Columns: `uis_indicator_id`, `uis_value`, (survey_year, country_code)

---

## Comparison Logic by Indicator Family

### A. Household Core Indicators

#### COMP_LVL (Completion Rates)
```python
# Match: internal COMP_LVL + household_core vs. WIDE comp_prim/lowsec/upsec columns
merged = pd.merge(int_agg[COMP_LVL], wide_comp_agg, on=['country_code', 'survey_year'])
```
**Comparison Strategy:** WIDE preferred (microdata-driven, avoids administrative inflation)

| Level | WIDE Column | Definition |
|---|---|---|
| Primary | `comp_prim_v2_m` | % of primary-age cohort with primary completion |
| Lower Secondary | `comp_lowsec_v2_m` | % of lower-secondary-age cohort with LS completion |
| Upper Secondary | `comp_upsec_v2_m` | % of upper-secondary-age cohort with US completion |

**Status Logic:**
- 🟢 Good: `abs(internal - benchmark) < 0.05` (5 percentage points)
- 🟡 Review: `abs(internal - benchmark) < 0.15` (15 percentage points)
- 🔴 High Dev: `abs(internal - benchmark) ≥ 0.15` (major deviation)

#### OOS_LVL (Out-of-School Rates)
```python
# Match: internal OOS_LVL + household_core vs. WIDE eduout_prim/lowsec columns
merged = pd.merge(int_agg[OOS_LVL], wide_comp_agg, on=['country_code', 'survey_year'])
```
**Comparison Strategy:** WIDE preferred (microdata-driven)

| Level | WIDE Column | Definition |
|---|---|---|
| Primary | `eduout_prim_m` | % of primary-age cohort out-of-school |
| Lower Secondary | `eduout_lowsec_m` | % of LS-age cohort out-of-school |

**Special Status:** 🔴 **Metric Mismatch** if `diff > 1.5` (indicates fundamental definition issue, e.g., attendance vs. enrollment mismatch)

#### LIT_RATE (Literacy Rates)
```python
# Try WIDE first: wide_df[literacy_1524_m].notna()
# If no WIDE, fallback to WB: wb_df[uis_indicator_id == 'LIT_RATE']
```
**Comparison Strategy:** WIDE → WB fallback

1. **WIDE Match (if available):** 15-24 age range
   ```python
   sub_wide_lit = wide_df[wide_df['literacy_1524_m'].notna()]
   ```

2. **WB Fallback (if WIDE unavailable):**
   ```python
   sub_wb_lit = wb_df[wb_df['uis_indicator_id'] == 'LIT_RATE']
   ```

**Current Status by Country:**
- ARG: 0 WIDE records → Using **WB Fallback** (2021-2024)
- HND: 0 recent WIDE records → Using **WB Fallback** (2023)
- PRY: 0 WIDE records → Using **WB Fallback** (2021-2024)

**Note:** LIT_RATE excluded from WIDE-only assessment (WIDE literacy data unpopulated); treated as internal estimate with WB validation only.

#### ATTEND_LVL (Attendance Rates)
```python
# Match: internal ATTEND_LVL + household_core vs. WB (no valid benchmark)
# All UIS entries for ATTEND_LVL are null — no comparison performed
```
**Status:** No valid benchmark available; internal estimate only.

---

### B. Secondary Layer Indicators

#### Learning Layer
```python
# Match: internal learning indicators vs. learning_finance_benchmarks
# Fallback to WB if learning_finance unavailable
if not lf_df.empty:
    merged_lrn = pd.merge(sub_int_lrn, lf_df,
                          left_on=['country_code', 'survey_year', 'indicator_id'],
                          right_on=['country_code', 'survey_year', 'learning_indicator_id'])
```

**Sources:** ERCE, PISA, PISA-D proxies (World Bank) or Learning/Finance benchmark

#### Admin/Reference Layer
```python
# Match: internal admin indicators (population, enrollment) vs. WB or dedicated benchmarks
merged_adm = pd.merge(sub_int_adm, wb_df,
                      left_on=['country_code', 'survey_year', 'indicator_id'],
                      right_on=['country_code', 'survey_year', 'uis_indicator_id'])
```

#### Finance Layer
```python
# Match: internal finance indicators (ODA, education expenditure) vs. OECD/World Bank
merged_fin = pd.merge(sub_int_fin, wb_df,
                      left_on=['country_code', 'survey_year', 'indicator_id'],
                      right_on=['country_code', 'survey_year', 'uis_indicator_id'])
```

---

## Cohort Type Handling (Standard vs. Harmonized Series)

### Cohort_Type Column
The internal indicators carry a `cohort_type` field that distinguishes:

- **`standard`** or `null` — Standard cohort (e.g., Age 20-29, all data)
- **`harmonized_age25to29_validonly`** — Harmonized cohort (Age 25-29, valid-only denominator)

### Preservation Through Pipeline
```python
# Group by cohort_type to preserve distinction
int_agg = int_nat.groupby([..., 'cohort_type'], dropna=False)['val'].mean()

# Carry cohort_type through to comparisons
cohort = row.get('cohort_type', 'standard') if pd.notna(row.get('cohort_type')) else 'standard'
comparisons.append({..., 'Cohort_Type': cohort})
```

### Visual Distinction in Report
```python
# Asterisk marker for harmonized series
is_harmonized = pd.notna(cohort_type) and 'harmonized' in str(cohort_type)
country_marker = " *" if is_harmonized else ""
```

**Output Example:**
```
| Household Core | COMP_LVL | primary | HND * | 2023 | 0.7850 | 0.8480 | 0.0630 | WIDE | 🟡 Review |
```
The `*` indicates this row is a harmonized series (Age 25-29, valid-only).

---

## Honduras 2023 Two-Track Reconciliation

### Purpose
Demonstrate that Honduras 2023 completion gaps vs. WIDE are **methodological, not computational**.

### Implementation
```python
# Extract harmonized series for Honduras 2023
harmonized_data = internal_df[
    (internal_df['country_code'] == 'HND') &
    (internal_df['survey_year'] == 2023) &
    (internal_df['indicator_id'] == 'COMP_LVL') &
    (internal_df['cohort_type'] == 'harmonized_age25to29_validonly')
]
```

### Results Documentation
The report includes a dedicated section showing both series side-by-side:

| Indicator | Level | Internal (Standard: Age 20-29) | Internal (Harmonized: Age 25-29) | WIDE | Gap Standard | Gap Harmonized |
|---|---|---|---|---|---|---|
| COMP_LVL | Primary | ~0.76 | ~0.85 | 0.848 | -8.36pp | +0.20pp |
| COMP_LVL | Lower Secondary | ~0.37 | ~0.55 | 0.548 | -17.8pp | +0.20pp |
| COMP_LVL | Upper Secondary | ~0.17 | ~0.42 | 0.417 | -24.7pp | +0.30pp |

### Interpretation
- **Standard series gap:** Due to including 20-24 age group (high-mobility age, many still in school)
- **Harmonized series alignment:** When restricted to Age 25-29 (post-secondary decision-making age) and excluding missing values, WIDE-level alignment achieved
- **Conclusion:** Gap is survey design interaction (survey captures different population stage), not mapping error

---

## Status Codes & Interpretation

### Completion & OOS
- 🟢 **Good** (`diff < 0.05`) — Excellent alignment; expected variation
- 🟡 **Review** (`diff < 0.15`) — Minor deviation; investigate if trend consistent
- 🔴 **High Dev** (`diff ≥ 0.15`) — Major deviation; review indicator logic and data completeness
- 🔴 **Metric Mismatch** (OOS only, `diff > 1.5`) — Fundamental definition issue (e.g., attendance vs. enrollment confusion)

### Learning/Finance/Admin Layers
- 🟢 **Good** (`diff < 0.05`)
- 🟡 **Review** (`diff < 0.15`)
- 🔴 **High Dev** (`diff ≥ 0.15`)

---

## Troubleshooting

### No comparisons generated?
- **Check:** Are benchmark CSV files present in `data/benchmark/`?
- **Check:** Do internal indicators have `disaggregation_level == 'national'`?
- **Check:** Are country codes consistent (ARG, HND, PRY)?

### All benchmarks missing for a country?
- **Check:** Benchmark CSV files may need refreshing:
  ```bash
  python fetch_benchmarks.py
  python sc_indicators.py
  python sc_learning_finance.py
  ```

### Cohort_type column not flowing through?
- **Check:** `R/pipeline/04_indicators.R` must include `cohort_type` in indicator output
- **Check:** No filter that drops rows with specific `cohort_type` values

### Honduras 2023 harmonized series not appearing?
- **Check:** Indicator computation must set `cohort_type = 'harmonized_age25to29_validonly'` for those rows
- **Check:** Data must have `country_code == 'HND'`, `survey_year == 2023`, `indicator_id == 'COMP_LVL'`

---

## Development & Iteration

### Testing Output Locally
```python
# Run script in repo root:
python benchmark/ind_benchmark.py

# Check output:
cat benchmark/ind_benchmark.md
```

### Adding New Benchmark Sources
1. Add fetcher script: `fetch_newsource.py`
2. Store data: `data/benchmark/newsource_benchmarks.csv`
3. Add merge logic in `ind_benchmark.py` (similar to WB/WIDE pattern)
4. Update this document

### Modifying Status Thresholds
Edit status calculation (line ~241):
```python
status = "🟢 Good" if row['Diff'] < 0.05 else ("🟡 Review" if row['Diff'] < 0.15 else "🔴 High Dev")
```

---

## See Also
- **Pipeline:** `R/pipeline/04_indicators.R` (produces internal indicators)
- **Data Fetching:** `fetch_benchmarks.py`, `sc_indicators.py`, `sc_learning_finance.py`
- **Benchmark Analysis:** `benchmark/ind_benchmark.md` (current report)
- **Development Proposals:** `benchmark/other/ind_proposals_fix.md`
