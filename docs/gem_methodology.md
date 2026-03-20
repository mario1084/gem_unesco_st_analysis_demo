# GEM Methodology

This document reconstructs the canonical working method for a GEM-style demo repo from four inputs: the job process map, the GitHub hard audit, the public WIDE/VIEW/SCOPE methodological surfaces, and the already built canonical source map.

## Canonical Resolution

- The demo repo should be organized around Outputs 1-6, not around ad hoc data downloads.
- WIDE contributes source-year discipline, disaggregation logic, and country-page presentation norms.
- VIEW contributes the staged workflow for compiled, modeled, and post-processed access/completion outputs.
- SCOPE contributes thematic integration across Access, Equity, Learning, Quality, and Finance.
- GEM contributes the publication standard: reproducible artifacts, short technical notes, and machine-readable handoff files.
- Raw HTML inspection of `VIEW` method pages from this environment returns an anti-bot or request-rejected shell; the methodological reconstruction therefore relies on the canonical link audit plus the already validated public method summaries and source-map evidence, not on brittle screen scraping.

## Hard Audit Findings

- The previous version was stale against the final demo stack: it omitted `EPHPM 2021-2024` for Honduras and did not expose the active reference layers already acquired.
- The previous version inherited outdated source statuses from an earlier `canonical_source_map.csv` snapshot and therefore understated the acquired learning layer.
- The corrected version distinguishes `WIDE` display labels from the local operational source files used in the demo repo.
- The corrected version treats Outputs 4-5 as multi-layer workflows: recent household survey + UIS admin + WPP + learning + finance, not just household survey tabulation.

## Current Demo Stack

- **Argentina**: local operational household source `EPH 2021-2024`; WIDE display label `EPH, 2023`; canonical learning sources `ERCE 2019, PISA 2022`.
- **Honduras**: local operational household source `EPHPM 2021-2024`; WIDE display label `EPH, 2023`; canonical learning sources `ERCE 2019, PISA-D 2016`.
- **Paraguay**: local operational household source `EPHC 2021-2024`; WIDE display label `EPH, 2023 / EPHC, 2019`; canonical learning sources `ERCE 2019, PISA 2022`.
- **Shared reference layers**: UIS admin 2021-2024, UIS learning API 2021-2024, WPP 2021-2024, OECD DAC/CRS 2021-2024, UIS Inventory of Household Surveys, UIS Inventory of Learning Assessments.

## Core Technical Method Specs

The two core data-driven activities in the demo are `02_harmonize` and `03_indicators`. They are specified below at deployment level rather than as high-level workflow descriptions.

### 02_harmonize

**Purpose**

Transform country-specific raw survey variables into a common analytical contract that can support WIDE-style disaggregation and VIEW/SCOPE-style indicator production without hiding source-specific deviations.

**Canonical source base**

- Household-survey harmonization rules are grounded in `uis_household_handbook_2025`, `uis_hhs_position_paper_2023`, `uis_household_indicator_calculation_2023`, `uis_total_net_attendance_rate_glossary`, and `uis_completion_rate_glossary`.
- WIDE contributes the public discipline of source-year provenance and visible source labeling: `wide_about`, `wide_argentina`, `wide_honduras`, `wide_paraguay`.
- VIEW contributes the requirement that survey inputs remain compatible with downstream completion/out-of-school estimation logic: `gem_view_out_school_methods`, `gem_view_completion`.

**Harmonized record contract**

Every harmonized person-level extract must expose, at minimum, the following fields:

- `country_code`
- `source_program`
- `source_wave`
- `survey_year`
- `unit_id`
- `person_id`
- `age`
- `sex`
- `residence`
- `sample_weight`
- `strata` if available
- `psu` if available
- `attending_currently_h`
- `level_current_h`
- `level_completed_h`
- `literacy_h` when available
- `repetition_h` when available
- `exception_flag`
- `exception_note`

The `_h` suffix denotes a harmonized field rather than the raw source variable.

**Formal harmonization method**

Stage 1: universe alignment
- Define the indicator universe before recoding any variable.
- For attendance indicators, the target universe is the population in the official school-age range required by the published UIS indicator definition.
- For completion indicators, the target universe is the reference age group specified by the indicator definition.

Stage 2: raw-to-harmonized variable crosswalk
- For each source, build a crosswalk table with columns:
  - `raw_variable`
  - `raw_label`
  - `harmonized_variable`
  - `mapping_rule`
  - `information_loss`
  - `comparability_class`
  - `exception_required`
- No raw variable may enter the harmonized layer without a row in this crosswalk.

Stage 3: schooling-structure alignment
- Translate source schooling levels into a common structure compatible with the UIS/ISCED-facing output.
- If the source contains country-specific level names, map them to the minimum common ladder needed for the target indicators.
- If the mapping requires collapsing categories, record the collapse explicitly in the crosswalk and in the exception log.

Stage 4: reference-period normalization
- Normalize current attendance, completion, and literacy variables only to the extent needed by the published indicator definition.
- Do not harmonize away substantive survey differences. If the source reference period differs materially from the indicator definition, keep the variable but classify it as non-comparable for that indicator.

Stage 5: exception logging
- Every transformation that changes numerator, denominator, subgroup meaning, or schooling-level interpretation must be recorded in an exception log.
- Minimum exception-log schema:
  - `country_code`
  - `source_wave`
  - `harmonized_variable`
  - `raw_variable`
  - `exception_type`
  - `rule_applied`
  - `effect_on_indicator`
  - `publishable_flag`

**Comparability classifier**

A raw variable is `directly harmonizable` if and only if all of the following hold:

1. the construct matches the published indicator construct;
2. the target population matches the published denominator universe;
3. the response coding can be mapped without collapsing meaning;
4. the reference period is consistent with the indicator definition.

A raw variable is `partially harmonizable` if:

1. the construct is the same, but
2. category collapse, age adjustment, or schooling-structure crosswalk is needed, and
3. the resulting loss is documentable without destroying cross-country meaning.

A raw variable is `non-comparable` if any of the following hold:

1. construct mismatch;
2. denominator universe mismatch;
3. reference period mismatch that changes meaning;
4. source wording or coding prevents a defensible common mapping.

**Operational output of 02_harmonize**

The deployable artifacts are:

- one source-level crosswalk table per country-wave;
- one harmonized person-level file per country-wave;
- one exception log per country-wave;
- one source comparability note;
- one machine-readable metadata row linking harmonized outputs back to source-year provenance.

**Canonical citations**

`uis_household_handbook_2025; uis_hhs_position_paper_2023; uis_household_indicator_calculation_2023; uis_total_net_attendance_rate_glossary; uis_completion_rate_glossary; wide_about; wide_argentina; wide_honduras; wide_paraguay; gem_view_out_school_methods; gem_view_completion`

### 03_indicators

**Purpose**

Construct publishable indicator estimates from the harmonized survey layer using official UIS/GEM definitions, explicit universes, and weighted estimators suitable for WIDE/VIEW/SCOPE-style publication.

**Canonical source base**

- Official indicator definitions and formulas: `uis_out_of_school_rate_glossary`, `uis_total_net_attendance_rate_glossary`, `uis_completion_rate_glossary`, `uis_literacy_rate_glossary`.
- Household-survey implementation guidance: `uis_household_indicator_calculation_2023`, `uis_household_handbook_2025`.
- Platform publication logic: `wide_about`, `scope_indicators`, `gem_view_out_school_methods`, `gem_view_completion`.

**Estimator framework**

Let `w_i` be the final survey weight for individual `i` and let `I(·)` be an indicator function.

For any binary education condition `C_i` defined over an eligible universe `U_i`, the canonical weighted share estimator is:


$$
\hat{p} = \frac{\sum_i w_i I(C_i = 1 \land U_i = 1)}{\sum_i w_i I(U_i = 1)}
$$


This is the operational estimator used to implement the published UIS share/rate definitions from household survey microdata.

**Indicator specifications**

1. Current attendance / net attendance implementation

Define:
- `U_i = 1` if individual `i` is in the official age range for the target level
- `A_i = 1` if individual `i` is currently attending the target level or any higher level, according to the published attendance rule

Estimator:


$$
\widehat{AttendanceRate} = \frac{\sum_i w_i I(A_i = 1 \land U_i = 1)}{\sum_i w_i I(U_i = 1)}
$$


2. Out-of-school rate

Using the glossary definition, the household-survey implementation is the weighted share of the official school-age population not attending the relevant level or higher.

Let `O_i = 1` if individual `i` is of official school age and is not attending the relevant level or a higher one.


$$
\widehat{OutOfSchoolRate} = \frac{\sum_i w_i I(O_i = 1)}{\sum_i w_i I(U_i = 1)}
$$


Equivalently, under the same universe and attendance coding:


$$
\widehat{OutOfSchoolRate} = 1 - \widehat{AttendanceRate}
$$


only when the attendance estimator is defined on the same official-age universe and level rule.

3. Completion rate

Let `R_i = 1` if individual `i` belongs to the published reference age group for the level, and `C_i = 1` if the individual has completed that level.


$$
\widehat{CompletionRate} = \frac{\sum_i w_i I(C_i = 1 \land R_i = 1)}{\sum_i w_i I(R_i = 1)}
$$


4. Literacy rate

Let `L_i = 1` if the person is classified as literate under the source's literacy item and the source is admissible for literacy publication.


$$
\widehat{LiteracyRate} = \frac{\sum_i w_i I(L_i = 1 \land U_i = 1)}{\sum_i w_i I(U_i = 1)}
$$


where `U_i` is the age universe specified by the literacy indicator definition.

**Disaggregated indicator construction**

For any subgroup `g`, the subgroup estimator is not a different formula; it is the same weighted share computed on the subgroup universe:


$$
\hat{p}_g = \frac{\sum_i w_i I(C_i = 1 \land U_i = 1 \land G_i = g)}{\sum_i w_i I(U_i = 1 \land G_i = g)}
$$


This must only be published when the subgroup passes the methodological review described in `P14`.

**Minimum QA conditions before publication**

An indicator estimate may enter the publication layer only if:

1. the indicator universe is documented and reproducible from the harmonized fields;
2. the estimator uses the final survey weights;
3. the indicator is traceable to a source-year label;
4. any country-wave workaround is present in the exception log;
5. the estimate passes cross-wave and cross-source plausibility checks against the reference layer.

**Operational output of 03_indicators**

The deployable artifacts are:

- one country-year indicator table;
- one disaggregated indicator table;
- one metadata table documenting numerator, denominator, source-year, and caveats;
- one QA table with pass/fail flags;
- one platform-ready export layer for WIDE/VIEW/SCOPE-style publication.

**Canonical citations**

`uis_out_of_school_rate_glossary; uis_total_net_attendance_rate_glossary; uis_completion_rate_glossary; uis_literacy_rate_glossary; uis_household_indicator_calculation_2023; uis_household_handbook_2025; wide_about; scope_indicators; gem_view_out_school_methods; gem_view_completion`


## Platform Methods

### WIDE

WIDE operationally combines household surveys, learning assessments, and explicit source-year labeling on country pages. The canonical workflow is: select the operative country source, calculate disaggregated indicators, attach visible source/year provenance, and present results through country cards, charts, maps, tables, and downloadable outputs.

Evidence:
- WIDE About describes the database as combining household surveys and learning assessments.
- WIDE country pages visibly attach indicator values to source labels such as EPH, ERCE, PISA, PISA-D, MICS or DHS with year tags.

### VIEW

VIEW methods combine administrative enrolment data from UIS, population references such as WPP, and household survey or census evidence. The workflow is explicitly staged as data compilation, pre-processing, estimation/modeling, and post-processing/validation. For the demo repo this implies separate scripts for source compilation, denominator alignment, model-ready reshaping, and final plausibility checks before publication.

Evidence:
- Public GEM VIEW out-of-school methods page/snippet identifies data compilation, pre-processing, the model, and post-processing as explicit stages.
- Public method snippet references household surveys, censuses, UIS administrative data, WPP, Eurostat, and SingStat as source families.

### VIEW Completion

VIEW completion is not a raw-tabulation page; it is a modeled completion pipeline using survey/census evidence and demographic alignment. For the demo repo this means completion outputs must be clearly separated from raw attendance tabulations, with explicit notes on source-year, cohort assumptions, and post-estimation validation.

Evidence:
- Public GEM completion method surface frames completion as an estimation workflow tied to survey/census information rather than a single-source extract.

### SCOPE

SCOPE integrates multiple evidence layers into five public themes: Access, Equity, Learning, Quality, and Finance. The canonical workflow is therefore not one monolithic script but a modular pipeline: household survey indicators for access/equity, administrative UIS series for system measures, learning datasets for achievement, and finance datasets for expenditure and aid.

Evidence:
- SCOPE About explicitly references administrative data, household surveys, learning assessments and education finance.
- SCOPE Indicators page exposes theme-based indicator navigation rather than source-specific pages, which implies a harmonized publication layer above the raw datasets.

## Job Process Map (1:1)

Each operational process from `job.txt` is mapped below to its canonical method, linked output, and publication implication.

- **P01 [Support the compilation of data sources for SDG 4 monitoring, with a particular focus on national sources.]**: Identify, assess and document household survey microdata sources relevant to education, including labour force surveys, income and expenditure surveys, multipurpose household surveys and other nationally representative instruments.
  - Linked output: 1
  - Canonical method: source discovery and source admissibility audit
  - Method detail: Enumerate candidate household surveys, verify national representativeness and education relevance, and admit a source only when it supports a defensible indicator construction path for the target country, year, and platform use case.
  - Formal method: Canonical source-admissibility audit driven by UIS household-survey standards and WIDE source discipline: the source must be nationally representative for the target population, expose the education variable needed for the indicator, document the survey year and reference period, preserve the age/population fields required for SDG 4 definitions, and retain enough metadata/codebook context to map the source-year visibly on the platform.
  - Formula: none published for this process; the canonical method is procedural rather than equation-driven.
  - Method type: procedural
  - Canonical citations: `wide_about; uis_edsc_household_surveys; uis_household_handbook_2025; uis_hhs_position_paper_2023; uis_education_literacy_methodology`
  - Criteria: Admit the source only if all five checks pass: (1) nationally representative target population; (2) indicator-relevant education items exist; (3) fieldwork/reference year is identifiable; (4) age, grade, and school-structure variables allow mapping to the published SDG 4 indicator definition; (5) documentation is sufficient to cite the source-year and caveats on the public page. Defer when one of 3-5 is weak but repairable; exclude when 1-2 fail.
  - Technical note: No public UIS document publishes a single admissibility score. The operational admissibility rule here is explicitly derived from UIS household-survey guidance on nationally representative coverage, indicator-variable availability, documented reference periods, and comparability constraints, plus WIDE's visible source-year provenance discipline on country pages.
  - Platform anchor: WIDE + VIEW + SCOPE source discovery
  - Source scope: EPH 2021-2024, EPHC 2021-2024, EPHPM 2021-2024, ILOSTAT catalogue, UIS household-survey inventory
  - Repo presentation implication: inventory tables first, not charts
- **P02 [Support the compilation of data sources for SDG 4 monitoring, with a particular focus on national sources.]**: Support the maintenance and expansion of an inventory of education-relevant survey data, in collaboration with the UNESCO Institute for Statistics, ensuring up-to-date coverage across countries and over time.
  - Linked output: 1
  - Canonical method: inventory maintenance and expansion
  - Method detail: Maintain a canonical inventory table keyed by country, survey program, source-year, unit of analysis, module coverage, and access status, updating it incrementally as new sources are verified with UIS and national-source evidence.
  - Formal method: Longitudinal source-inventory maintenance with stable keys and update rules: one row per country-source-year-unit combination, append-only updates, explicit supersession notes, and no silent overwrites of historical provenance.
  - Formula: none published for this process; the canonical method is procedural rather than equation-driven.
  - Method type: procedural
  - Canonical citations: `wide_about; uis_edsc_household_surveys; uis_household_handbook_2025; uis_hhs_position_paper_2023`
  - Criteria: Stable key = country + survey_program + survey_id/source_label + fieldwork_year + unit_of_analysis. Update rules: append a new row for each new wave; never replace a historical row; if a source is superseded, mark it with `supersedes` and `active_flag`; track module coverage, access status, and canonical use case in separate columns rather than free text.
  - Technical note: UIS publishes inventory-oriented governance principles, but not a canonical database schema. The stable-key rule here is an explicit operationalization needed to preserve WIDE-style source-year discipline and reproducible source selection over time.
  - Platform anchor: WIDE + VIEW + SCOPE source discovery
  - Source scope: EPH 2021-2024, EPHC 2021-2024, EPHPM 2021-2024, ILOSTAT catalogue, UIS household-survey inventory
  - Repo presentation implication: inventory tables first, not charts
- **P03 [Support the compilation of data sources for SDG 4 monitoring, with a particular focus on national sources.]**: Produce concise methodological notes describing survey design, education variables, coverage, comparability and limitations, to inform analytical use within GEM products.
  - Linked output: 2
  - Canonical method: methodological note writing
  - Method detail: Write short source notes that document survey design, education-variable coverage, population scope, comparability limits, and analytical suitability for downstream GEM products.
  - Formal method: Structured source-note template: design, variables, coverage, comparability, limitations, and admissibility.
  - Formula: none published for this process; the canonical method is procedural rather than equation-driven.
  - Method type: procedural
  - Canonical citations: `uis_education_literacy_methodology`
  - Technical note: UIS documents the review, clarification, estimation, and QA cycle; the note-writing format is methodological but not formulaic.
  - Platform anchor: WIDE source-year discipline + VIEW/SCOPE metadata discipline
  - Source scope: EPH 2021-2024, EPHC 2021-2024, EPHPM 2021-2024, ILOSTAT methodological notes, UIS inventory extracts
  - Repo presentation implication: method cards and metadata tables
- **P04 [Support the compilation of data sources for SDG 4 monitoring, with a particular focus on national sources.]**: Identify and review household survey modules capturing additional constructs related to SDG 4.
  - Linked output: 3
  - Canonical method: module review
  - Method detail: Inspect questionnaires and codebooks module by module, identify candidate SDG 4 constructs, and classify each construct only after testing definition, universe, response scale, reference period, and education-level mapping against published UIS/learning-assessment standards.
  - Formal method: Questionnaire-and-codebook module review against standardized survey items, published indicator definitions, and learning/household-survey working-group norms, with an explicit three-way comparability rule.
  - Formula: none published for this process; the canonical method is procedural rather than equation-driven.
  - Method type: procedural
  - Canonical citations: `uis_edsc_household_surveys; uis_edsc_gaml; uis_household_handbook_2025; uis_hhs_position_paper_2023`
  - Criteria: Directly harmonizable = same construct, same target population, same reference period, and a lossless map to the published indicator categories/ISCED levels. Partially harmonizable = same construct but requires documented aggregation, age adjustment, school-structure crosswalk, or category collapse. Non-comparable = construct definition, universe, wording, or measurement scale cannot be aligned without changing substantive meaning.
  - Technical note: UIS does not publish an official named three-class harmonization classifier. The classifier below is an explicit operationalization derived from the comparability problems UIS documents for household surveys and learning assessments.
  - Platform anchor: WIDE learning source overlay + UIS learning API
  - Source scope: EPH 2021-2024, EPHC 2021-2024, EPHPM 2021-2024, ERCE 2019, PISA 2022, PISA-D 2016, UIS learning API, questionnaires/codebooks
  - Repo presentation implication: construct feasibility matrices and source badges
- **P05 [Strengthen data harmonization, reproducibility and quality assurance workflows.]**: Update the current CSV control file template that outlines all necessary parameters for generating the factsheet per country
  - Linked output: 4
  - Canonical method: control file architecture
  - Method detail: Define one canonical CSV control template per country-source pair so every pipeline run has explicit parameters for inputs, recodes, indicator logic, disaggregations, and export paths.
  - Formal method: Parameterization of country-source workflows through explicit control metadata.
  - Formula: none published for this process; the canonical method is procedural rather than equation-driven.
  - Method type: procedural
  - Canonical citations: `gem_view_out_school_methods; scope_indicators`
  - Technical note: The public canonical surfaces show staged pipelines and publication layers, but they do not publish a formula for control-file design.
  - Platform anchor: VIEW modeling discipline + WIDE/SCOPE harmonization discipline
  - Source scope: EPH 2021-2024, EPHC 2021-2024, EPHPM 2021-2024, UIS admin 2021-2024, WPP 2021-2024, country control files
  - Repo presentation implication: control-file-driven reproducibility and QA tables
- **P06 [Strengthen data harmonization, reproducibility and quality assurance workflows.]**: Support the harmonization of education variables across household survey sources, including documentation of assumptions, recoding rules and country-specific deviations.
  - Linked output: 4
  - Canonical method: harmonization and exception logging
  - Method detail: Map source-specific education variables into a common contract, documenting assumptions, recoding rules, age/reference-period adjustments, and country-specific deviations in separate exception logs rather than embedding them implicitly in scripts.
  - Formal method: ISCED-aligned recoding with reference-year and age adjustments plus explicit country exception logging: align the source universe to the indicator universe, translate levels to the common school structure, normalize response categories, and log every country-wave deviation that changes denominator, numerator, or subgroup definition.
  - Formula: none published for this process; the canonical method is procedural rather than equation-driven.
  - Method type: procedural
  - Canonical citations: `uis_total_net_attendance_rate_glossary; uis_completion_rate_glossary; uis_education_literacy_methodology; uis_edsc_household_surveys; uis_household_indicator_calculation_2023; uis_household_handbook_2025`
  - Criteria: Required harmonization checks: (1) universe alignment to the published indicator denominator; (2) age adjustment using survey age, interview date, and school-age rules where required; (3) school-level translation to the common structure/ISCED view; (4) explicit recode map for attendance/completion/literacy variables; (5) exception log whenever a source-specific workaround changes interpretation or comparability.
  - Technical note: Official technical detail exists on age adjustment, school structure, and ISCED alignment, but the harmonization workflow is a sequence of controlled transformations rather than a single equation.
  - Platform anchor: VIEW modeling discipline + WIDE/SCOPE harmonization discipline
  - Source scope: EPH 2021-2024, EPHC 2021-2024, EPHPM 2021-2024, UIS admin 2021-2024, WPP 2021-2024, country control files
  - Repo presentation implication: control-file-driven reproducibility and QA tables
- **P07 [Strengthen data harmonization, reproducibility and quality assurance workflows.]**: Create a template per country R script that reads the CSV control file and generation indicator estimates for different disaggregations (out-of-school rate, attendance rate, completion rate, literacy rate, repetition rate etc.)
  - Linked output: 4
  - Canonical method: country template script generation
  - Method detail: Build a reproducible country script template that reads the control file, applies harmonization rules, computes survey-weighted indicators, and emits flat outputs and QA summaries with stable filenames.
  - Formal method: Parameterized country-runner implementing published indicator definitions via control-file inputs.
  - Formula: For indicator ratios implemented from household surveys, use the published indicator forms, e.g. completion rate = completed population in the reference age group / total population in the same reference age group, and out-of-school rate = [population of official school age - enrolled population of the same age] / population of official school age.
  - Method type: mixed
  - Canonical citations: `uis_out_of_school_rate_glossary; uis_completion_rate_glossary; uis_total_net_attendance_rate_glossary; uis_household_indicator_calculation_2023`
  - Technical note: The script template is procedural, but it should implement official UIS formulas and age-adjustment rules rather than ad hoc calculations.
  - Platform anchor: VIEW modeling discipline + WIDE/SCOPE harmonization discipline
  - Source scope: EPH 2021-2024, EPHC 2021-2024, EPHPM 2021-2024, UIS admin 2021-2024, WPP 2021-2024, country control files
  - Repo presentation implication: control-file-driven reproducibility and QA tables
- **P08 [Strengthen data harmonization, reproducibility and quality assurance workflows.]**: Conduct routine quality assurance checks of estimates, including internal consistency over time, coherence across indicators, and plausibility relative to comparable countries or external information.
  - Linked output: 4
  - Canonical method: quality assurance and plausibility review
  - Method detail: Run internal consistency checks over time, cross-indicator coherence checks, and external plausibility checks against comparable countries and reference layers before any estimate is promoted to the publication layer.
  - Formal method: Multi-stage QA: submission checks, time-series consistency, cross-indicator coherence, plausibility against reference layers, and sampling-error diagnostics where applicable.
  - Formula: none published for this process; the canonical method is procedural rather than equation-driven.
  - Method type: mixed
  - Canonical citations: `gem_view_out_school_methods; uis_education_literacy_methodology`
  - Technical note: VIEW explicitly references clustered jackknife sampling variances for survey data; UIS also documents review, clarification, and estimation workflows. The public surfaces do not expose a single full QA equation.
  - Platform anchor: VIEW modeling discipline + WIDE/SCOPE harmonization discipline
  - Source scope: EPH 2021-2024, EPHC 2021-2024, EPHPM 2021-2024, UIS admin 2021-2024, WPP 2021-2024, country control files
  - Repo presentation implication: control-file-driven reproducibility and QA tables
- **P09 [Strengthen data harmonization, reproducibility and quality assurance workflows.]**: Translate, consolidate or refactor legacy Stata scripts into clearer, reproducible R and/or Stata workflows, as agreed with the GEM Report monitoring team.
  - Linked output: 4
  - Canonical method: legacy code refactoring
  - Method detail: Refactor legacy Stata logic into clearer, annotated R or Stata modules with equivalent survey design treatment, stable naming conventions, and explicit version control.
  - Formal method: Reproducibility-preserving code refactor that keeps indicator definitions and survey design handling invariant while improving clarity and modularity.
  - Formula: none published for this process; the canonical method is procedural rather than equation-driven.
  - Method type: procedural
  - Canonical citations: `gem_view_out_school_methods; uis_edsc_household_surveys`
  - Technical note: This is a software-engineering process constrained by official indicator definitions, not a standalone statistical formula.
  - Platform anchor: VIEW modeling discipline + WIDE/SCOPE harmonization discipline
  - Source scope: EPH 2021-2024, EPHC 2021-2024, EPHPM 2021-2024, UIS admin 2021-2024, WPP 2021-2024, country control files
  - Repo presentation implication: control-file-driven reproducibility and QA tables
- **P10 [Strengthen data harmonization, reproducibility and quality assurance workflows.]**: For around 30 countries, translate the codes written in Stata that harmonize the educational indicators into R and embed them in the new GitHub workflow on harmonization and standardization of educational microdata.
  - Linked output: 4
  - Canonical method: stata-to-r migration
  - Method detail: Translate country harmonization code from Stata into R while preserving indicator definitions, sample restrictions, weight handling, and country-specific recodes, then embed the result in the shared GitHub workflow.
  - Formal method: Language migration with semantic equivalence checks against the published indicator definitions and control-file contract.
  - Formula: none published for this process; the canonical method is procedural rather than equation-driven.
  - Method type: procedural
  - Canonical citations: `uis_out_of_school_rate_glossary; uis_completion_rate_glossary; uis_total_net_attendance_rate_glossary; gem_view_out_school_methods`
  - Technical note: The formal constraint is equivalence to the published indicator formulas; the migration itself is procedural.
  - Platform anchor: VIEW modeling discipline + WIDE/SCOPE harmonization discipline
  - Source scope: EPH 2021-2024, EPHC 2021-2024, EPHPM 2021-2024, UIS admin 2021-2024, WPP 2021-2024, country control files
  - Repo presentation implication: control-file-driven reproducibility and QA tables
- **P11 [Strengthen data harmonization, reproducibility and quality assurance workflows.]**: Ensure that all analytical code is clearly annotated and published on a GitHub, version-controlled and documented to facilitate reuse, transparency and institutional memory.
  - Linked output: 4
  - Canonical method: repository annotation and institutional memory
  - Method detail: Publish code with inline annotations, README-level execution instructions, version-controlled configs, and reproducibility notes so the repository serves as institutional memory rather than a private working directory.
  - Formal method: Repository-level reproducibility and documentation standard for analytical workflows.
  - Formula: none published for this process; the canonical method is procedural rather than equation-driven.
  - Method type: procedural
  - Canonical citations: `wide_about; scope_about; uis_education_literacy_methodology`
  - Technical note: The method is publication-governance and reproducibility discipline, not a quantitative estimator.
  - Platform anchor: VIEW modeling discipline + WIDE/SCOPE harmonization discipline
  - Source scope: EPH 2021-2024, EPHC 2021-2024, EPHPM 2021-2024, UIS admin 2021-2024, WPP 2021-2024, country control files
  - Repo presentation implication: control-file-driven reproducibility and QA tables
- **P12 [Support the analysis and reporting of microdata sets to update the WIDE, VIEW and SCOPE websites, in coordination with the GEM Report monitoring team.]**: Contribute to the processing of household survey microdata sets to generate estimates of education indicators.
  - Linked output: 5
  - Canonical method: indicator estimation workflow
  - Method detail: Process harmonized household microdata into validated indicator estimates using survey-weighted routines, explicit disaggregation logic, and source-year provenance suitable for WIDE, VIEW, and SCOPE publication.
  - Formal method: Published household-survey indicator estimation using official denominator/numerator definitions and level-specific age structures.
  - Formula: Examples of official UIS forms: completion rate = completed population in the reference age group / total population in the same reference age group; out-of-school rate = [population of official school age - enrolled population of the same age] / population of official school age; literacy rate = literate population in the age group / total population in the same age group.
  - Method type: mathematical
  - Canonical citations: `uis_out_of_school_rate_glossary; uis_completion_rate_glossary; uis_literacy_rate_glossary; uis_household_indicator_calculation_2023; wide_about`
  - Technical note: This is the core quantitative process and should be implemented directly from official UIS glossary formulas and the 2023 household-survey calculation report.
  - Platform anchor: WIDE/VIEW/SCOPE publication layer
  - Source scope: EPH 2021-2024, EPHC 2021-2024, EPHPM 2021-2024, ERCE 2019, PISA 2022, PISA-D 2016, UIS admin 2021-2024, UIS learning API 2021-2024, WPP 2021-2024, OECD DAC/CRS 2021-2024, UIS Inventory of Household Surveys, UIS Inventory of Learning Assessments
  - Repo presentation implication: country pages, trend charts, indicator cards, downloadable flat files
- **P13 [Support the analysis and reporting of microdata sets to update the WIDE, VIEW and SCOPE websites, in coordination with the GEM Report monitoring team.]**: Contribute to the maintenance and improvement of the GitHub repository by supporting code review, documentation enhancement, and reproducibility checks, in line with established GEM workflows and standards.
  - Linked output: 5
  - Canonical method: repository code review and reproducibility enforcement
  - Method detail: Review code, metadata, and output artifacts together, enforcing reproducibility checks, documentation completeness, and consistent repository structure before merging platform-facing changes.
  - Formal method: Repository-level review combining code, metadata, and output validation prior to publication.
  - Formula: none published for this process; the canonical method is procedural rather than equation-driven.
  - Method type: procedural
  - Canonical citations: `scope_about; wide_about; gem_view_out_school_methods`
  - Technical note: This process is methodological governance of the analytical workflow, not a published equation.
  - Platform anchor: WIDE/VIEW/SCOPE publication layer
  - Source scope: EPH 2021-2024, EPHC 2021-2024, EPHPM 2021-2024, ERCE 2019, PISA 2022, PISA-D 2016, UIS admin 2021-2024, UIS learning API 2021-2024, WPP 2021-2024, OECD DAC/CRS 2021-2024, UIS Inventory of Household Surveys, UIS Inventory of Learning Assessments
  - Repo presentation implication: country pages, trend charts, indicator cards, downloadable flat files
- **P14 [Support the analysis and reporting of microdata sets to update the WIDE, VIEW and SCOPE websites, in coordination with the GEM Report monitoring team.]**: Provide analytical and methodological review of disaggregated data by individual characteristics (such as location or ethnicity), identifying potential data quality, comparability or interpretation issues.
  - Linked output: 5
  - Canonical method: disaggregated-data methodological review
  - Method detail: Review subgroup estimates by location, ethnicity, sex, wealth, or other individual characteristics, testing subgroup-definition stability, weighted sample adequacy, disclosure risk, and interpretation limits before publication.
  - Formal method: Subgroup-specific application of the published indicator formula, followed by a methodological review of subgroup comparability, sparse-cell risk, and interpretability before release.
  - Formula: none published for this process; the canonical method is procedural rather than equation-driven.
  - Method type: mixed
  - Canonical citations: `wide_about; uis_education_literacy_methodology; uis_household_indicator_calculation_2023; uis_household_handbook_2025`
  - Criteria: Release subgroup estimates only when the subgroup variable is consistently defined across source-years, the subgroup universe matches the indicator universe, weighted support is adequate for stable interpretation, and the resulting estimate does not rely on a country-specific workaround that destroys cross-country meaning. Otherwise flag as caveated or suppress from the public layer.
  - Technical note: The subgroup review applies the published indicator definition after stratification. The review itself is procedural: the public canonical sources do not publish a separate subgroup-only estimator beyond the base indicator formula.
  - Platform anchor: WIDE/VIEW/SCOPE publication layer
  - Source scope: EPH 2021-2024, EPHC 2021-2024, EPHPM 2021-2024, ERCE 2019, PISA 2022, PISA-D 2016, UIS admin 2021-2024, UIS learning API 2021-2024, WPP 2021-2024, OECD DAC/CRS 2021-2024, UIS Inventory of Household Surveys, UIS Inventory of Learning Assessments
  - Repo presentation implication: country pages, trend charts, indicator cards, downloadable flat files
- **P15 [Support the analysis and reporting of microdata sets to update the WIDE, VIEW and SCOPE websites, in coordination with the GEM Report monitoring team.]**: Provide analytical input to the review of indicators related to post-secondary education, including assessment of data sources, coverage and consistency across countries.
  - Linked output: 5
  - Canonical method: post-secondary indicator review
  - Method detail: Assess post-secondary indicators by checking source availability, population coverage, definitional consistency, and cross-country comparability before deciding whether they enter the publication stack.
  - Formal method: Source-coverage and definitional-consistency review for tertiary/post-secondary indicators.
  - Formula: none published for this process; the canonical method is procedural rather than equation-driven.
  - Method type: procedural
  - Canonical citations: `uis_education_literacy_methodology; scope_indicators`
  - Technical note: This is a methodological review process. The relevant quantitative formulas depend on the specific post-secondary indicator selected after source-coverage review.
  - Platform anchor: WIDE/VIEW/SCOPE publication layer
  - Source scope: EPH 2021-2024, EPHC 2021-2024, EPHPM 2021-2024, ERCE 2019, PISA 2022, PISA-D 2016, UIS admin 2021-2024, UIS learning API 2021-2024, WPP 2021-2024, OECD DAC/CRS 2021-2024, UIS Inventory of Household Surveys, UIS Inventory of Learning Assessments
  - Repo presentation implication: country pages, trend charts, indicator cards, downloadable flat files
- **P16 [Support the analysis and reporting of microdata sets to update the WIDE, VIEW and SCOPE websites, in coordination with the GEM Report monitoring team.]**: Contribute to the enhancement of WIDE, VIEW and SCOPE documentation, technical notes and user-facing explanations.
  - Linked output: 5
  - Canonical method: metadata and user-facing explanation enhancement
  - Method detail: Attach short technical notes, metadata rows, and user-facing explanations directly to each platform artifact so definitions, caveats, and source-year provenance are visible where users consume the indicator.
  - Formal method: Platform-facing metadata publication standard aligned with WIDE, VIEW, and SCOPE presentation patterns.
  - Formula: none published for this process; the canonical method is procedural rather than equation-driven.
  - Method type: procedural
  - Canonical citations: `wide_about; gem_view_out_school_methods; scope_about`
  - Technical note: This process concerns technical-note architecture and presentation discipline rather than statistical estimation.
  - Platform anchor: WIDE/VIEW/SCOPE publication layer
  - Source scope: EPH 2021-2024, EPHC 2021-2024, EPHPM 2021-2024, ERCE 2019, PISA 2022, PISA-D 2016, UIS admin 2021-2024, UIS learning API 2021-2024, WPP 2021-2024, OECD DAC/CRS 2021-2024, UIS Inventory of Household Surveys, UIS Inventory of Learning Assessments
  - Repo presentation implication: country pages, trend charts, indicator cards, downloadable flat files
- **P17 [Contribute to GEM Report team outputs upon request.]**: Provide technical support to the production of statistical analyses (e.g. tables and figures) that support GEM Report publications.
  - Linked output: 5
  - Canonical method: tables and figures production support
  - Method detail: Produce reproducible tables and figures from validated outputs using script-driven chart specifications and publication-ready flat files, not manual spreadsheet editing.
  - Formal method: Scripted production of publication artifacts from validated flat files and metadata layers.
  - Formula: none published for this process; the canonical method is procedural rather than equation-driven.
  - Method type: procedural
  - Canonical citations: `wide_about; gem_aid_tables_2024; scope_indicators`
  - Technical note: The method is reproducible rendering and tabulation from validated outputs, not a new estimator.
  - Platform anchor: WIDE/VIEW/SCOPE publication layer
  - Source scope: EPH 2021-2024, EPHC 2021-2024, EPHPM 2021-2024, ERCE 2019, PISA 2022, PISA-D 2016, UIS admin 2021-2024, UIS learning API 2021-2024, WPP 2021-2024, OECD DAC/CRS 2021-2024, UIS Inventory of Household Surveys, UIS Inventory of Learning Assessments
  - Repo presentation implication: country pages, trend charts, indicator cards, downloadable flat files

## Output-by-Output Canonical Reconstruction

### Output 1

**Job activity:** Map education-relevant survey microdata (DHS, MICS, LFS) and create a standardized inventory structure.

- **source discovery**: Enumerate nationally representative survey families first, then tag each by indicator relevance, years, and access path.
  - Platform anchor: WIDE + VIEW + SCOPE source discovery
  - Source scope: EPH 2021-2024, EPHC 2021-2024, EPHPM 2021-2024, ILOSTAT catalogue, UIS household-survey inventory
  - Implementation precedent: UNICEF MICS processing and World Bank LSMS-style inventory design as implementation precedent for source inventory tables.
  - Repo presentation implication: inventory tables first, not charts
- **inventory standardization**: Build a canonical inventory schema with country, source, year, unit of analysis, education modules, access status, and notes on comparability.
  - Platform anchor: WIDE + VIEW + SCOPE source discovery
  - Source scope: EPH 2021-2024, EPHC 2021-2024, EPHPM 2021-2024, ILOSTAT catalogue, UIS household-survey inventory
  - Implementation precedent: UNICEF MICS processing and World Bank LSMS-style inventory design as implementation precedent for source inventory tables.
  - Repo presentation implication: inventory tables first, not charts
- **prioritization**: Rank sources by canonical relevance to WIDE/VIEW/SCOPE, not by availability alone.
  - Platform anchor: WIDE + VIEW + SCOPE source discovery
  - Source scope: EPH 2021-2024, EPHC 2021-2024, EPHPM 2021-2024, ILOSTAT catalogue, UIS household-survey inventory
  - Implementation precedent: UNICEF MICS processing and World Bank LSMS-style inventory design as implementation precedent for source inventory tables.
  - Repo presentation implication: inventory tables first, not charts

### Output 2

**Job activity:** Expand inventory of household survey microdata sources; create short methodological notes on survey design, variables, coverage, comparability, and limitations.

- **methodological note writing**: For every source, document survey design, target population, education variables, known breaks, and why the source is or is not analytically admissible.
  - Platform anchor: WIDE source-year discipline + VIEW/SCOPE metadata discipline
  - Source scope: EPH 2021-2024, EPHC 2021-2024, EPHPM 2021-2024, ILOSTAT methodological notes, UIS inventory extracts
  - Implementation precedent: World Bank Learning Poverty and DHS indicator documentation as precedent for short methodological notes and comparability memos.
  - Repo presentation implication: method cards and metadata tables
- **comparability audit**: Map cross-country and cross-wave comparability explicitly: age ranges, schooling definitions, missing modules, and source-year gaps.
  - Platform anchor: WIDE source-year discipline + VIEW/SCOPE metadata discipline
  - Source scope: EPH 2021-2024, EPHC 2021-2024, EPHPM 2021-2024, ILOSTAT methodological notes, UIS inventory extracts
  - Implementation precedent: World Bank Learning Poverty and DHS indicator documentation as precedent for short methodological notes and comparability memos.
  - Repo presentation implication: method cards and metadata tables
- **technical recommendation**: Conclude each note with a keep/defer/archive recommendation tied to the platform use case.
  - Platform anchor: WIDE source-year discipline + VIEW/SCOPE metadata discipline
  - Source scope: EPH 2021-2024, EPHC 2021-2024, EPHPM 2021-2024, ILOSTAT methodological notes, UIS inventory extracts
  - Implementation precedent: World Bank Learning Poverty and DHS indicator documentation as precedent for short methodological notes and comparability memos.
  - Repo presentation implication: method cards and metadata tables

### Output 3

**Job activity:** Technical review of survey modules capturing SDG 4-related education constructs (including SDG 4.7); assess conceptual relevance, question wording, population coverage, cross-country comparability.

- **module review**: Inspect questionnaires and codebooks for additional SDG 4 constructs and classify whether wording is directly harmonizable, partially harmonizable, or not comparable.
  - Platform anchor: WIDE learning source overlay + UIS learning API
  - Source scope: EPH 2021-2024, EPHC 2021-2024, EPHPM 2021-2024, ERCE 2019, PISA 2022, PISA-D 2016, UIS learning API, questionnaires/codebooks
  - Implementation precedent: Learning Poverty, MICS documentation, and DHS module-review logic as precedent for question-level feasibility reviews.
  - Repo presentation implication: construct feasibility matrices and source badges
- **triangulation**: Triangulate construct feasibility across survey instruments, platform needs, and public indicator definitions before adding a variable into the demo scope.
  - Platform anchor: WIDE learning source overlay + UIS learning API
  - Source scope: EPH 2021-2024, EPHC 2021-2024, EPHPM 2021-2024, ERCE 2019, PISA 2022, PISA-D 2016, UIS learning API, questionnaires/codebooks
  - Implementation precedent: Learning Poverty, MICS documentation, and DHS module-review logic as precedent for question-level feasibility reviews.
  - Repo presentation implication: construct feasibility matrices and source badges
- **feasibility note**: Document which constructs can be integrated into current outputs versus future extensions.
  - Platform anchor: WIDE learning source overlay + UIS learning API
  - Source scope: EPH 2021-2024, EPHC 2021-2024, EPHPM 2021-2024, ERCE 2019, PISA 2022, PISA-D 2016, UIS learning API, questionnaires/codebooks
  - Implementation precedent: Learning Poverty, MICS documentation, and DHS module-review logic as precedent for question-level feasibility reviews.
  - Repo presentation implication: construct feasibility matrices and source badges

### Output 4

**Job activity:** Translate legacy Stata code for indicator harmonization into R; embed clean, version-controlled scripts for ~30 countries; maintain quality assurance documentation.

- **harmonization**: Create source-specific recode maps into a common variable contract, then version country exceptions explicitly instead of burying them in code.
  - Platform anchor: VIEW modeling discipline + WIDE/SCOPE harmonization discipline
  - Source scope: EPH 2021-2024, EPHC 2021-2024, EPHPM 2021-2024, UIS admin 2021-2024, WPP 2021-2024, country control files
  - Implementation precedent: stata2r + survey/srvyr + DHS Indicators R as implementation precedent for harmonization, weighting, and Stata-to-R translation.
  - Repo presentation implication: control-file-driven reproducibility and QA tables
- **control file architecture**: Use one config/control file per country-source combination so the pipeline can generate the same outputs reproducibly.
  - Platform anchor: VIEW modeling discipline + WIDE/SCOPE harmonization discipline
  - Source scope: EPH 2021-2024, EPHC 2021-2024, EPHPM 2021-2024, UIS admin 2021-2024, WPP 2021-2024, country control files
  - Implementation precedent: stata2r + survey/srvyr + DHS Indicators R as implementation precedent for harmonization, weighting, and Stata-to-R translation.
  - Repo presentation implication: control-file-driven reproducibility and QA tables
- **Stata-to-R translation**: Translate legacy logic into tidy, testable R scripts while preserving survey design handling and value-label semantics.
  - Platform anchor: VIEW modeling discipline + WIDE/SCOPE harmonization discipline
  - Source scope: EPH 2021-2024, EPHC 2021-2024, EPHPM 2021-2024, UIS admin 2021-2024, WPP 2021-2024, country control files
  - Implementation precedent: stata2r + survey/srvyr + DHS Indicators R as implementation precedent for harmonization, weighting, and Stata-to-R translation.
  - Repo presentation implication: control-file-driven reproducibility and QA tables
- **QA**: Run internal consistency, cross-indicator coherence, and plausibility checks against reference layers before publication.
  - Platform anchor: VIEW modeling discipline + WIDE/SCOPE harmonization discipline
  - Source scope: EPH 2021-2024, EPHC 2021-2024, EPHPM 2021-2024, UIS admin 2021-2024, WPP 2021-2024, country control files
  - Implementation precedent: stata2r + survey/srvyr + DHS Indicators R as implementation precedent for harmonization, weighting, and Stata-to-R translation.
  - Repo presentation implication: control-file-driven reproducibility and QA tables

### Output 5

**Job activity:** Generate validated household survey-based education indicators; produce quality-assurance notes; update metadata/user-facing explanations for GEM platforms (WIDE, VIEW, SCOPE).

- **indicator generation**: Publish only validated outputs with explicit source-year provenance and aligned metadata rows.
  - Platform anchor: WIDE/VIEW/SCOPE publication layer
  - Source scope: EPH 2021-2024, EPHC 2021-2024, EPHPM 2021-2024, ERCE 2019, PISA 2022, PISA-D 2016, UIS admin 2021-2024, UIS learning API 2021-2024, WPP 2021-2024, OECD DAC/CRS 2021-2024, UIS Inventory of Household Surveys, UIS Inventory of Learning Assessments
  - Implementation precedent: Open SDG / UNESCO-style flat-file exports as implementation precedent for platform packaging and metadata handoff.
  - Repo presentation implication: country pages, trend charts, indicator cards, downloadable flat files
- **platform packaging**: Export flat CSV/JSON plus short user-facing explanations mirroring WIDE, VIEW, and SCOPE presentation logic.
  - Platform anchor: WIDE/VIEW/SCOPE publication layer
  - Source scope: EPH 2021-2024, EPHC 2021-2024, EPHPM 2021-2024, ERCE 2019, PISA 2022, PISA-D 2016, UIS admin 2021-2024, UIS learning API 2021-2024, WPP 2021-2024, OECD DAC/CRS 2021-2024, UIS Inventory of Household Surveys, UIS Inventory of Learning Assessments
  - Implementation precedent: Open SDG / UNESCO-style flat-file exports as implementation precedent for platform packaging and metadata handoff.
  - Repo presentation implication: country pages, trend charts, indicator cards, downloadable flat files
- **documentation enhancement**: Attach technical notes and metadata files directly to platform artifacts, not as disconnected internal memos.
  - Platform anchor: WIDE/VIEW/SCOPE publication layer
  - Source scope: EPH 2021-2024, EPHC 2021-2024, EPHPM 2021-2024, ERCE 2019, PISA 2022, PISA-D 2016, UIS admin 2021-2024, UIS learning API 2021-2024, WPP 2021-2024, OECD DAC/CRS 2021-2024, UIS Inventory of Household Surveys, UIS Inventory of Learning Assessments
  - Implementation precedent: Open SDG / UNESCO-style flat-file exports as implementation precedent for platform packaging and metadata handoff.
  - Repo presentation implication: country pages, trend charts, indicator cards, downloadable flat files

### Output 6

**Job activity:** Consolidated documentation of inventories, workflows, scripts, QA procedures; final synthesis report; forward-looking technical recommendations for strengthening SDG 4 monitoring.

- **handover packaging**: Freeze inventories, configs, scripts, QA logs, and metadata tables into a clean repo tree with deterministic entrypoints.
  - Platform anchor: GEM handover and maintenance layer
  - Source scope: Inventories, configs, scripts, QA logs, metadata tables, archive rationale, and platform handoff files
  - Implementation precedent: DHS-style repository documentation and GEM handover logic as precedent for operational packaging and institutional memory.
  - Repo presentation implication: repo tree, README, change log, gap register
- **synthesis reporting**: Summarize sources used, outputs delivered, unresolved gaps, and next-priority acquisitions in a single operational note.
  - Platform anchor: GEM handover and maintenance layer
  - Source scope: Inventories, configs, scripts, QA logs, metadata tables, archive rationale, and platform handoff files
  - Implementation precedent: DHS-style repository documentation and GEM handover logic as precedent for operational packaging and institutional memory.
  - Repo presentation implication: repo tree, README, change log, gap register
- **institutional memory**: Document why sources were included, excluded, or archived so future cycles do not repeat dead-end acquisitions.
  - Platform anchor: GEM handover and maintenance layer
  - Source scope: Inventories, configs, scripts, QA logs, metadata tables, archive rationale, and platform handoff files
  - Implementation precedent: DHS-style repository documentation and GEM handover logic as precedent for operational packaging and institutional memory.
  - Repo presentation implication: repo tree, README, change log, gap register

## Output Methods Not Explicitly Named In P01-P17

The output layer contains implementation methods that are either aliases of longer process names, decomposed submethods that the objective bullets leave implicit, or genuinely additional workflow methods needed to operationalize the repo. The list below separates those cases and highlights which ones actually signal quantitative competence in the demo.

- **Output 1 :: inventory standardization**
  - Classification: decomposed_submethod
  - Related process(es): P02
  - Method class: data_engineering_procedural
  - Quantitative signal for the demo: medium
  - Why it does not appear as its own P01-P17 method: P02 names inventory maintenance broadly, while the output layer makes the schema-standardization step explicit.
  - Canonical output method: Build a canonical inventory schema with country, source, year, unit of analysis, education modules, access status, and notes on comparability.
  - Repo-deployable artifacts: canonical inventory schema; stable-key validator; append-only inventory updater
  - Canonical citations: `uis_household_handbook_2025; uis_hhs_position_paper_2023; wide_about`
  - Platform anchor: WIDE + VIEW + SCOPE source discovery
  - Source scope: EPH 2021-2024, EPHC 2021-2024, EPHPM 2021-2024, ILOSTAT catalogue, UIS household-survey inventory
- **Output 1 :: prioritization**
  - Classification: decomposed_submethod
  - Related process(es): P01, P02
  - Method class: procedural
  - Quantitative signal for the demo: low
  - Why it does not appear as its own P01-P17 method: The objectives speak about identification and maintenance, but the output layer exposes the explicit ranking/selection step needed to choose the active core.
  - Canonical output method: Rank sources by canonical relevance to WIDE/VIEW/SCOPE, not by availability alone.
  - Repo-deployable artifacts: source-ranking table; active-core selector; source status note
  - Canonical citations: `wide_about; scope_about; scope_indicators`
  - Platform anchor: WIDE + VIEW + SCOPE source discovery
  - Source scope: EPH 2021-2024, EPHC 2021-2024, EPHPM 2021-2024, ILOSTAT catalogue, UIS household-survey inventory
- **Output 1 :: source discovery**
  - Classification: alias_of_process_method
  - Related process(es): P01
  - Method class: procedural
  - Quantitative signal for the demo: low
  - Why it does not appear as its own P01-P17 method: The output layer shortens the full P01 method name `source discovery and source admissibility audit` into a simpler label.
  - Canonical output method: Enumerate nationally representative survey families first, then tag each by indicator relevance, years, and access path.
  - Repo-deployable artifacts: inventory seed script; source ledger; admissibility decision table
  - Canonical citations: `wide_about; uis_edsc_household_surveys; uis_household_handbook_2025; uis_hhs_position_paper_2023`
  - Platform anchor: WIDE + VIEW + SCOPE source discovery
  - Source scope: EPH 2021-2024, EPHC 2021-2024, EPHPM 2021-2024, ILOSTAT catalogue, UIS household-survey inventory
- **Output 2 :: comparability audit**
  - Classification: decomposed_submethod
  - Related process(es): P03, P04, P14, P15
  - Method class: mixed
  - Quantitative signal for the demo: medium
  - Why it does not appear as its own P01-P17 method: Comparability checks are spread across methodological notes, module review, disaggregated review, and post-secondary review; the output layer consolidates them as one operational method.
  - Canonical output method: Map cross-country and cross-wave comparability explicitly: age ranges, schooling definitions, missing modules, and source-year gaps.
  - Repo-deployable artifacts: comparability matrix; year-coverage audit; subgroup comparability note
  - Canonical citations: `uis_household_handbook_2025; uis_hhs_position_paper_2023; uis_household_guide_2017; wide_about`
  - Platform anchor: WIDE source-year discipline + VIEW/SCOPE metadata discipline
  - Source scope: EPH 2021-2024, EPHC 2021-2024, EPHPM 2021-2024, ILOSTAT methodological notes, UIS inventory extracts
- **Output 2 :: technical recommendation**
  - Classification: decomposed_submethod
  - Related process(es): P03
  - Method class: procedural
  - Quantitative signal for the demo: low
  - Why it does not appear as its own P01-P17 method: P03 requires methodological notes, but the output layer surfaces the explicit keep/defer/archive recommendation that closes each note.
  - Canonical output method: Conclude each note with a keep/defer/archive recommendation tied to the platform use case.
  - Repo-deployable artifacts: source recommendation memo; keep/defer/archive status field
  - Canonical citations: `uis_education_literacy_methodology; wide_about`
  - Platform anchor: WIDE source-year discipline + VIEW/SCOPE metadata discipline
  - Source scope: EPH 2021-2024, EPHC 2021-2024, EPHPM 2021-2024, ILOSTAT methodological notes, UIS inventory extracts
- **Output 3 :: feasibility note**
  - Classification: decomposed_submethod
  - Related process(es): P04
  - Method class: procedural
  - Quantitative signal for the demo: low
  - Why it does not appear as its own P01-P17 method: P04 asks for review of additional constructs; the output layer makes explicit the closing feasibility decision for current vs future integration.
  - Canonical output method: Document which constructs can be integrated into current outputs versus future extensions.
  - Repo-deployable artifacts: construct feasibility table; current-vs-future inclusion note
  - Canonical citations: `uis_edsc_household_surveys; uis_edsc_gaml; scope_indicators`
  - Platform anchor: WIDE learning source overlay + UIS learning API
  - Source scope: EPH 2021-2024, EPHC 2021-2024, EPHPM 2021-2024, ERCE 2019, PISA 2022, PISA-D 2016, UIS learning API, questionnaires/codebooks
- **Output 3 :: triangulation**
  - Classification: additional_output_method
  - Related process(es): P04, P12, P14, P15
  - Method class: mixed
  - Quantitative signal for the demo: high
  - Why it does not appear as its own P01-P17 method: No process bullet names triangulation directly, but it is required to reconcile household surveys, learning assessments, admin series, and platform definitions before variable admission or publication.
  - Canonical output method: Triangulate construct feasibility across survey instruments, platform needs, and public indicator definitions before adding a variable into the demo scope.
  - Repo-deployable artifacts: source triangulation matrix; nearest-source-year reconciliation note; cross-source consistency checks
  - Canonical citations: `wide_about; scope_about; scope_indicators; gem_view_out_school_methods; gem_view_completion`
  - Platform anchor: WIDE learning source overlay + UIS learning API
  - Source scope: EPH 2021-2024, EPHC 2021-2024, EPHPM 2021-2024, ERCE 2019, PISA 2022, PISA-D 2016, UIS learning API, questionnaires/codebooks
- **Output 4 :: harmonization**
  - Classification: alias_of_process_method
  - Related process(es): P06
  - Method class: mixed
  - Quantitative signal for the demo: high
  - Why it does not appear as its own P01-P17 method: P06 is named `harmonization of education variables across household survey sources`, while the output layer uses the shorter operational label `harmonization`.
  - Canonical output method: Create source-specific recode maps into a common variable contract, then version country exceptions explicitly instead of burying them in code.
  - Repo-deployable artifacts: recode maps; harmonized flat files; exception log; test fixtures
  - Canonical citations: `uis_household_indicator_calculation_2023; uis_completion_rate_glossary; uis_total_net_attendance_rate_glossary; gem_view_out_school_methods`
  - Platform anchor: VIEW modeling discipline + WIDE/SCOPE harmonization discipline
  - Source scope: EPH 2021-2024, EPHC 2021-2024, EPHPM 2021-2024, UIS admin 2021-2024, WPP 2021-2024, country control files
- **Output 4 :: QA**
  - Classification: alias_of_process_method
  - Related process(es): P08
  - Method class: quantitative
  - Quantitative signal for the demo: high
  - Why it does not appear as its own P01-P17 method: P08 spells out internal consistency, coherence, and plausibility; the output layer collapses that into the shorter but implementation-critical label `QA`.
  - Canonical output method: Run internal consistency, cross-indicator coherence, and plausibility checks against reference layers before publication.
  - Repo-deployable artifacts: QA report; consistency checks; cross-indicator validation tables
  - Canonical citations: `uis_education_literacy_methodology; gem_view_out_school_methods; scope_about`
  - Platform anchor: VIEW modeling discipline + WIDE/SCOPE harmonization discipline
  - Source scope: EPH 2021-2024, EPHC 2021-2024, EPHPM 2021-2024, UIS admin 2021-2024, WPP 2021-2024, country control files
- **Output 4 :: Stata-to-R translation**
  - Classification: alias_of_process_method
  - Related process(es): P09, P10
  - Method class: technical
  - Quantitative signal for the demo: high
  - Why it does not appear as its own P01-P17 method: The process map names refactoring/migration in longer form; the output layer compresses it into the deployable translation task.
  - Canonical output method: Translate legacy logic into tidy, testable R scripts while preserving survey design handling and value-label semantics.
  - Repo-deployable artifacts: paired Stata/R scripts; translation notes; regression tests
  - Canonical citations: `gem_view_out_school_methods; scope_about`
  - Platform anchor: VIEW modeling discipline + WIDE/SCOPE harmonization discipline
  - Source scope: EPH 2021-2024, EPHC 2021-2024, EPHPM 2021-2024, UIS admin 2021-2024, WPP 2021-2024, country control files
- **Output 5 :: documentation enhancement**
  - Classification: alias_of_process_method
  - Related process(es): P16
  - Method class: procedural
  - Quantitative signal for the demo: low
  - Why it does not appear as its own P01-P17 method: P16 already contains this method in longer form; the output layer uses a shorter label tied to publication packaging.
  - Canonical output method: Attach technical notes and metadata files directly to platform artifacts, not as disconnected internal memos.
  - Repo-deployable artifacts: technical notes; metadata tables; user-facing method explanations
  - Canonical citations: `scope_about; scope_indicators; wide_about`
  - Platform anchor: WIDE/VIEW/SCOPE publication layer
  - Source scope: EPH 2021-2024, EPHC 2021-2024, EPHPM 2021-2024, ERCE 2019, PISA 2022, PISA-D 2016, UIS admin 2021-2024, UIS learning API 2021-2024, WPP 2021-2024, OECD DAC/CRS 2021-2024, UIS Inventory of Household Surveys, UIS Inventory of Learning Assessments
- **Output 5 :: indicator generation**
  - Classification: decomposed_submethod
  - Related process(es): P07, P12
  - Method class: quantitative
  - Quantitative signal for the demo: high
  - Why it does not appear as its own P01-P17 method: P07 and P12 mention template scripts and estimate generation, but the output layer isolates the actual computation of publication-ready indicators.
  - Canonical output method: Publish only validated outputs with explicit source-year provenance and aligned metadata rows.
  - Repo-deployable artifacts: indicator computation scripts; country outputs; weighted estimate tables
  - Canonical citations: `scope_indicators; wide_about; gem_view_completion; gem_view_out_school_methods`
  - Platform anchor: WIDE/VIEW/SCOPE publication layer
  - Source scope: EPH 2021-2024, EPHC 2021-2024, EPHPM 2021-2024, ERCE 2019, PISA 2022, PISA-D 2016, UIS admin 2021-2024, UIS learning API 2021-2024, WPP 2021-2024, OECD DAC/CRS 2021-2024, UIS Inventory of Household Surveys, UIS Inventory of Learning Assessments
- **Output 5 :: platform packaging**
  - Classification: decomposed_submethod
  - Related process(es): P16
  - Method class: procedural
  - Quantitative signal for the demo: medium
  - Why it does not appear as its own P01-P17 method: P16 speaks about documentation and user-facing explanations, while the output layer adds the platform packaging step required to make outputs look and behave like WIDE/VIEW/SCOPE.
  - Canonical output method: Export flat CSV/JSON plus short user-facing explanations mirroring WIDE, VIEW, and SCOPE presentation logic.
  - Repo-deployable artifacts: country pages; trend pages; downloadable CSV/JSON; metadata cards
  - Canonical citations: `wide_about; scope_about; scope_indicators`
  - Platform anchor: WIDE/VIEW/SCOPE publication layer
  - Source scope: EPH 2021-2024, EPHC 2021-2024, EPHPM 2021-2024, ERCE 2019, PISA 2022, PISA-D 2016, UIS admin 2021-2024, UIS learning API 2021-2024, WPP 2021-2024, OECD DAC/CRS 2021-2024, UIS Inventory of Household Surveys, UIS Inventory of Learning Assessments
- **Output 6 :: handover packaging**
  - Classification: decomposed_submethod
  - Related process(es): P11, P13, P17
  - Method class: procedural
  - Quantitative signal for the demo: medium
  - Why it does not appear as its own P01-P17 method: The process bullets spread reproducibility, documentation, and technical support across several tasks; the output layer exposes the final packaging step as its own method.
  - Canonical output method: Freeze inventories, configs, scripts, QA logs, and metadata tables into a clean repo tree with deterministic entrypoints.
  - Repo-deployable artifacts: release bundle; reproducibility tree; handover README
  - Canonical citations: `scope_about; wide_about`
  - Platform anchor: GEM handover and maintenance layer
  - Source scope: Inventories, configs, scripts, QA logs, metadata tables, archive rationale, and platform handoff files
- **Output 6 :: institutional memory**
  - Classification: decomposed_submethod
  - Related process(es): P11, P13
  - Method class: procedural
  - Quantitative signal for the demo: medium
  - Why it does not appear as its own P01-P17 method: The process map references documentation and reuse, but the output layer surfaces institutional memory as a named operational deliverable.
  - Canonical output method: Document why sources were included, excluded, or archived so future cycles do not repeat dead-end acquisitions.
  - Repo-deployable artifacts: archive rationale; source decisions log; maintenance playbook
  - Canonical citations: `scope_about; wide_about`
  - Platform anchor: GEM handover and maintenance layer
  - Source scope: Inventories, configs, scripts, QA logs, metadata tables, archive rationale, and platform handoff files
- **Output 6 :: synthesis reporting**
  - Classification: decomposed_submethod
  - Related process(es): P17
  - Method class: procedural
  - Quantitative signal for the demo: low
  - Why it does not appear as its own P01-P17 method: The objectives mention technical support to analyses, but the output layer makes explicit the synthesis note that closes the cycle and communicates gaps and next steps.
  - Canonical output method: Summarize sources used, outputs delivered, unresolved gaps, and next-priority acquisitions in a single operational note.
  - Repo-deployable artifacts: synthesis memo; gap register; source-use summary
  - Canonical citations: `scope_about; wide_about; gem_aid_tables_2024`
  - Platform anchor: GEM handover and maintenance layer
  - Source scope: Inventories, configs, scripts, QA logs, metadata tables, archive rationale, and platform handoff files

## Visual Presentation Rules For The Demo Repo

### WIDE

- Use one country page per sample country with visible source-year badges next to every indicator.
- Present disaggregation first: wealth, sex, location, ethnicity/disability when available.
- Use small multiples, maps, charts and tables, with download/export controls surfaced in the UI.
- Keep learning results visually linked to the same country page rather than on a separate analytical notebook.

### VIEW

- Use time-series charts with observed-source points and a modeled line or aligned trend layer.
- Separate raw source observations from modeled/validated outputs in the legend.
- Show uncertainty or methodological caveat bands where modeling is involved.
- Attach a compact methods note directly below the figure, not in a disconnected appendix.

### SCOPE

- Organize the repo landing page by the five themes: Access, Equity, Learning, Quality, Finance.
- Use indicator cards that link to technical metadata and user-facing explanation pages.
- Keep indicator pages concise: chart first, then source-year, then definition and limitations.
- Expose downloadable flat files and a machine-readable metadata table alongside the visual.

### GEM

- Write technical notes in the same order GEM uses operationally: source, coverage, harmonization rule, caveat, output file.
- Prefer flat CSV/JSON handoff artifacts plus short methodological markdown pages over notebooks as the public-facing layer.
- Make every chart reproducible from a clearly named script and a control/config file.
- Use restrained design: policy-facing text, explicit provenance, no exploratory clutter.

## Minimal Repo IA

- `data/`: canonical source extracts and derived flat files
- `config/`: country-source control files
- `scripts/01_inventory/`: source discovery and inventory building
- `scripts/02_notes/`: methodological-note generation
- `scripts/03_modules/`: module review and feasibility checks
- `scripts/04_harmonize/`: recodes, joins, QA, and Stata-to-R translations
- `scripts/05_publish/`: indicator exports, metadata, and user-facing pages
- `scripts/06_handover/`: synthesis, gap logs, and maintenance notes
- `site/` or `docs/`: WIDE/VIEW/SCOPE-style presentation layer

## Visual End Product

- `site/index.md`: SCOPE-style landing page with five thematic entrypoints.
- `site/countries/<country>.md`: WIDE-style country pages with source-year badges and learning overlays.
- `site/view/`: VIEW-style trend pages separating observed points, aligned/modelled series, and methods notes.
- `site/metadata/`: downloadable metadata tables, QA notes, and flat file links.

## Method Appendices

These appendices distill the operational method inductively from real canonical documents, country pages, and source programs already audited in the stack. Each appendix first shows concrete applications and then states the reusable template for implementation in the demo repo.

### Appendix A. Source Admissibility Audit by Example

Real examples:
1. Dataset/source: `EPH, Argentina, 2023`
   Source document: WIDE Argentina country page plus the active recent-source inventory for Argentina
   Variable or indicator: Primary/lower-secondary completion and out-of-school indicators as displayed on WIDE
   Observed evidence: The public WIDE page shows Argentina indicators with the visible source badge `EPH, 2023`. The local recent inventory also contains EPH waves in the active recent core.
   Rule applied: Apply the admissibility audit: nationally relevant household survey, explicit source-year, education indicator use visible on the canonical platform, and sufficient provenance to display the source-year publicly.
   Decision/transform in practice: The source is admitted because WIDE publicly labels Argentina's household-survey indicators with `EPH, 2023`, which satisfies source-year provenance, national relevance, and indicator applicability for access/completion outputs.
   Output artifact: Inventory row marked `admit`, platform source label fixed as `EPH, 2023`, and the household-survey branch retained in the recent core.
   Canonical citations: `wide_argentina; wide_about`
2. Dataset/source: `EPH/EPHPM, Honduras, 2023`
   Source document: WIDE Honduras country page plus Honduras recent microdata manifest
   Variable or indicator: Completion and participation indicators on the Honduras WIDE country page
   Observed evidence: The public WIDE page displays Honduras access/completion indicators with `EPH, 2023`, while the local operational files are `EPHPM 2021-2024`.
   Rule applied: Separate platform label from local operational file family; admit the NSO source family if the public platform label and the local file provenance can be reconciled without changing the substantive source identity.
   Decision/transform in practice: The source is admitted as the operative national household survey for recent access/completion outputs, while older DHS waves remain non-core for the recent integrated stack.
   Output artifact: Inventory row retained as active recent source, with WIDE label stored separately from the local filename family `EPHPM`.
   Canonical citations: `wide_honduras; wide_about`
3. Dataset/source: `EPHC, Paraguay, 2019/2023`
   Source document: WIDE Paraguay country page plus Paraguay recent microdata manifest
   Variable or indicator: Schooling deprivation and completion indicators on WIDE
   Observed evidence: WIDE displays Paraguay indicators with `EPHC, 2019` and recent `EPH, 2023`-style labels, while the local NSO download contains recent EPHC microdata waves.
   Rule applied: Admit the country source when the public indicator page and the local NSO files both identify the same survey family and explicit year labels can be preserved.
   Decision/transform in practice: Paraguay's EPHC is admissible because WIDE displays it as the canonical country source with explicit year tags, showing the required source-year discipline.
   Output artifact: Canonical household source retained for Paraguay, with year-specific labels preserved in the metadata layer instead of collapsing all waves into one generic source.
   Canonical citations: `wide_paraguay; wide_about`
4. Dataset/source: `ERCE 2019`
   Source document: UNESCO ERCE 2019 landing page plus WIDE country pages
   Variable or indicator: Reading and mathematics learning results used on WIDE country pages
   Observed evidence: ERCE appears as the named learning source on the country pages, and UNESCO publishes ERCE as the regional assessment program with defined grade/domain scope.
   Rule applied: Admit a learning source only if the assessment program is publicly documented, the domain/grade scope is explicit, and the source appears in the canonical platform layer for the relevant country outputs.
   Decision/transform in practice: ERCE is admitted as a canonical learning source because it is an official UNESCO regional assessment with documented grade/domain scope and visible use on the WIDE country pages.
   Output artifact: Learning-source inventory row created with source program `ERCE`, cycle `2019`, and use case `country-page learning overlay`.
   Canonical citations: `erce_2019_unesco; wide_argentina; wide_honduras; wide_paraguay`
5. Dataset/source: `PISA 2022 / PISA-D 2016`
   Source document: OECD PISA/PISA-D database pages plus WIDE country pages
   Variable or indicator: Secondary-level learning results on WIDE country pages
   Observed evidence: WIDE shows PISA or PISA-D as the learning source for secondary-age outcomes, and OECD publishes the corresponding database and analysis documentation.
   Rule applied: Admit the source when there is both a canonical platform use case and an official producer database/documentation trail sufficient to interpret the output.
   Decision/transform in practice: OECD PISA and PISA-D are admitted as canonical learning sources because the country pages visibly use them, and OECD publishes the database and analysis documentation needed for provenance and interpretation.
   Output artifact: Separate learning inventory rows created for `PISA 2022` and `PISA-D 2016`, rather than a generic pooled OECD learning row.
   Canonical citations: `pisa_2022_database; pisa_d_database; pisa_2022_analysis_docs; wide_argentina; wide_honduras; wide_paraguay`

Distilled general template:
- Step 1: Verify that the candidate source is publicly or institutionally recognized in the canonical platform layer for the country or indicator family.
- Step 2: Confirm that the source has an identifiable source-year, target population, and documentation trail.
- Step 3: Test whether the education variable set can support a published UIS/GEM indicator definition without changing substantive meaning.
- Step 4: Record the admissibility decision as `admit`, `defer`, or `exclude`, with explicit reason codes rather than narrative-only notes.
- Step 5: Preserve the platform-facing source label exactly as it should appear on the public page.

### Appendix B. Inventory Maintenance by Example

Real examples:
1. Dataset/source: `Argentina EPH 2021-2024`
   Source document: Argentina recent microdata manifest and canonical recent-window matrix
   Variable or indicator: Recent household-survey microdata inventory rows
   Observed evidence: Multiple recent EPH waves exist locally and belong to the same national survey family.
   Rule applied: One row per country-source-year-unit combination; append a new row for each new wave; never overwrite a historical wave.
   Decision/transform in practice: The inventory keeps one stable row per country-source-year-unit combination; new EPH waves are appended, not merged over prior rows.
   Output artifact: Append-only inventory block for Argentina with distinct rows for 2021, 2022, 2023, and 2024 waves.
   Canonical citations: `wide_argentina; uis_household_handbook_2025; uis_hhs_position_paper_2023`
2. Dataset/source: `Honduras EPHPM 2021-2024`
   Source document: Honduras recent microdata manifest and canonical recent-window matrix
   Variable or indicator: Recent household-survey microdata inventory rows
   Observed evidence: The local Honduras stack contains multiple EPHPM waves and a distinct public label discipline on WIDE.
   Rule applied: Store source-year, access-state, and active-core status separately so recent selection is metadata-driven, not filename-driven.
   Decision/transform in practice: EPHPM waves are stored with explicit source-year and access-state fields so the active recent wave can be selected without deleting historical provenance.
   Output artifact: Honduras inventory rows with `active_flag`, source-year, and platform-label fields separated.
   Canonical citations: `wide_honduras; uis_household_handbook_2025`
3. Dataset/source: `Paraguay EPHC 2021-2024`
   Source document: Paraguay recent microdata manifest and canonical recent-window matrix
   Variable or indicator: Recent household-survey microdata inventory rows
   Observed evidence: Paraguay has multiple recent EPHC waves in the active stack plus older historically useful material.
   Rule applied: Keep recent-core and historical-alt status as separate metadata, not as file deletion or implicit convention.
   Decision/transform in practice: EPHC rows are maintained append-only, with the recent integrated core separated from older waves that remain historically useful but non-core.
   Output artifact: Inventory rows retained for all waves, with recent-core selection encoded in status fields rather than destructive cleanup.
   Canonical citations: `wide_paraguay; uis_household_handbook_2025`
4. Dataset/source: `ERCE 2019`
   Source document: ERCE source acquisition manifest and UNESCO ERCE program pages
   Variable or indicator: Learning-source inventory row
   Observed evidence: ERCE was downloaded and verified as a learning dataset, with different unit/domain logic from household surveys.
   Rule applied: Learning programs require a distinct source family in the inventory because their unit of analysis and publication role differ from household surveys.
   Decision/transform in practice: The learning-source row is keyed separately from household surveys because the unit of analysis, domain coverage, and publication role differ materially from household survey sources.
   Output artifact: A dedicated learning-source inventory row with source family `learning_assessment` instead of `household_survey`.
   Canonical citations: `erce_2019_unesco; uis_edsc_gaml`
5. Dataset/source: `PISA 2022 / PISA-D 2016`
   Source document: PISA and PISA-D manifests plus OECD database landing pages
   Variable or indicator: Learning-source inventory rows
   Observed evidence: PISA and PISA-D are separate programs with different cycles and country coverage, but both appear in the canonical learning layer.
   Rule applied: Do not aggregate distinct learning programs under a generic producer key when the cycle and platform use case differ.
   Decision/transform in practice: PISA and PISA-D enter the inventory as distinct source programs with explicit cycle years and canonical use cases, preventing accidental aggregation under a generic `OECD` label.
   Output artifact: Separate inventory rows for PISA and PISA-D with cycle-specific metadata and source labels.
   Canonical citations: `pisa_2022_database; pisa_d_database; uis_edsc_gaml`

Distilled general template:
- Stable key: `country + source_program + source_label + year + unit_of_analysis`.
- Append-only rule: every new wave creates a new row; historical rows are never silently overwritten.
- Supersession rule: if a wave becomes non-core, mark `active_flag = false` and add a `supersedes` or `status_note` field rather than deleting the row.
- Coverage rule: store module coverage, learning/household classification, and platform use case in separate fields.
- Selection rule: derive the active recent core from the inventory, not from ad hoc filename inspection.

### Appendix C. Module Review and Harmonizability Classification by Example

Real examples:
1. Dataset/source: `EPH / EPHPM / EPHC`
   Source document: Questionnaires/codebooks plus UIS attendance glossary and household indicator calculation guide
   Variable or indicator: Current school attendance
   Observed evidence: The candidate variable is an attendance-state item with a direct schooling-status interpretation and a survey universe that can be matched to the attendance denominator.
   Rule applied: Classify as directly harmonizable only if the source item matches the attendance construct, the reference period is acceptable, and categories can be mapped losslessly into the publication contract.
   Decision/transform in practice: Attendance items are usually directly harmonizable when the target population and reference period match the UIS attendance definition and the response categories can be mapped losslessly to enrolled/not enrolled.
   Output artifact: Variable enters the harmonization map with a direct recode rule and no comparability exception.
   Canonical citations: `uis_total_net_attendance_rate_glossary; uis_household_indicator_calculation_2023; uis_household_guide_2017`
2. Dataset/source: `EPH / EPHPM / EPHC`
   Source document: Questionnaires/codebooks plus UIS completion glossary and household-survey handbook
   Variable or indicator: Highest level or grade completed
   Observed evidence: The variable captures schooling attainment, but it must be translated into the common level structure and linked to an age rule before it supports the official completion indicator.
   Rule applied: Classify as partially harmonizable when the construct is valid but only after school-structure/ISCED mapping or age adjustment.
   Decision/transform in practice: Completion variables are often partially harmonizable because they require school-structure or ISCED mapping and an age rule before they can support the published completion-rate indicator.
   Output artifact: Variable enters the map with a required crosswalk and a harmonization note rather than a direct recode.
   Canonical citations: `uis_completion_rate_glossary; uis_household_indicator_calculation_2023; uis_household_handbook_2025`
3. Dataset/source: `Household survey literacy item`
   Source document: Questionnaire wording plus UIS literacy glossary and household-survey guide
   Variable or indicator: Self-reported literacy status
   Observed evidence: The item may exist as a yes/no or multi-category self-report, and age thresholds can vary across sources.
   Rule applied: Classify as directly or partially harmonizable depending on whether the age threshold and response scale match the UIS literacy publication rule.
   Decision/transform in practice: Literacy may be directly or partially harmonizable depending on age threshold, question wording, and whether the response scale matches the UIS literacy definition used for publication.
   Output artifact: Variable either receives a direct literacy recode or is flagged for aggregation/age-threshold adjustment before use.
   Canonical citations: `uis_literacy_rate_glossary; uis_household_guide_2017`
4. Dataset/source: `ERCE 2019`
   Source document: ERCE technical report notice and ERCE acquisition manifest
   Variable or indicator: Reading proficiency at grade-based assessment points
   Observed evidence: ERCE proficiency results are fixed within an assessment design that defines grade and domain explicitly.
   Rule applied: Treat ERCE constructs as directly harmonizable only inside the ERCE learning layer, not as substitutes for household-survey schooling variables.
   Decision/transform in practice: ERCE reading results are directly harmonizable within the learning-assessment layer because grade, domain, and assessment design are fixed inside the ERCE program, but they are not interchangeable with household-survey schooling variables.
   Output artifact: ERCE remains in a separate learning-domain schema with no forced merge into household recodes.
   Canonical citations: `erce_2019_unesco; erce_2019_technical_report; uis_edsc_gaml`
5. Dataset/source: `PISA 2022 / PISA-D 2016`
   Source document: OECD PISA database pages and analysis documentation
   Variable or indicator: Reading or mathematics proficiency for 15-year-olds
   Observed evidence: PISA/PISA-D measure age-based proficiency, while ERCE is grade-based and household surveys measure schooling status rather than proficiency scores.
   Rule applied: Classify as non-comparable whenever the construct universe changes enough that harmonization would falsely imply the same educational measure.
   Decision/transform in practice: PISA and PISA-D learning variables are non-comparable with grade-based ERCE outcomes unless the review explicitly states that the comparison is cross-source and not a direct harmonization of the same construct universe.
   Output artifact: PISA/PISA-D retained as separate learning sources with explicit comparability caveats.
   Canonical citations: `pisa_2022_database; pisa_d_database; pisa_2022_analysis_docs; uis_edsc_gaml`

Distilled general template:
- Directly harmonizable: same construct, same target population, same reference period, and a lossless map to the published categories.
- Partially harmonizable: same construct, but only after documented aggregation, age adjustment, school-structure crosswalk, or category collapse.
- Non-comparable: the universe, wording, scale, or construct meaning changes enough that harmonization would alter substantive interpretation.
- Review each candidate variable against: definition, universe, response scale, reference period, and published indicator target.
- Record the classification and the exact transformation or caveat required before the variable enters the pipeline.

### Appendix D. Harmonization and Exception Logging by Example

Real examples:
1. Dataset/source: `EPH, Argentina`
   Source document: Argentina EPH microdata plus UIS attendance glossary
   Variable or indicator: Attendance indicator
   Observed evidence: The raw attendance variable exists in the recent household survey and must be translated to the publication denominator and state coding.
   Rule applied: Harmonize only after universe alignment and explicit recode to the published attendance state.
   Decision/transform in practice: Attendance is harmonized by aligning the survey universe to the published attendance denominator and recoding the response categories into the UIS attendance state used in publication.
   Output artifact: Country recode block plus no-exception entry if the direct mapping is lossless.
   Canonical citations: `uis_total_net_attendance_rate_glossary; uis_household_indicator_calculation_2023`
2. Dataset/source: `EPHPM, Honduras`
   Source document: Honduras EPHPM microdata plus UIS completion glossary
   Variable or indicator: Completion indicator
   Observed evidence: Schooling attainment exists but the local structure must be translated before the official completion population can be computed.
   Rule applied: Apply structure crosswalk first, then the official age rule, and only then compute the completion indicator.
   Decision/transform in practice: Completion is harmonized only after mapping the schooling variable to the common level structure and applying the official age rule for the reference completion population.
   Output artifact: Crosswalk table, age-rule parameter, and an explicit completion derivation note in the country log.
   Canonical citations: `uis_completion_rate_glossary; uis_household_handbook_2025`
3. Dataset/source: `EPHC, Paraguay`
   Source document: Paraguay EPHC microdata plus VIEW out-of-school methods and UIS glossary
   Variable or indicator: Out-of-school indicator
   Observed evidence: The source provides age and attendance information, but the school-age mapping and country education structure must be fixed before the numerator and denominator are coherent.
   Rule applied: When the indicator depends on school-age alignment, record the age mapping and every country-specific assumption in the exception log.
   Decision/transform in practice: The out-of-school numerator and denominator require school-age alignment, so the harmonization step explicitly records the age mapping and any country-specific education-structure assumption in the exception log.
   Output artifact: Out-of-school derivation block plus exception-log entry for the school-age mapping used.
   Canonical citations: `uis_out_of_school_rate_glossary; uis_household_indicator_calculation_2023; gem_view_out_school_methods`
4. Dataset/source: `ERCE 2019`
   Source document: ERCE 2019 database and technical documentation
   Variable or indicator: Reading proficiency layer
   Observed evidence: ERCE provides a complete learning-assessment layer with its own cycle, domain, and publication semantics.
   Rule applied: Do not force learning-assessment files into the household recode contract; harmonize them at the metadata layer with distinct source-year and domain fields.
   Decision/transform in practice: ERCE enters the harmonized stack as a distinct learning layer with its own source-year and assessment-domain fields, not by forcing it into the household-survey recode contract.
   Output artifact: Separate learning-layer output table keyed by country, cycle, domain, and subgroup.
   Canonical citations: `erce_2019_unesco; erce_2019_technical_report; scope_about`
5. Dataset/source: `PISA 2022 / PISA-D 2016`
   Source document: PISA/PISA-D public-use files and OECD methodology pages
   Variable or indicator: Secondary learning layer
   Observed evidence: PISA-family files are valid learning sources but not household survey schooling variables.
   Rule applied: Keep these sources harmonized at the metadata layer; log any attempt to merge them with household-schooling variables as a comparability exception.
   Decision/transform in practice: PISA and PISA-D are harmonized at the metadata layer through stable source labels, domains, and cycle years; any attempt to treat them as household-survey schooling variables would be logged as a comparability exception.
   Output artifact: Metadata-layer harmonization only, with explicit comparability caveat in the learning output note.
   Canonical citations: `pisa_2022_database; pisa_d_database; pisa_2022_analysis_docs; scope_about`

Distilled general template:
- Stage 1: align the source universe to the published indicator universe.
- Stage 2: translate schooling levels to the common structure or ISCED view.
- Stage 3: normalize response categories into the publication contract.
- Stage 4: apply age or reference-period adjustments only when the official indicator definition requires them.
- Stage 5: write every country-wave workaround to an exception log if it changes denominator, numerator, subgroup, or interpretation.

### Appendix E. Disaggregated-Data Methodological Review by Example

Real examples:
1. Dataset/source: `EPH, Argentina`
   Source document: Argentina country page, recent microdata, and completion indicator rule
   Variable or indicator: Completion by sex
   Observed evidence: Sex is available as a subgroup field and the completion indicator exists, but publication requires a check that the subgroup universe is still the official completion universe.
   Rule applied: Apply the base indicator definition first, then test whether the subgroup variable is stable and whether the subgrouped denominator is still valid.
   Decision/transform in practice: The disaggregated estimate is publishable only if the subgroup variable is stable across source-years and the subgroup universe matches the completion indicator universe.
   Output artifact: Publishable subgroup row if checks pass; otherwise caveat or suppress in the public output.
   Canonical citations: `wide_argentina; uis_completion_rate_glossary; uis_household_indicator_calculation_2023`
2. Dataset/source: `EPHPM, Honduras`
   Source document: Honduras recent microdata plus UIS attendance rule
   Variable or indicator: Attendance by location
   Observed evidence: The survey contains a location variable that can support an urban/rural or geographic disaggregation, but its definition must be stable across waves.
   Rule applied: Keep the subgroup only if definition stability and weighted support are adequate for public interpretation.
   Decision/transform in practice: Location-based disaggregation is methodologically acceptable when the urban/rural or geographic variable is consistently defined and the weighted support is adequate for interpretation.
   Output artifact: Location disaggregate published only after stability and support checks; otherwise retained internally as caveated.
   Canonical citations: `wide_honduras; uis_total_net_attendance_rate_glossary; uis_household_handbook_2025`
3. Dataset/source: `EPHC, Paraguay`
   Source document: Paraguay recent microdata and historical comparison notes
   Variable or indicator: Schooling deprivation by area
   Observed evidence: The base deprivation indicator is valid, but area definitions can shift with redesigns or coding changes.
   Rule applied: Do not publish a subgroup trend as comparable if the area variable changed meaning across waves, even when the base indicator formula stayed fixed.
   Decision/transform in practice: The subgroup estimate remains caveated if the area definition or survey redesign changes comparability across waves, even when the base indicator formula is unchanged.
   Output artifact: Subgroup trend either caveated in metadata or suppressed from the public comparison layer.
   Canonical citations: `wide_paraguay; uis_household_guide_2017`
4. Dataset/source: `ERCE 2019`
   Source document: ERCE technical documentation and learning output layer
   Variable or indicator: Reading performance by sex or location
   Observed evidence: The assessment design supports subgroup reporting, but subgroup validity depends on the assessment's own design and publication rules.
   Rule applied: Retain subgroup results only if the subgroup field is stable inside the assessment design and supports valid cross-country interpretation.
   Decision/transform in practice: Learning disaggregation is retained only when the subgroup field is stable inside the assessment design and the public interpretation remains comparable across participating countries.
   Output artifact: Learning subgroup output table with design-aware caveats, not a generic household-survey subgroup table.
   Canonical citations: `erce_2019_unesco; erce_2019_technical_report; uis_edsc_gaml`
5. Dataset/source: `PISA 2022 / PISA-D 2016`
   Source document: OECD PISA methodology pages and public-use files
   Variable or indicator: Mathematics or reading by subgroup
   Observed evidence: The base PISA estimate exists, but subgroup cells can become hard to interpret or sparse even when the national estimate is stable.
   Rule applied: Require a separate subgroup review for comparability, support, and interpretation before publishing a disaggregated learning result.
   Decision/transform in practice: Secondary-learning disaggregates require methodological review because subgroup comparability, sparse-cell risk, and interpretability can fail even when the base PISA estimate is valid.
   Output artifact: Subgroup output released only after methodological sign-off; otherwise caveated or excluded from the public layer.
   Canonical citations: `pisa_2022_database; pisa_d_database; pisa_2022_analysis_docs; uis_edsc_gaml`

Distilled general template:
- Apply the published base indicator definition first; do not invent a subgroup-specific estimator.
- Verify that the subgroup variable is consistently defined across waves and countries.
- Check that the subgroup universe matches the base indicator universe and does not silently change the denominator.
- Assess weighted support and interpretability before public release.
- Suppress or caveat subgroup results when a country-specific workaround breaks cross-country meaning.

## Official Links Audited

- `GEM_VIEW_out_school_methods`: https://www.unesco.org/gem-report/en/view/out-school-methods (status `200`, note `anti_bot_shell`)
- `GEM_VIEW_completion`: https://www.unesco.org/gem-report/en/view/completion (status `200`, note `anti_bot_shell`)
- `WIDE_about`: https://www.education-inequalities.org/about (status `200`)
- `WIDE_argentina`: https://www.education-inequalities.org/countries/argentina (status `200`)
- `WIDE_honduras`: https://www.education-inequalities.org/countries/honduras (status `200`)
- `WIDE_paraguay`: https://www.education-inequalities.org/countries/paraguay (status `200`)
- `SCOPE_about`: https://www.education-progress.org/en/about (status `200`)
- `SCOPE_indicators`: https://www.education-progress.org/en/indicators (status `200`)
- `UIS_API_docs`: https://api.uis.unesco.org/api/public/documentation/ (status `200`)

## Bibliography

- BibTeX file: `C:\Users\mglez\Documents\MGS\v0013\git_model\merida_raptor_mgs\docs\others\jobs\remote\un\Statistical Analysis Consultant\github_sample\data\gem_methodology.bib`
- Canonical references included for GEM, VIEW, WIDE, SCOPE, and UIS.

## Source Files Used

- `C:\Users\mglez\Documents\MGS\v0013\git_model\merida_raptor_mgs\docs\others\jobs\remote\un\Statistical Analysis Consultant\job.txt`
- `C:\Users\mglez\Documents\MGS\v0013\git_model\merida_raptor_mgs\docs\others\jobs\remote\un\Statistical Analysis Consultant\HARD_AUDIT_GITHUB_RESEARCH.md`
- `C:\Users\mglez\Documents\MGS\v0013\git_model\merida_raptor_mgs\docs\others\jobs\remote\un\Statistical Analysis Consultant\git_hub_un_gem\github_job_output_map.md`
- `C:\Users\mglez\Documents\MGS\v0013\git_model\merida_raptor_mgs\docs\others\jobs\remote\un\Statistical Analysis Consultant\github_sample\canonical_stack\canonical_source_map.csv`
- `C:\Users\mglez\Documents\MGS\v0013\git_model\merida_raptor_mgs\docs\others\jobs\remote\un\Statistical Analysis Consultant\github_sample\inv_data.txt`
