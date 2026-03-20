# Benchmark Validation Suite

This directory contains scripts to fetch official benchmark data and compare internal pipeline indicators against authoritative UNESCO/World Bank standards.

## Directory Structure

```
benchmark/
├── fetch_benchmarks.py          [Data fetcher: World Bank UIS API]
├── sc_indicators.py             [Data fetcher: WIDE bulk data]
├── sc_learning_finance.py       [Data fetcher: Learning & Finance indicators]
├── ind_benchmark.py             [Main comparison script]
├── ind_benchmark.md             [Generated benchmark report]
├── README.md                    [This file]
└── other/                       [Development/investigation (non-canonical)]
    ├── ind_proposals_fix.md     [Technical proposal docs]
    └── inspect_edu_vars.R       [Debugging scripts]
```

## Workflow

### 1. Data Fetching (Optional - Data Pre-Cached)

The three fetcher scripts download official benchmark data. These are typically run once to populate `data/benchmark/`:

- **`fetch_benchmarks.py`**: Queries World Bank Education API (mirrors UNESCO Institute for Statistics)
  - Attendance, Completion, Out-of-School, Literacy, Repetition rates
  - National-level and gender-disaggregated data
  - Output: `data/benchmark/uis_benchmarks.csv`

- **`sc_indicators.py`**: Intercepts WIDE (World Inequality Database on Education) bulk endpoint
  - Urban/Rural (location) disaggregations
  - Wealth quintile breakdowns
  - Upper secondary rates
  - Output: `data/benchmark/wide_benchmarks.csv`

- **`sc_learning_finance.py`**: Fetches learning indicators and finance flows
  - World Bank learning proxies (ERCE, PISA-D)
  - OECD DAC/CRS official education ODA flows
  - Output: `data/benchmark/learning_finance_benchmarks.csv`

### 2. Benchmark Comparison (Main Pipeline)

**`ind_benchmark.py`** is the primary analysis script that:

1. **Loads internal indicators** from `output/indicators/all_indicators_combined.csv`
2. **Loads benchmark references** from `data/benchmark/` (WIDE, WB, Learning/Finance)
3. **Performs intelligent comparisons** using fallback logic:
   - COMP_LVL (Completion) → WIDE preferred (avoids >100% administrative inflation)
   - OOS_LVL (Out-of-School) → WIDE preferred (microdata-driven)
   - LIT_RATE (Literacy) → WIDE first, WB fallback
   - ATTEND_LVL (Attendance) → Internal estimate only (no valid benchmark)
   - Learning Layer → Learning/Finance benchmark or WB fallback
   - Admin/Finance Layers → Dedicated benchmark sources

4. **Generates comprehensive report** → `ind_benchmark.md`
   - Marks status: 🟢 Good (<5% diff), 🟡 Review (<15% diff), 🔴 High Dev (>15% diff)
   - Distinguishes standard vs. harmonized cohorts with asterisk notation
   - Documents Honduras 2023 two-track reconciliation (methodological validation)
   - Explains smart fallback strategy and data source coverage

### How to Use

**Run the full pipeline with benchmarking (recommended):**
```bash
Rscript R/pipeline/01_data_acquisition.R
Rscript R/pipeline/02_harmonize.R
Rscript R/pipeline/03_combine_harmonized_data.R
Rscript R/pipeline/04_indicators.R
python benchmark/ind_benchmark.py
```

**Run benchmark comparison only (after indicators are generated):**
```bash
python benchmark/ind_benchmark.py
```

**Refresh benchmark data from sources (optional, if updates available):**
```bash
python fetch_benchmarks.py
python sc_indicators.py
python sc_learning_finance.py
```

## Key Features

### Fallback Logic
The script uses intelligent source selection to handle data sparsity:
- Prefers microdata-driven WIDE over administrative WB data for COMP_LVL, OOS_LVL
- Falls back to WB when WIDE unavailable
- Matches learning indicators to either Learning/Finance benchmark or WB proxy

### Two-Track Reconciliation
Honduras 2023 demonstrates two methodological variants of the same v17 ISCED mapping:
- **Standard series** (Age 20-29, all data) — survey-design-sensitive
- **Harmonized series** (Age 25-29, valid-only) — WIDE-level alignment
- Both share identical mapping logic; gap is methodological, not computational

### Quality Flagging
- 🟢 **Good**: <5% absolute difference (expected variance)
- 🟡 **Review**: 5-15% difference (minor investigation needed)
- 🔴 **High Deviation**: >15% difference (major investigation recommended)
- 🔴 **Metric Mismatch**: OOS showing extreme bounds (data definition issue)

## Output

**`ind_benchmark.md`** contains:
1. Coverage summary by indicator family
2. Detailed comparison table with all matches
3. Honduras 2023 harmonized series documentation
4. Benchmark source strategy explanation
5. Quality assessment and recommendations

## Development & Investigation

Non-canonical utilities for development and debugging are archived in `other/`:
- **`ind_proposals_fix.md`** — Technical proposals for addressing benchmark gaps
- **`inspect_edu_vars.R`** — Debugging script to inspect raw education variables and verify remapping logic
