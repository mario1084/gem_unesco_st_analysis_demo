# GEM Harmonization Method

This document is the deployable specification for `02_harmonize` in the demo repo. It is limited to the active canonical stack for the Latin American sample and is written as an implementation contract, not as a general overview. The harmonization logic follows the public UIS household-survey methodology for SDG 4 measurement, the public WIDE source-discipline visible on country pages, and the acquired source files in the local stack: [UIS Household Survey Handbook](https://tcg.uis.unesco.org/wp-content/uploads/sites/4/2025/02/EDSC11_4.1_Household-Survey-Handbook.pdf), [UIS Position Paper on Household Surveys for SDG 4 Monitoring](https://tcg.uis.unesco.org/wp-content/uploads/sites/4/2023/10/HHS_position_paper_2023.touse_.pdf), [UIS Calculation of Education Indicators Based on Household Survey Data](https://tcg.uis.unesco.org/wp-content/uploads/sites/4/2024/02/Calculation-of-education-indicators_HHS_Report-UNESCO-UIS-13122023.pdf), [UIS Guide to the Analysis and Use of Household Survey and Census Education Data](https://uis.unesco.org/sites/default/files/documents/guide-to-the-analysis-and-use-of-household-survey-and-census-education-data-en_0.pdf), [UIS Code of Practice for Household Survey Data on Education](https://uis.unesco.org/sites/default/files/documents/code-practice-household-survey-2017-en.pdf), [Age adjustment techniques in the use of household survey data, DOI:10.15220/978-92-9189-206-8-en](https://doi.org/10.15220/978-92-9189-206-8-en), [Estimation of the numbers and rates of out-of-school children and adolescents using administrative and household survey data, DOI:10.15220/978-92-9189-207-5-en](https://doi.org/10.15220/978-92-9189-207-5-en), [World Inequality Database on Education, DOI:10.1080/00094056.2017.1367221](https://doi.org/10.1080/00094056.2017.1367221), [IPUMS Harmonization of Census Data, DOI:10.1002/9781119712206.ch12](https://doi.org/10.1002/9781119712206.ch12), [Harmonizing measurements: establishing a common metric via shared items across instruments, DOI:10.1186/s12963-024-00351-z](https://doi.org/10.1186/s12963-024-00351-z), [IPUMS MICS Data Harmonization Code, DOI:10.18128/D082.V1.3](https://doi.org/10.18128/D082.V1.3), [WIDE About](https://www.education-inequalities.org/about), [WIDE Argentina](https://www.education-inequalities.org/countries/argentina), [WIDE Honduras](https://www.education-inequalities.org/countries/honduras), and [WIDE Paraguay](https://www.education-inequalities.org/countries/paraguay).

No official GEM/WIDE/VIEW/SCOPE code repository exposing this exact harmonization pipeline was identified. The implementation below is therefore reconstructed from official methodological pages and the active canonical stack already downloaded.

## 1. Active Canonical Stack for Harmonization

Only the recent canonical household-survey layer enters `02_harmonize`.

| Country | Canonical source | Years | Raw files actually in stack | Local evidence |
|---|---|---:|---|---|
| Argentina | `EPH` | 2021-2024 | quarterly ZIP bundles, each with `usu_hogar_*.txt` and `usu_individual_*.txt` | [recent_microdata_manifest.csv](./NSO/Argentina/recent_microdata_manifest.csv) |
| Honduras | `EPHPM` | 2021-2024 | annual/june-release SPSS archives, including `Data de la Encuesta de Hogares 2024_PD.sav` | [recent_microdata_manifest.csv](./NSO/Honduras/recent_microdata_manifest.csv) |
| Paraguay | `EPHC` | 2021-2024 | `.SAV` and `.csv` files for `INGREFAM`, `REG01`, `REG02` | [recent_microdata_manifest.csv](./NSO/Paraguay/recent_microdata_manifest.csv) |

### 1.0 Temporal window and reporting cadence

This harmonization spec implements an **annual indicator series over the 2021–2024 reconstruction window** for the household-survey core. The `2021–2024` window is a demo implementation rule derived from the active canonical stack for `Argentina`, `Honduras`, and `Paraguay`; it is not claimed here as a universal GEM platform rule: [WIDE Argentina](https://www.education-inequalities.org/countries/argentina), [WIDE Honduras](https://www.education-inequalities.org/countries/honduras), [WIDE Paraguay](https://www.education-inequalities.org/countries/paraguay).

- `WIDE-style cadence`: public country pages show the latest valid source-year by indicator and source family, and those years can differ within the same country page. The demo therefore reconstructs **annual household indicator observations for 2021, 2022, 2023, and 2024** where the canonical household source exists, while preserving `source` and `source_year` on every row: [WIDE About](https://www.education-inequalities.org/about), [WIDE Argentina](https://www.education-inequalities.org/countries/argentina), [WIDE Honduras](https://www.education-inequalities.org/countries/honduras), [WIDE Paraguay](https://www.education-inequalities.org/countries/paraguay).
- `VIEW-style cadence`: `VIEW` uses annualized reporting logic that combines observed points with admin/population context. The harmonization layer therefore contributes **observed annual household points only**; it does not create synthetic between-wave household records: [VIEW out-of-school methods](https://www.unesco.org/gem-report/en/view/out-school-methods), [VIEW completion](https://www.unesco.org/gem-report/en/view/completion).
- `SCOPE-style cadence`: `SCOPE` integrates the latest available thematic indicators by source family. The household layer is therefore organized as an annual 2021–2024 series, while learning and finance layers remain source-native at their own canonical publication year: [SCOPE indicators](https://www.education-progress.org/en/indicators).

Operational rule: the household harmonization layer is maintained as **country-year-source annual records** over `2021–2024`. Learning, admin, population, and finance layers are integrated later and retain their own source-native year rather than forcing a fake same-year panel.

### 1.1 Stack partition

The active demo stack is partitioned so that each layer is used only for the method it can support under published GEM/UIS/WIDE/VIEW/SCOPE logic.

- `Household harmonization layer`: `EPH`, `EPHPM`, `EPHC`. This is the only layer that enters person-record harmonization and household-survey indicator construction: [WIDE About](https://www.education-inequalities.org/about), [UIS Household Survey Handbook](https://tcg.uis.unesco.org/wp-content/uploads/sites/4/2025/02/EDSC11_4.1_Household-Survey-Handbook.pdf).
- `Learning layer integration`: `ERCE 2019`, `PISA 2022`, `PISA-D 2016`, `UIS learning API`, and the sample-country extract from the [UIS Inventory of Learning Assessments](https://www.uis.unesco.org/en/data/inventory-learning-assements). These do not enter person-file harmonization in `02_harmonize`; they enter publication integration and thematic comparison in `03_indicators`.
- `Admin/reference integration`: `UIS admin 2021-2024` and `WPP 2021-2024`. These are reference and denominator layers used for contextualization, validation, and `VIEW`-style publication logic, not for row-level survey recoding: [Methodology: Education and Literacy](https://www.uis.unesco.org/en/themes/education-literacy), [VIEW out-of-school methods](https://www.unesco.org/gem-report/en/view/out-school-methods), [VIEW completion](https://www.unesco.org/gem-report/en/view/completion).
- `Finance integration`: `OECD DAC/CRS 2021-2024`. This layer is used only for `SCOPE`-style thematic publication blocks and does not enter the person-level harmonization contract: [GEM aid tables](https://www.unesco.org/gem-report/en/aid-tables), [SCOPE indicators](https://www.education-progress.org/en/indicators).

Supporting but non-harmonized reference layers:
- `UIS admin 2021-2024` for publication context and cross-checks, not for row-level microdata harmonization: [UIS Data API documentation](https://api.uis.unesco.org/api/public/documentation/), [Methodology: Education and Literacy](https://www.uis.unesco.org/en/themes/education-literacy).
- `WPP 2021-2024` for population denominators used later in `VIEW`-style publication logic, not for person-file harmonization.
- `UIS Inventory of Household Surveys` and `UIS Inventory of Learning Assessments` for source registration, not for row-level recoding.

Explicitly out of scope for `02_harmonize`:
- archived `MICS` and `DHS`
- `ERCE`, `PISA`, and `PISA-D` learning files
- `OECD DAC/CRS`

## 2. Harmonization Objective

The harmonization layer must transform each source-year raw file into a common person-level analytical structure that can reproduce UIS/GEM household-survey indicators without hidden country-specific logic in downstream code. In UIS terms, the harmonized layer must preserve source provenance, preserve indicator universes, and document all transformations that affect comparability or publication suitability: [UIS Handbook](https://tcg.uis.unesco.org/wp-content/uploads/sites/4/2025/02/EDSC11_4.1_Household-Survey-Handbook.pdf), [UIS Code of Practice](https://uis.unesco.org/sites/default/files/documents/code-practice-household-survey-2017-en.pdf), [Age adjustment techniques in the use of household survey data, DOI:10.15220/978-92-9189-206-8-en](https://doi.org/10.15220/978-92-9189-206-8-en), [Estimation of the numbers and rates of out-of-school children and adolescents using administrative and household survey data, DOI:10.15220/978-92-9189-207-5-en](https://doi.org/10.15220/978-92-9189-207-5-en).

Before defining the output tuple, the harmonization itself is formalized as a metadata-driven transform. This is the closest published methodological analogue found for the way GEM/WIDE-style harmonization must be implemented in code. In IPUMS International, harmonization is built from standardized metadata, source-specific correspondence tables, and composite coding that maps heterogeneous source categories into a comparable target coding while preserving source detail separately: [IPUMS Harmonization of Census Data, DOI:10.1002/9781119712206.ch12](https://doi.org/10.1002/9781119712206.ch12). In IPUMS MICS, the public harmonization code DOI documents a real survey implementation in which standardized variables, cross-survey coding rules, and source-specific set-up logic are applied to heterogeneous UNICEF MICS samples before extract generation: [IPUMS MICS Data Harmonization Code, DOI:10.18128/D082.V1.3](https://doi.org/10.18128/D082.V1.3). In comparable methodological literature outside the GEM ecosystem, harmonization across non-identical instruments is likewise formalized as a transform that uses anchors/shared items to recover a common metric rather than assuming raw comparability: [Harmonizing measurements: establishing a common metric via shared items across instruments, DOI:10.1186/s12963-024-00351-z](https://doi.org/10.1186/s12963-024-00351-z).

For this demo, the harmonization transform is therefore written as:


$$
z_{i,v}^{(h)} = g_{s,y,v}\!\left(x_{i,\mathcal{J}_{s,y,v}} \mid M_{s,y}, C_{s,y,v}, A_{s,y,v}\right)
$$


where:
- $x_{i,\mathcal{J}_{s,y,v}}$ is the set of source variables needed to derive harmonized target variable $v$ for record $i$
- $M_{s,y}$ is the source metadata/documentation package for source $s$ and year $y$
- $C_{s,y,v}$ is the correspondence table or composite-code mapping from source categories to the harmonized target definition
- $A_{s,y,v}$ is the admissibility/comparability rule set that determines whether the derived target is directly harmonizable, partially harmonizable, or non-comparable

The harmonized analytical record is then the output schema of that transform:


$$
H_i = \left(c_i, s_i, y_i, hh_i, p_i, z_{i,1}^{(h)}, \ldots, z_{i,K}^{(h)}, e_i\right)
$$


In the current household-survey demo, the required target set is:


$$
\{z_{i,1}^{(h)},\ldots,z_{i,K}^{(h)}\}
=
\{a_i, sex_i, loc_i, w_i, att_i, levcur_i, levcomp_i, lit_i, rep_i\}
$$


This means the tuple below is not the harmonization function itself; it is the declared output contract of a published-style metadata/correspondence-driven transform. That is methodologically stronger than treating the tuple as a free-standing guess, and it is the closest validated formalization located for GEM-adjacent public methods.

where:
- $c_i$ = country code
- $s_i$ = source program
- $y_i$ = survey year
- $hh_i$ = household identifier
- $p_i$ = person identifier
- $a_i$ = age
- $sex_i$ = sex
- $loc_i$ = location/residence field
- $w_i$ = final survey weight
- $att_i$ = harmonized current-attendance status
- $levcur_i$ = harmonized current level
- $levcomp_i$ = harmonized highest completed level
- $lit_i$ = harmonized literacy flag if admissible
- $rep_i$ = harmonized repetition flag if admissible
- $e_i$ = exception payload recording comparability caveats

### 2.1 External methodological validation of the transform and tuple

The tuple above is not a quoted UIS object, but the transform-plus-output structure is anchored in published methodological requirements:

- The transform form $z_{i,v}^{(h)} = g_{s,y,v}(\cdot)$ is validated by IPUMS-style harmonization, where standardized metadata, correspondence tables, and composite coding are the explicit mechanism used to derive harmonized variables from heterogeneous source variables while retaining traceability to the originals: [IPUMS Harmonization of Census Data, DOI:10.1002/9781119712206.ch12](https://doi.org/10.1002/9781119712206.ch12).
- The same metadata-plus-code approach is also validated by the archived IPUMS MICS harmonization code release, which shows a production implementation in which harmonized survey variables are generated through explicit cross-survey coding logic rather than by assuming the original UNICEF variable names are already comparable: [IPUMS MICS Data Harmonization Code, DOI:10.18128/D082.V1.3](https://doi.org/10.18128/D082.V1.3).
- The idea that non-identical source instruments can still be mapped into a common metric through explicitly declared anchors and transformation rules is validated by published harmonization literature using shared-item / common-metric construction: [Harmonizing measurements: establishing a common metric via shared items across instruments, DOI:10.1186/s12963-024-00351-z](https://doi.org/10.1186/s12963-024-00351-z).

- $(c_i, s_i, y_i, hh_i, p_i)$ is the provenance and linkage spine required to keep source-year identity, unit of observation, and household/person joins stable across waves; this follows the UIS code-of-practice emphasis on traceability and reproducibility in household-survey indicator production: [UIS Code of Practice](https://uis.unesco.org/sites/default/files/documents/code-practice-household-survey-2017-en.pdf), [UIS Guide to the Analysis and Use of Household Survey and Census Education Data](https://uis.unesco.org/sites/default/files/documents/guide-to-the-analysis-and-use-of-household-survey-and-census-education-data-en_0.pdf).
- $(a_i, sex_i, loc_i, w_i)$ is the minimum design and disaggregation core needed to define indicator universes, subgroup estimates, and weighted rates. UIS explicitly ties age adjustment, eligible-universe construction, and survey-weight use to household-survey indicator validity: [Age adjustment techniques in the use of household survey data, DOI:10.15220/978-92-9189-206-8-en](https://doi.org/10.15220/978-92-9189-206-8-en), [UIS Calculation of Education Indicators Based on Household Survey Data](https://tcg.uis.unesco.org/wp-content/uploads/sites/4/2024/02/Calculation-of-education-indicators_HHS_Report-UNESCO-UIS-13122023.pdf).
- $(att_i, levcur_i, levcomp_i, lit_i, rep_i)$ is the indicator-input core. These variables are required because public UIS/GEM practice computes attendance, out-of-school, completion, literacy, and related education measures from explicit universe and status fields rather than from opaque source-specific labels: [Estimation of the numbers and rates of out-of-school children and adolescents using administrative and household survey data, DOI:10.15220/978-92-9189-207-5-en](https://doi.org/10.15220/978-92-9189-207-5-en), [UIS Household Survey Handbook](https://tcg.uis.unesco.org/wp-content/uploads/sites/4/2025/02/EDSC11_4.1_Household-Survey-Handbook.pdf), [World Inequality Database on Education, DOI:10.1080/00094056.2017.1367221](https://doi.org/10.1080/00094056.2017.1367221).
- $e_i$ is not a published UIS symbol, but the need for an explicit exception carrier follows directly from the UIS code-of-practice requirement that departures from full comparability be documented and auditable rather than hidden inside recode scripts: [UIS Code of Practice](https://uis.unesco.org/sites/default/files/documents/code-practice-household-survey-2017-en.pdf), [UIS Position Paper on Household Surveys for SDG 4 Monitoring](https://tcg.uis.unesco.org/wp-content/uploads/sites/4/2023/10/HHS_position_paper_2023.touse_.pdf).

Learning and finance layers do not enter this tuple because they are integrated later in the demo as publication layers, not as person-level household harmonization inputs. In the active demo architecture, `ERCE`, `PISA`, `PISA-D`, and `OECD DAC/CRS` are therefore excluded from the household harmonization contract while remaining part of the full canonical stack for `03_indicators` and `05_publish`: [World Inequality Database on Education, DOI:10.1080/00094056.2017.1367221](https://doi.org/10.1080/00094056.2017.1367221), [Piloting PISA for development to success, DOI:10.1080/03057925.2020.1852914](https://doi.org/10.1080/03057925.2020.1852914), [SCOPE indicators](https://www.education-progress.org/en/indicators), [GEM aid tables](https://www.unesco.org/gem-report/en/aid-tables).

## 3. Source-Registration Method

Before any recode, every source-year must be registered as a canonical admissible wave. The admissibility rule follows the UIS household-survey criteria: source must be nationally interpretable, documented, identifiable by wave/year, and capable of supporting an education indicator universe without undocumented denominator drift: [UIS Position Paper](https://tcg.uis.unesco.org/wp-content/uploads/sites/4/2023/10/HHS_position_paper_2023.touse_.pdf), [UIS Guide](https://uis.unesco.org/sites/default/files/documents/guide-to-the-analysis-and-use-of-household-survey-and-census-education-data-en_0.pdf).

Each `source_registration.csv` row must contain:
- `country_code`
- `source_program`
- `survey_year`
- `periodicity`
- `file_name`
- `raw_member_name`
- `unit_of_observation`
- `weight_var`
- `design_vars`
- `education_vars_detected`
- `documentation_link`
- `admissibility_status`
- `admissibility_note`

### 3.1 Concrete source examples from the current stack

**Argentina 2024 Q1**
- archive: `EPH_usu_1_Trim_2024_txt.zip`
- members: `usu_hogar_T124.txt`, `usu_individual_T124.txt`
- person file contains observed variables such as `CODUSU`, `NRO_HOGAR`, `COMPONENTE`, `CH04`, `CH06`, `CH08`, `NIVEL_ED`, `ESTADO`, `PONDERA`, `MAS_500`.
- application: register the wave as `country_code=ARG`, `source_program=EPH`, `survey_year=2024`, `unit_of_observation=person`, `weight_var=PONDERA`, `design_vars=AGLOMERADO,MAS_500`, `education_vars_detected=CH08,NIVEL_ED,ESTADO`.

**Honduras 2024**
- archive: `BASE-DE-DATOS-EPHPM_JUNIO_2024.zip`
- microdata member: `Data de la Encuesta de Hogares 2024_PD.sav`
- observed variables include `SEXO`, `EDAD`, `DOMINIO`, `FACTOR`, `ED01`-`ED20`; labels confirm education content such as `ED02 ¿Está matriculado...?`, `ED03 ¿Asiste actualmente...?`, `ED05 nivel educativo más alto alcanzado`, `ED08 último grado aprobado`, `ED10 nivel educativo en el que estudia actualmente`, `ED11 ¿Está repitiendo el año?`.
- application: register the wave with `weight_var=FACTOR`, `design_vars=DOMINIO`, `household_id=HOGAR`, `person_id=ORDEN` for the current public demo contract, and candidate education block `ED01/ED02/ED03/ED05/ED08/ED10/ED11`. No additional PSU/strata variable has been promoted into the public demo contract because it was not verified in the current SPSS audit.

**Paraguay 2024**
- files: `INGREFAM_EPHC_ANUAL_2024.SAV`, `REG01_EPHC_ANUAL_2024.SAV`, `REG02_EPHC_ANUAL_2024.SAV` and CSV equivalents.
- `REG02_EPHC_ANUAL_2024.csv` exposes person-level education block including `ED02` (literacy), `ED03` (ever attended), `ED0504` (level/grade approved), `ED08` (currently attends), `ED09` (sector), `ED10` (reason for non-attendance), demographic roster variables including `AREA`, `P02`, `P08A`, and a final expansion field visible in the CSV header as `FEX.2022`.
- application: register `REG02` as the person file, `REG01` as household support, `weight_var=FEX.2022` for the current public CSV evidence, `design_vars=AREA`, `household_id=UPM+NVIVI+NHOGA`, `person_id=UPM+NVIVI+NHOGA+L02` for the public demo contract, and `INGREFAM` as income/household companion only if a downstream indicator explicitly requires it. If the `.SAV` metadata surfaces a year-specific expansion field with a different label, that change must be logged in `source_registration.csv`.

## 4. Harmonized Analytical Contract

Each harmonized person file must expose the following canonical fields.

| Harmonized field | Definition | Required for | Source examples |
|---|---|---|---|
| `country_code` | ISO3-like country code | all outputs | `ARG`, `HND`, `PRY` |
| `source_program` | source family | provenance | `EPH`, `EPHPM`, `EPHC` |
| `survey_year` | survey reference year | all outputs | 2021-2024 |
| `wave_id` | wave/period identifier | provenance and QA | quarter or annual label |
| `household_id_h` | harmonized household key | joins, denominators | `CODUSU+NRO_HOGAR`, `HOGAR`, `UPM+NVIVI+NHOGA` |
| `person_id_h` | harmonized person key | all person indicators | `CODUSU+NRO_HOGAR+COMPONENTE`, `HOGAR+ORDEN`, `UPM+NVIVI+NHOGA+L02` |
| `age_h` | age in completed years | universes | `CH06`, `EDAD`, `P08A` |
| `sex_h` | binary/standardized sex code | disaggregation | `CH04`, `SEXO`, `P02` |
| `location_h` | urban/rural or equivalent | disaggregation | `MAS_500`, `DOMINIO`, `AREA` |
| `weight_h` | final survey weight | all estimators | `PONDERA`, `FACTOR`, `FEX.2022` |
| `attending_currently_h` | currently attending educational institution | attendance/OOS | `CH08` or attendance item; `ED03`; `ED08` |
| `current_level_h` | currently attended level | attendance by level | `NIVEL_ED` with current-status logic; `ED10`; source-specific current level field |
| `highest_level_completed_h` | highest completed level | completion | `NIVEL_ED` + status logic; `ED05`; `ED0504` |
| `highest_grade_completed_h` | highest completed grade/year within level | completion | source-specific grade items |
| `literacy_h` | literacy flag if admissible | literacy | `ED01` for HND, `ED02` for PRY; ARG only if a valid literacy item exists |
| `repetition_h` | repeating-year flag if admissible | repetition | `ED11` in HND; only where a defensible item exists |
| `exception_flag` | any comparability caveat affecting the record | QA/publishability | derived |
| `exception_note` | human-readable caveat | QA/publishability | derived |

### 4.1 Operational harmonization matrix

The harmonization contract is executed variable by variable. The table below is the production map that links each harmonized field to the actual active stack, the raw source fields, the transformation class, and the indicator family it serves.

| Harmonized variable | Role in method | Country | Dataset/file | Raw variable(s) | Rule type | Required for indicator family |
|---|---|---|---|---|---|---|
| `country_code` | provenance key | ARG/HND/PRY | all person files | fixed country tag | direct assignment | all |
| `source_program` | provenance key | ARG | `EPH_usu_*_Trim_YYYY_txt.zip` | fixed source tag `EPH` | direct assignment | all |
| `source_program` | provenance key | HND | `EPHPM-2021.zip`, `EPHPM2022.zip`, `EPHPM2023.zip`, `BASE-DE-DATOS-EPHPM_JUNIO_2024.zip` | fixed source tag `EPHPM` | direct assignment | all |
| `source_program` | provenance key | PRY | `REG02_EPHC_ANUAL_YYYY.(SAV/csv)` | fixed source tag `EPHC` | direct assignment | all |
| `survey_year` | time index | ARG | all active `EPH` waves | `ANO4` | direct assignment | all |
| `survey_year` | time index | HND | all active `EPHPM` waves | derived from filename year | parse filename | all |
| `survey_year` | time index | PRY | all active `EPHC` waves | `AÑO` | direct assignment | all |
| `wave_id` | within-year provenance | ARG | quarterly `EPH` files | quarter parsed from filename | direct assignment | all |
| `wave_id` | within-year provenance | HND | annual files | annual/june release parsed from filename | parse filename | all |
| `wave_id` | within-year provenance | PRY | annual files | `2021` quarterly vs `2022-2024` annual parsed from filename | parse filename | all |
| `household_id_h` | linkage spine | ARG | `usu_hogar_*`, `usu_individual_*` | `CODUSU`, `NRO_HOGAR` | composite key | all |
| `household_id_h` | linkage spine | HND | `Data de la Encuesta de Hogares YYYY_PD.sav` | `HOGAR` | direct key | all |
| `household_id_h` | linkage spine | PRY | `REG01_EPHC_ANUAL_YYYY.(SAV/csv)`, `REG02_EPHC_ANUAL_YYYY.(SAV/csv)` | `UPM`, `NVIVI`, `NHOGA` | composite key | all |
| `person_id_h` | person spine | ARG | `usu_individual_*` | `COMPONENTE` with household key | composite key | all |
| `person_id_h` | person spine | HND | `Data de la Encuesta de Hogares YYYY_PD.sav` | `HOGAR`, `ORDEN` | composite key | all |
| `person_id_h` | person spine | PRY | `REG02_EPHC_ANUAL_YYYY.(SAV/csv)` | `UPM`, `NVIVI`, `NHOGA`, `L02` | composite key | all |
| `age_h` | universe construction | ARG | `usu_individual_*` | `CH06` | direct map | attendance, oos, completion, literacy, repetition, post_secondary_review |
| `age_h` | universe construction | HND | `Data de la Encuesta de Hogares YYYY_PD.sav` | `EDAD` | direct map | attendance, oos, completion, literacy, repetition, post_secondary_review |
| `age_h` | universe construction | PRY | `REG02_EPHC_ANUAL_YYYY.(SAV/csv)` | `P08A` | direct map | attendance, oos, completion, literacy, repetition, post_secondary_review |
| `sex_h` | subgroup/disaggregation | ARG | `usu_individual_*` | `CH04` | direct recode | all household indicators |
| `sex_h` | subgroup/disaggregation | HND | `Data de la Encuesta de Hogares YYYY_PD.sav` | `SEXO` | direct recode | all household indicators |
| `sex_h` | subgroup/disaggregation | PRY | `REG02_EPHC_ANUAL_YYYY.(SAV/csv)` | `P02` | direct recode | all household indicators |
| `location_h` | subgroup/disaggregation | ARG | `usu_hogar_*` / `usu_individual_*` | `MAS_500` | direct recode | all household indicators |
| `location_h` | subgroup/disaggregation | HND | `Data de la Encuesta de Hogares YYYY_PD.sav` | `DOMINIO` | direct recode | all household indicators |
| `location_h` | subgroup/disaggregation | PRY | `REG02_EPHC_ANUAL_YYYY.(SAV/csv)` | `AREA` | direct recode | all household indicators |
| `weight_h` | final expansion factor | ARG | `usu_individual_*` | `PONDERA` | direct map | all estimators |
| `weight_h` | final expansion factor | HND | `Data de la Encuesta de Hogares YYYY_PD.sav` | `FACTOR` | direct map | all estimators |
| `weight_h` | final expansion factor | PRY | `REG02_EPHC_ANUAL_YYYY.(SAV/csv)` | `FEX` or `FEX.2022` by year | coalesce-by-year map with label caveat | all estimators |
| `attending_currently_h` | attendance/OOS numerator input | ARG | `usu_individual_*` | `CH10` | direct binary map | attendance, oos |
| `attending_currently_h` | attendance/OOS numerator input | HND | `Data de la Encuesta de Hogares YYYY_PD.sav` | `ED03` | direct binary map | attendance, oos |
| `attending_currently_h` | attendance/OOS numerator input | PRY | `REG02_EPHC_ANUAL_YYYY.(SAV/csv)` | `ED08` | direct binary map | attendance, oos |
| `current_level_h` | level-specific attendance | ARG | `usu_individual_*` | `NIVEL_ED` + current-status logic | conditional level map | attendance by level, oos by level, post_secondary_review |
| `current_level_h` | level-specific attendance | HND | `Data de la Encuesta de Hogares YYYY_PD.sav` | `ED10` | direct level map | attendance by level, oos by level, post_secondary_review |
| `current_level_h` | level-specific attendance | PRY | `REG02_EPHC_ANUAL_YYYY.(SAV/csv)` | no validated direct current-study level field in active stack | structural missing | attendance by level, oos by level, post_secondary_review |
| `highest_level_completed_h` | completion input | ARG | `usu_individual_*` | `NIVEL_ED` + `ESTADO` | conditional attainment map | completion, post_secondary_review |
| `highest_level_completed_h` | completion input | HND | `Data de la Encuesta de Hogares YYYY_PD.sav` | `ED05` | direct/partial level map | completion, post_secondary_review |
| `highest_level_completed_h` | completion input | PRY | `REG02_EPHC_ANUAL_YYYY.(SAV/csv)` | `ED0504` | split-coded map | completion, post_secondary_review |
| `highest_grade_completed_h` | completion input | ARG | `usu_individual_*` | no validated direct completed-grade field in active stack | structural missing | completion |
| `highest_grade_completed_h` | completion input | HND | `Data de la Encuesta de Hogares YYYY_PD.sav` | `ED08` | direct grade map | completion |
| `highest_grade_completed_h` | completion input | PRY | `REG02_EPHC_ANUAL_YYYY.(SAV/csv)` | `ED0504` | split-coded map | completion |
| `literacy_h` | literacy numerator input | ARG | `usu_individual_*` | no validated direct literacy item in active stack | structural missing | literacy |
| `literacy_h` | literacy numerator input | HND | `Data de la Encuesta de Hogares YYYY_PD.sav` | `ED01` | direct binary map | literacy |
| `literacy_h` | literacy numerator input | PRY | `REG02_EPHC_ANUAL_YYYY.(SAV/csv)` | `ED02` | direct binary map | literacy |
| `repetition_h` | repetition numerator input | ARG | `usu_individual_*` | no validated direct repetition item in active stack | structural missing | repetition |
| `repetition_h` | repetition numerator input | HND | `Data de la Encuesta de Hogares YYYY_PD.sav` | `ED11` | direct binary map | repetition |
| `repetition_h` | repetition numerator input | PRY | `REG02_EPHC_ANUAL_YYYY.(SAV/csv)` | no validated direct repetition item in active stack | structural missing | repetition |
| `exception_flag` | comparability state | ARG/HND/PRY | derived | derived from classifier | derived QA field | all publishable household indicators |
| `exception_note` | human-readable caveat | ARG/HND/PRY | derived | derived from classifier | derived QA field | all publishable household indicators |

## 5. Comparability Classifier

This classifier is the key deployable method. It is not named this way in a single UIS sentence, but it is the direct operationalization of UIS rules on comparability, denominator integrity, and construct equivalence: [UIS Handbook](https://tcg.uis.unesco.org/wp-content/uploads/sites/4/2025/02/EDSC11_4.1_Household-Survey-Handbook.pdf), [UIS Position Paper](https://tcg.uis.unesco.org/wp-content/uploads/sites/4/2023/10/HHS_position_paper_2023.touse_.pdf), [UIS Guide](https://uis.unesco.org/sites/default/files/documents/guide-to-the-analysis-and-use-of-household-survey-and-census-education-data-en_0.pdf).

For each source variable $x_{s,v}$ and target harmonized variable $z_v$, assign one class:

### 5.1 Directly harmonizable
Assign `directly_harmonizable` if all conditions hold:
1. construct equivalence: the item asks the same substantive question as the target indicator input;
2. population equivalence: the item is observed on the same eligible population used by the indicator universe;
3. coding equivalence: no substantive category collapse is needed;
4. temporal equivalence: reference period is compatible with the indicator definition.

Example:
- `Honduras ED03` (“¿Asiste actualmente...?”) -> `attending_currently_h`
- `Paraguay ED08` (“Asiste actualmente...”) -> `attending_currently_h`
- both are direct candidate inputs for current attendance, subject to normal code mapping and valid universe declaration.

### 5.2 Partially harmonizable
Assign `partially_harmonizable` if the construct is usable but one or more controlled transformations are required:
1. level crosswalk or system alignment is needed;
2. grade/year must be combined with level to define completion;
3. a category collapse is required but does not destroy cross-country meaning;
4. wording is close enough for use but requires an explicit exception note.

Example:
- `Argentina NIVEL_ED` plus status/attendance fields may support `current_level_h` and `highest_level_completed_h`, but only after mapping national labels to a common ladder and explicitly recording level collapse if needed.
- `Paraguay ED0504` (“Nivel y grado aprobado”) supports completion, but only after splitting level and grade and documenting the rule.

### 5.3 Non-comparable
Assign `non_comparable` if any of the following hold:
1. the source item does not represent the target construct;
2. the eligible population differs materially from the published UIS denominator;
3. reference period changes the meaning;
4. coding or wording prevents a defensible common mapping.

Example:
- a historical attendance item with a different reference year or retrospective status that does not correspond to current attendance for the published indicator should not enter `attending_currently_h`.

## 6. Variable-Family Harmonization Rules

### 6.1 Demographic and design variables

**Rule**
- `age_h` must be integer age in completed years.
- `sex_h` must be recoded to a standard two-category code only if the source actually supports that coding without ambiguity.
- `location_h` must preserve the public urban/rural or equivalent residence classification used in disaggregation on WIDE pages.
- `weight_h` must be the final person-level weight, never a household weight unless the source is person-level only and the documentation confirms it.
- observed design/disaggregation fields may be carried into metadata even where the public stack audit has not yet validated a full PSU/strata pair; no unverified design field may be promoted into estimation code.
- in the current demo contract, only design/disaggregation fields directly observed in the active stack are registered: `AGLOMERADO` and `MAS_500` for Argentina, `DOMINIO` for Honduras, and `AREA` for Paraguay. No claim of a complete PSU/strata pair is made unless the field was directly verified in the acquired files and manifests.

**Application**
- Argentina: `CH06 -> age_h`, `CH04 -> sex_h`, `MAS_500 -> location_h`, `PONDERA -> weight_h`.
- Argentina: observed household/publication design fields in the stack are `AGLOMERADO` and `MAS_500`; the demo carries `AGLOMERADO` as source metadata and `MAS_500 -> location_h`.
- Honduras: `EDAD -> age_h`, `SEXO -> sex_h`, `DOMINIO -> location_h`, `FACTOR -> weight_h`.
- Honduras: no additional survey-design field beyond the observed `DOMINIO` variable is promoted into the current demo contract.
- Paraguay: `P08A -> age_h`, `P02 -> sex_h`, `AREA -> location_h`, `FEX.2022 -> weight_h` in the public 2024 CSV evidence.
- Paraguay: no further survey-design field is promoted into the current demo contract until `.SAV` metadata confirms a stable design variable beyond `AREA`.

**Inline basis**
- Denominator and disaggregation integrity are explicit requirements in the [UIS Handbook](https://tcg.uis.unesco.org/wp-content/uploads/sites/4/2025/02/EDSC11_4.1_Household-Survey-Handbook.pdf) and the [UIS Code of Practice](https://uis.unesco.org/sites/default/files/documents/code-practice-household-survey-2017-en.pdf).

### 6.2 Current attendance

**Target variable**
- `attending_currently_h ∈ {0,1,NA}`

**Rule**
- Set `1` if the respondent is currently attending an educational institution under the source wording.
- Set `0` if the respondent is in the questionnaire universe and explicitly reports not attending.
- Set `NA` if the source item is structurally absent or outside the eligible questionnaire skip pattern.

**Application**
- Honduras: `ED03` is the direct current-attendance item; `ED02` (matriculated) can be retained as auxiliary metadata but not substituted for attendance without explicit justification.
- Paraguay: `ED08` is the direct current-attendance item; `ED03` is prior/ever attendance and must not be substituted for current attendance.
- Argentina: `CH10` is the direct EPH attendance question (CH10=1: currently attends school; CH10≠1: does not attend); this maps directly to `attending_currently_h` without additional status/level logic required.

**Inline basis**
- Attendance indicators must be aligned to the source wording and official age universe: [UIS Glossary: Total net attendance rate](https://tcg.uis.unesco.org/wp-content/uploads/sites/4/2023/03/Glossary_education_March2023DR-edited.pdf), [UIS indicator-calculation report](https://tcg.uis.unesco.org/wp-content/uploads/sites/4/2024/02/Calculation-of-education-indicators_HHS_Report-UNESCO-UIS-13122023.pdf).

### 6.3 Current educational level

**Target variable**
- `current_level_h`

**Rule**
- derive only from current attendance/current study block, not from highest completed level;
- map source categories to a common ladder used by the demo (`pre-primary`, `primary`, `lower_secondary`, `upper_secondary`, `tertiary_or_more`, `unknown`);
- every country-specific label collapse must appear in `crosswalk.csv`.

**Application**
- Honduras: `ED10` is the explicit current level field.
- Paraguay: derive from current attendance block and current level/grade fields where available in `REG02`; if grade-only information appears, level must be inferred only when the coding scheme is documented.
- Argentina: derive from `NIVEL_ED` only when combined with current-status logic; do not equate `NIVEL_ED` automatically with completion.

**Inline basis**
- UIS requires careful mapping of national education structure before using household data in level-specific indicators: [UIS Guide](https://uis.unesco.org/sites/default/files/documents/guide-to-the-analysis-and-use-of-household-survey-and-census-education-data-en_0.pdf), [UIS Handbook](https://tcg.uis.unesco.org/wp-content/uploads/sites/4/2025/02/EDSC11_4.1_Household-Survey-Handbook.pdf).

### 6.4 Highest level completed and highest grade completed

**Target variables**
- `highest_level_completed_h`
- `highest_grade_completed_h`

**Rule**
- derive from the source item that explicitly captures highest level attained or highest grade approved;
- separate level and grade when they are jointly coded;
- mark `partially_harmonizable` whenever a country-specific split is required.

**Application**
- Honduras: `ED05` (highest level reached) + `ED08` (último grado aprobado) form the completion block.
- Paraguay: `ED0504` is explicitly a combined level/grade-approved field and therefore requires split logic before entering the harmonized schema.
- Argentina: `NIVEL_ED` may provide a current/attained ladder, but completion still requires a defensible rule using state/status fields. That rule must be wave-stable and explicitly logged.

**Inline basis**
- Completion indicators require age-specific reference universes and defensible level attainment variables: [UIS Glossary: Completion rate](https://tcg.uis.unesco.org/wp-content/uploads/sites/4/2023/03/Glossary_education_March2023DR-edited.pdf), [VIEW completion](https://www.unesco.org/gem-report/en/view/completion), [UIS indicator-calculation report](https://tcg.uis.unesco.org/wp-content/uploads/sites/4/2024/02/Calculation-of-education-indicators_HHS_Report-UNESCO-UIS-13122023.pdf).

### 6.5 Literacy

**Target variable**
- `literacy_h`

**Rule**
- literacy enters the harmonized file only if the source asks a direct literacy item consistent with UIS literacy reporting;
- otherwise `literacy_h=NA` and the variable is excluded from publication for that source-year.

**Application**
- Honduras: `ED01` is a direct literacy item and is admissible.
- Paraguay: `ED02` is a direct literacy item and is admissible.
- Argentina: no direct literacy item is currently documented in the active EPH stack evidence used here; therefore `literacy_h` remains structurally missing unless a validated literacy variable is detected during source registration.

**Inline basis**
- Literacy indicators must follow the exact source question and target universe: [UIS Glossary: Literacy rate](https://tcg.uis.unesco.org/wp-content/uploads/sites/4/2023/03/Glossary_education_March2023DR-edited.pdf), [UIS Handbook](https://tcg.uis.unesco.org/wp-content/uploads/sites/4/2025/02/EDSC11_4.1_Household-Survey-Handbook.pdf).

### 6.6 Repetition

**Target variable**
- `repetition_h`

**Rule**
- repetition is included only where a direct repeating-year question exists;
- do not infer repetition from age-grade mismatch.

**Application**
- Honduras: `ED11` is a direct repetition item and is admissible.
- Paraguay and Argentina: unless a direct repetition item is identified in the registered source block, repetition remains out of scope.

**Inline basis**
- Repetition and similar education-flow variables must not be inferred when a direct source variable is absent; this follows the UIS comparability discipline in the household-survey guidance: [UIS Position Paper](https://tcg.uis.unesco.org/wp-content/uploads/sites/4/2023/10/HHS_position_paper_2023.touse_.pdf), [UIS Code of Practice](https://uis.unesco.org/sites/default/files/documents/code-practice-household-survey-2017-en.pdf).

## 7. Crosswalk and Exception Log

### 7.1 Crosswalk contract

Every raw variable used in the harmonized layer must appear in `crosswalk.csv` with this minimum schema:

| country_code | survey_year | raw_file | raw_variable | raw_label | harmonized_variable | rule_type | rule_expression | comparability_class | information_loss | citation_link |
|---|---:|---|---|---|---|---|---|---|---|---|

Example rows:
- `HND,2024,Data de la Encuesta de Hogares 2024_PD.sav,ED03,"¿Asiste actualmente...?",attending_currently_h,direct_binary,"ED03 in {si}=1; ED03 in {no}=0",directly_harmonizable,none,<UIS glossary link>`
- `PRY,2024,REG02_EPHC_ANUAL_2024.csv,ED0504,"Nivel y grado aprobado",highest_level_completed_h,split_coded,"split level and grade by documented codebook",partially_harmonizable,level-grade collapse risk,<UIS completion glossary link>`
- `ARG,2024,usu_individual_T124.txt,NIVEL_ED,"nivel educativo",current_level_h,conditional_map,"use NIVEL_ED only when current attendance/status supports current study",partially_harmonizable,current/completed ambiguity,<UIS handbook link>`

### 7.2 Exception log contract

Every lossy or caveated transformation must appear in `exception_log.csv`:

| country_code | survey_year | raw_variable | harmonized_variable | exception_type | reason | action | publication_impact |
|---|---:|---|---|---|---|---|---|

Example rows:
- `ARG,2024,NIVEL_ED,current_level_h,construct_ambiguity,"source level item is not purely current-study level",conditional mapping applied,"publish with metadata note"`
- `PRY,2024,ED0504,highest_level_completed_h,combined_code_split,"level and grade stored in same field",split using documented coding,"publish if split verified"`
- `HND,2024,ED02,attending_currently_h,auxiliary_only,"matriculation is not equivalent to attendance",retain as auxiliary only,"not used in numerator"`

## 8. Country-by-Country Implementation Order

### Argentina
1. register each quarter separately;
2. read `usu_individual_*` as person file and `usu_hogar_*` as household support;
3. build person and household keys from `CODUSU`, `NRO_HOGAR`, `COMPONENTE`;
4. harmonize `CH04`, `CH06`, `MAS_500`, `PONDERA` directly;
5. map `CH10 -> attending_currently_h` (binary: 1=attends, other=does not attend); derive completion from `NIVEL_ED` under explicit crosswalk rules;
6. set `literacy_h=NA` unless a validated direct literacy item is identified.

### Honduras
1. register annual/june releases separately;
2. read the SPSS person file directly;
3. harmonize `SEXO`, `EDAD`, `DOMINIO` directly;
4. map `ED03 -> attending_currently_h`;
5. map `ED10 -> current_level_h`;
6. map `ED05 + ED08 -> highest_level_completed_h/highest_grade_completed_h`;
7. map `ED01 -> literacy_h` and `ED11 -> repetition_h`;
8. keep `ED02` and `ED15`-`ED20` as auxiliary education-history metadata.

### Paraguay
1. register annual files `INGREFAM`, `REG01`, `REG02`, using `REG02` as the person file;
2. harmonize residence and person roster variables from the person/household keys;
3. map `ED08 -> attending_currently_h`;
4. map `ED0504 -> highest_level_completed_h/highest_grade_completed_h` through a documented split rule;
5. map `ED02 -> literacy_h`;
6. retain `ED03` as prior/ever attendance context, not current attendance.

## 9. Deliverables Required in the Repo

The harmonization layer is not complete unless the repo exposes:
- `data/staging/<country>/<year>/source_registration.csv`
- `data/staging/<country>/<year>/crosswalk.csv`
- `data/staging/<country>/<year>/exception_log.csv`
- `data/harmonized/<country>/<year>/persons_harmonized.parquet`
- `docs/methods/harmonization/<country>_<year>.md`

## 10. Acceptance Criteria

`02_harmonize` is complete only if:
1. every source-year in the recent canonical stack has a registration row;
2. every harmonized field is traceable to raw variables through `crosswalk.csv`;
3. every lossy transformation is recorded in `exception_log.csv`;
4. every country-year file preserves source-year provenance;
5. the harmonized file is sufficient to reproduce the indicator universes used in `03_indicators`.

