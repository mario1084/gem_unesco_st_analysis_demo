# UNESCO Statistical Analysis Demo

R-first demo repository for a canonical UNESCO GEM-style reconstruction using the active sample countries `Argentina`, `Honduras`, and `Paraguay`.

## Objective

This repository stages a compact, auditable pipeline aligned to the consultant tasks of:

1. `01_data_acquisition`
2. `02_harmonization`
3. `03_combine_harmonized_data` (consolidation step)
4. `04_indicators`

The repo is designed to demonstrate reproducible handling of the canonical stack rather than a full production clone of `WIDE`, `VIEW`, or `SCOPE`.

## Canonical Stack

### Household annual reconstruction window
- `Argentina`: `EPH 2021-2024`
- `Honduras`: `EPHPM 2021-2024`
- `Paraguay`: `EPHC 2021-2024`

### Source-native integrated layers
- `ERCE 2019`
- `PISA 2022`
- `PISA-D 2016`
- `UIS learning API 2021-2024`
- `UIS admin 2021-2024`
- `WPP API 2021-2024`
- `OECD DAC/CRS 2021-2024`

## Pipeline

The data processing pipeline is designed to be a modular and reproducible workflow that transforms raw, source-native data into a harmonized, analysis-ready dataset. The pipeline is orchestrated by a series of R scripts that correspond to the three main stages of the workflow: data acquisition, harmonization, and indicator calculation.

### 1. `01_data_acquisition`

*   **Process:** This initial stage inventories all required data sources and verifies their existence. The `R/acquisition/build_source_registry.R` script reads from a series of manifest files that list the raw data files from your data stack. It then creates a centralized inventory of all data sources, called `config/source_registry.csv`, which contains the full paths to your raw data files, along with metadata about each source.
*   **Data:** The data at this stage is in its raw, source-native format (e.g., `.zip`, `.sav`, `.txt`, `.csv`). The data sources include household surveys from national statistics offices (for Argentina, Honduras, and Paraguay) and other educational data from sources like ERCE, PISA, and UIS, as listed in the "Canonical Stack" section.

### 2. `02_harmonization`

*   **Process:** This is the most complex stage of the pipeline, where the raw data from various sources is transformed into a consistent format. The `R/pipeline/02_harmonize.R` script reads the raw data from the paths specified in the source registry and applies a series of cleaning and transformation rules defined in a "crosswalk" file (`config/crosswalk.csv`). This process creates a set of harmonized, person-level datasets, saved as intermediate, compressed CSV files.
*   **Data:** The data is transformed from source-specific schemas into a common, harmonized schema. This involves standardizing variable names, recoding values, and creating new derived variables. The output of this stage is a set of clean, consistent datasets, one for each input source file. These are stored as intermediate files in the `data/interim/harmonized` directory.

### 3. `03_combine_harmonized_data` (Consolidation)

*   **Process:** After harmonization, the `R/pipeline/03_combine_harmonized_data.R` script consolidates all individual harmonized CSV.GZ files (one per source-year) into a single, efficient Parquet file (`persons_harmonized.parquet`) for streamlined processing by the indicator estimation stage.
*   **Data:** Input is the set of harmonized CSV.GZ files produced by `02_harmonize.R`. Output is a consolidated person-level analytical record ready for indicator calculation.

### 4. `04_indicators`

*   **Process:** The final stage applies statistical formulas to compute educational indicators across all families. The `R/pipeline/04_indicators.R` script orchestrates household core estimators (completion, attendance, out-of-school, literacy, repetition) alongside secondary layers (learning, admin/reference, finance), each applying indicator-level harmonization to translate national education codes into ISCED-comparable classifications. All outputs are consolidated into a single unified CSV with `indicator_family` labels. The `benchmark/ind_benchmark.py` script then filters to household core indicators for comparative validation against WIDE and UIS published benchmarks.
*   **Data:** Input is the consolidated `persons_harmonized.parquet` file. Output is `output/indicators/all_indicators_combined.csv` containing all indicator families with audit and benchmark comparisons.

## Repository Structure

- `config/`: source registry and implementation contracts
- `data/raw/`: canonical raw source destinations by layer
- `data/interim/`: harmonized outputs, crosswalks, QA artifacts
- `data/output/`: indicator, metadata, and publication-ready outputs
- `docs/`: methodological specifications and stack status
- `R/`: reusable functions and pipeline entrypoints
  - `pipeline/`: top-level data processing entrypoints (01_data_acquisition through 04_indicators)
  - `acquisition/`, `harmonization/`, `indicators/`: function libraries by stage
  - `utils/`, `qa/`: utility and quality assurance functions
- `benchmark/`: benchmark comparison scripts and data sources
- `output/reports/`: final publication-ready reports
- `archive/`: development artifacts (investigations, debug scripts, utilities)

## Method Specs

- `docs/gem_methodology.md`
- `docs/gem_method_harmonization.md`
- `docs/gem_method_indicator.md`


## Learning Layer Implementation Status

- `ERCE 2019` and `PISA 2022` are registered as canonical learning sources in `R/acquisition/build_source_registry.R`.
- More specifically, they are registered at `R/acquisition/build_source_registry.R:169` and `R/acquisition/build_source_registry.R:185`.
- However, the current implemented learning integration code reads only `data/raw/UIS_LEARNING_API/indicator_records_learning_sample.csv` in `R/indicators/learning/integration.R:19`.
- `R/indicators/learning/integration.R` explicitly marks `ERCE`, `PISA`, and `PISA-D` integration as placeholders rather than active runtime transformations.
- As a result, the current learning-family output is produced from the UIS learning API sample, while ERCE and PISA files are presently registry assets for completeness and future implementation.

Implementation of the full data flow should start from (in order):
```bash
Rscript R/pipeline/01_data_acquisition.R
Rscript R/pipeline/02_harmonize.R
Rscript R/pipeline/03_combine_harmonized_data.R
Rscript R/pipeline/04_indicators.R
python benchmark/ind_benchmark.py
```

## Data Scope

- **Countries:** Argentina (ARG), Honduras (HND), Paraguay (PRY)
- **Core Variables:** COMP_LVL, OOS_LVL, LIT_RATE (household completion, out-of-school, literacy)
- **Period:** 2021-2024 (overlap sample for cross-country comparison)
- **Methodology:** ISCED v17 harmonization with country-specific surgical patches

## Notes

- The active demo excludes archived `MICS` and `DHS` materials because they are not part of the demo reconstruction.
- Household estimates are reconstructed as annual indicator series over the `2021-2024` window.
- Learning, admin, population, and finance layers are integrated at their canonical source year and always preserve `source` and `source_year`.
