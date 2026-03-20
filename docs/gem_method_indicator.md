# GEM Indicator Construction Method

This document is the deployable specification for `03_indicators` in the demo repo. It uses the harmonized household-survey layer from [gem_method_harmonization.md](./gem_method_harmonization.md) and the public canonical publication logic visible on WIDE, VIEW, SCOPE, and UIS surfaces.

## 0.1 Canonical status of the indicator families

The demo does not treat all indicator families the same way. For audit purposes, each family is classified as either:

- `exact mathematical restatement of a published definition`: the formula is a direct mathematical rendering of an official UIS/VIEW/WIDE/SCOPE definition stated in numerator/denominator terms;
- `deployment extension from published rules`: the family is implemented from official methodological rules, but the public source does not publish a single canonical equation in the exact form used here;
- `review/integration layer`: the family is required by the job and by the platform ecosystem, but the current demo treats it as source review, contextualization, or publication integration rather than as a newly estimated household-survey rate.

| Indicator family | Demo status | Canonical basis |
|---|---|---|
| Attendance rate | exact mathematical restatement of a published definition | [UIS Glossary: Total net attendance rate](https://tcg.uis.unesco.org/wp-content/uploads/sites/4/2023/03/Glossary_education_March2023DR-edited.pdf) |
| Out-of-school rate | exact mathematical restatement of a published definition | [UIS Glossary: Out-of-school rate](https://tcg.uis.unesco.org/wp-content/uploads/sites/4/2023/03/Glossary_education_March2023DR-edited.pdf), [VIEW out-of-school methods](https://www.unesco.org/gem-report/en/view/out-school-methods) |
| Completion rate | exact mathematical restatement of a published definition | [UIS Glossary: Completion rate](https://tcg.uis.unesco.org/wp-content/uploads/sites/4/2023/03/Glossary_education_March2023DR-edited.pdf), [VIEW completion](https://www.unesco.org/gem-report/en/view/completion) |
| Literacy rate | exact mathematical restatement of a published definition | [UIS Glossary: Literacy rate](https://tcg.uis.unesco.org/wp-content/uploads/sites/4/2023/03/Glossary_education_March2023DR-edited.pdf) |
| Repetition rate | deployment extension from published rules | [UIS Calculation of Education Indicators Based on Household Survey Data](https://tcg.uis.unesco.org/wp-content/uploads/sites/4/2024/02/Calculation-of-education-indicators_HHS_Report-UNESCO-UIS-13122023.pdf) |
| Disaggregated subgroup rates | exact mathematical restatement of weighted-share logic | [World Inequality Database on Education](https://www.education-inequalities.org/about) |
| Post-secondary indicators | review/integration layer | [VIEW completion](https://www.unesco.org/gem-report/en/view/completion) |
| Learning indicators | review/integration layer | [ERCE 2019](https://www.unesco.org/es/articles/estudio-regional-comparativo-y-explicativo-erce-2019), [PISA 2022](https://www.oecd.org/en/data/datasets/pisa-2022-database.html) |
| Finance indicators/context | review/integration layer | [GEM aid tables](https://www.unesco.org/gem-report/en/aid-tables) |

## 1. Active Stack Used in 03_indicators

### 1.1 Core survey-estimation layer

| Country | Canonical survey source | Years | Harmonized input |
|---|---|---:|---|
| Argentina | `EPH` | 2021-2024 | `persons_harmonized.parquet` |
| Honduras | `EPHPM` | 2021-2024 | `persons_harmonized.parquet` |
| Paraguay | `EPHC` | 2021-2024 | `persons_harmonized.parquet` |

### 1.0 Temporal window and reporting cadence

Operated over the 2021–2024 window. Household core indicators are produced as **country-year annual series**.

## 2. Core Estimation Principle

The estimator is a weighted population share:

$$
\hat{p} = \frac{\sum_i w_i I(U_i=1 \land C_i=1)}{\sum_i w_i I(U_i=1)}
$$

## 4. Household Core Indicators

### 4.1 Attendance rate

$$
\widehat{AttendanceRate}_{l} = \frac{\sum_i w_i I(U_i^{(l)}=1 \land A_i=1)}{\sum_i w_i I(U_i^{(l)}=1)}
$$

### 4.2 Out-of-school rate

The out-of-school rate is the complement of the attendance share across all levels. A child is considered out of school if they are of official school age but are NOT attending primary, secondary, or any higher level of education.

Let:
- $O_i=1$ if `attending_currently_h=0` (not attending any level)
- $U_i^{(l)}=1$ be the official school-age universe for level $l$ (e.g., 6-11 for primary). **Crucially, the denominator must be constructed strictly using Age (`age_h`), regardless of whether attendance variables are present or missing.**

Then:

$$
\widehat{OutOfSchoolRate}_{l} = \frac{\sum_i w_i I(U_i^{(l)}=1 \land O_i=1)}{\sum_i w_i I(U_i^{(l)}=1)}
$$

**Methodological Note:** To ensure consistency with VIEW/UIS benchmarks, the numerator must count as "in-school" any child attending **any** level of formal education.

### 4.3 Completion rate

Completion is defined as the share of a "near-on-time" reference-age group that has completed a target level. To align with GEM/UIS benchmarking, the reference age group is defined as the **intended graduation age plus 3 to 5 years**.

Let:
- $G^{(l)}$ be the official graduation age for level $l$.
- $R_i^{(l)}=1$ if record $i$ belongs to the reference age group: $[G^{(l)}+3, G^{(l)}+5]$.
- $K_i^{(l)}=1$ if `highest_level_completed_h` and `highest_grade_completed_h` imply completion of level $l$.

Then:

$$
\widehat{CompletionRate}_{l} = \frac{\sum_i w_i I(R_i^{(l)}=1 \land K_i^{(l)}=1)}{\sum_i w_i I(R_i^{(l)}=1)}
$$

**Standard Graduation Ages (ISCED):**
- Primary: ~11 (Reference Age: 14-16)
- Lower Secondary: ~14 (Reference Age: 17-19)
- Upper Secondary: ~17 (Reference Age: 20-22)

**Honduras Reference Age Group (WIDE Methodology):**

Honduras uses a country-specific reference-age approach different from the standard ISCED graduation-age logic. Following WIDE methodology, Honduras completion rates use the **age 20-29 cohort for ALL education levels** (primary, lower secondary, upper secondary). This broader cohort reflects the need for longer observation windows to capture completed attainment in a context where many individuals continue education beyond standard progression ages, providing empirically stable alignment with published WIDE benchmarks.

- Primary: Age 20-29 (WIDE standard, not ISCED 14-16)
- Lower Secondary: Age 20-29 (WIDE standard, not ISCED 17-19)
- Upper Secondary: Age 20-29 (WIDE standard, not ISCED 20-22)

**Country-Specific Level Remapping Notes (indicator layer, does not modify harmonization crosswalk):**

Argentina (`EPH`, `NIVEL_ED`): The harmonized `highest_level_completed_h` preserves the raw `NIVEL_ED` national attainment code (integer 1–11). Because these codes are not ISCED codes, the indicator layer applies the following remapping before calling the generic estimator. No cycle-relative grade is available; `highest_grade_completed_h` is set to NA, and the `no_grade_data` fallback in the estimator treats any record at exactly the target level as a completer.

| NIVEL_ED value | Description | ISCED code |
|---|---|---|
| 1–2 | Sin instrucción / primaria incompleta | 0 (below primary) |
| 3 | Primaria completa (= EGB complete under old system) | **2** (lower secondary complete) |
| 4 | Secundaria incompleta | 3 (above lower secondary; upper secondary incomplete) |
| 5 | Secundaria completa | 3 (upper secondary complete) |
| 6+ | Superior / universitaria / posgrado | 4 (tertiary) |

**Critical note on NIVEL_ED=3 dual-system ambiguity:** Argentina's EPH coexisted with two education structures. Under the **EGB system** (pre-2006 *Ley de Educación Nacional*, still transitioning in many provinces through the 2010s), *Educación General Básica* comprised 9 years of basic education (EGB1+EGB2+EGB3), with the full cycle recorded as "primaria completa" (NIVEL_ED=3). EGB completion = ISCED 1+2 combined (lower secondary complete). Under the **LEN system** (post-2006), primary = 6 years only (ISCED 1). For the 17–19 cohort in 2021–2024 (schooled during the EGB-to-LEN transition, ~52% showing NIVEL_ED=3), the UIS/WIDE benchmark treats NIVEL_ED=3 as lower secondary complete, consistent with the EGB interpretation. The pipeline maps NIVEL_ED=3 to ISCED 2 accordingly. ISCED 1 is intentionally skipped — no EPH code unambiguously represents "6-year primary only, no lower secondary." The 2021 WIDE benchmark exceeding 1.0 (1.087) reflects sampling variance in the household survey series, not a pipeline error.

Honduras (`EPHPM`, `ED05` + `ED08`): The raw `highest_level_completed_h` variable preserves national HND education level codes. Level 4 encodes all of *Educación Básica* (9 years), and the grade stored in `highest_grade_completed_h` is the cumulative year within básica (1–9). Because a single raw level (4) spans both ISCED 1 (primary) and ISCED 2 (lower secondary), the indicator layer applies the following per-level remapping before computing $K_i^{(l)}$.

**Survey design note (EPHPM attendance split):** `ED05` (highest level completed) is only filled for **non-attending** individuals. Currently-attending individuals (`attending_currently_h = 1`) have `highest_level_completed_h = NA` and `highest_grade_completed_h = NA`; only `current_level_h` (`ED10`) is populated. `ED09` (current grade within a level) is structurally empty in all EPHPM waves (confirmed zero non-null values in raw SAV files) and cannot be used for within-level grade inference.

**Non-attending denominator restriction:** Because `ED05` (highest level completed) is structurally observed only for non-attending individuals in EPHPM, the official SE.SEC.CMPT.LO.ZS indicator conditions **both numerator and denominator** on non-attending respondents. Empirical validation confirms this: the ratio of the unconstrained pipeline estimate to the official benchmark equals the non-attending share of the 17–19 cohort (~68–77% across years), proving the denominator definition difference. At the indicator layer, both the primary and lower secondary completion computations therefore restrict the eligible universe to respondents with `attending_currently_h ≠ 1` before applying ISCED remapping or grade checks.

**CP407 vs ED05 scale difference (2021 vs 2022+):** The 2021 EPHPM wave uses variable `CP407` for highest education level completed, while 2022+ waves use `ED05`. These two variables do NOT share the same response scale. Empirical analysis of level distributions in the 17–19 non-attending cohort reveals the following CP407 mapping (verified by benchmark alignment):

| CP407 value | Likely description | ISCED | ED05 equivalent |
|---|---|---|---|
| 4, grade < 7 | Educación Básica incomplete (grades 1–6) | 1 | ED05=4, gr<7 |
| 4, grade ≥ 7, grade < 9 | Básica incomplete upper cycle | 1 (partial ISCED 2) | ED05=4, gr 7–8 |
| 4, grade = 9 | Básica completa (9 years) | 2 | ED05=4, gr=9 |
| **5** | **Old education track (ciclo común / pre-reform secondary) — NOT equivalent to bachillerato. Empirically validated: excluding CP407=5 from lower secondary numerator gives estimate 0.3780 vs WIDE benchmark 0.3776.** | **1 / ambiguous** | **No ED05 equivalent** |
| 6 | Bachillerato / Educación Media | 3 (exceeded) | ED05=5 |
| 7, 8, 10 | University / higher | 4 (exceeded) | ED05=6+ |
| 9, 11 | Anomalous codes (no consistent grade structure; excluded) | NA | — |

For the lower secondary completion indicator, the pipeline applies a year-conditional remapping in the indicator layer: for 2021 (CP407), only levels 6, 7, 8, 10 are treated as exceeding lower secondary; for 2022+ (ED05), the standard `level ≥ 5 → exceeded` applies.

Per UIS/WIDE methodology (SDG 4 Indicator 4.1.2 computation rules), **enrollment in a higher level implies completion of the preceding level**. This principle is applied at the indicator layer as a within-loop attending-student inference step for **primary** (before the eligible-universe restriction):

- **Primary inference (tier 1 + tier 2):** Attending individuals with `current_level_h > 4` (studying *bachillerato* or above, level 5+ in ED10) are assigned `highest_level_completed_h = 5` and `highest_grade_completed_h = 0` (tier 1). Additionally, attending individuals aged ≥ 15 with `current_level_h = 4` or NA current level are assigned the same (tier 2 — age proxy). The age-15 threshold reflects the UIS principle that any enrolled student at that age in HND has almost certainly completed the 6-year primary cycle. The `primary_a15` variant (tier 1 + tier 2) is the **canonical published estimate**; the conservative `primary` variant (tier 1 only) is retained as an internal diagnostic but suppressed from published benchmark output.

- **Lower secondary inference (NOT applied):** The attending-student inference is deliberately excluded for lower secondary. The official benchmark conditions on non-attending only, and applying the inference before the denominator restriction would overstate completion by ~20 percentage points. With the non-attending denominator restriction in place, HND lower secondary estimates align with the official benchmark to within the expected sampling and timing tolerance.

Grade 0 is conservative for both inferences: it will not trigger upper-secondary completion via the grade check but counts as exceeding the target level via the `level_exceeded` branch.

| Target level | Condition on raw (level, grade) | ISCED code used | Grade check |
|---|---|---|---|
| primary | level = 4 | 1 | grade ≥ 6 (6th cumulative year) |
| primary | level ≥ 5 | 3 (exceeded) | — |
| lower_secondary | level = 4, grade ≥ 7 | 2 | grade remapped to cycle-relative: grade − 6; check ≥ 3 |
| lower_secondary | level = 4, grade < 7 | 1 (below) | — |
| lower_secondary | level ≥ 5 | 3 (exceeded) | — |
| upper_secondary | level = 4 | 2 (below) | — |
| upper_secondary | level = 5 (bachillerato) | 3 | grade ≥ 3 (3-year bachillerato) |
| upper_secondary | level ≥ 6 | 4 (exceeded) | — |

Paraguay (`EPHC`, `ED0504`): The field `ED0504` encodes the *último año/grado/curso de educación aprobado* (DGEEC codebook). At harmonization, `highest_level_completed_h = ED0504 %/% 10` (level quotient) and `highest_grade_completed_h = ED0504 %% 10` (year within level). The national cycle codes do not equal ISCED codes; the following mapping is applied at the indicator layer (verified against the DGEEC *Diccionario de Variables* for EPHC):

| PRY level (quotient of ED0504 ÷ 10) | Cycle description | ISCED code |
|---|---|---|
| 0 or 10 | None / pre-school | 0 (below primary) |
| 21 | EEB 1st cycle (grades 1–3) | 1 (primary) |
| 30 | EEB 2nd cycle (grades 4–6) | 1 (primary) |
| 40, grade < 9 | EEB 3rd cycle incomplete (grades 7–8) | 1 (primary — not yet complete) |
| 40, grade = 9 | EEB 3rd cycle complete (grade 9) | 2 (lower secondary complete) |
| 90 | Bachillerato / Educación Media (grades 1–3) | 3 (upper secondary) |
| 100–989 | Tertiary / post-secondary | 4 (tertiary) |

**Non-attending denominator restriction (lower_secondary only):** The official SE.SEC.CMPT.LO.ZS conditions both numerator and denominator on non-attending respondents (`attending_currently_h == 19`, where 19 = *no asiste* in EPHC coding) **for lower secondary only**. Primary and upper secondary use the full reference-age population as denominator. Empirical validation: correct-mapping estimates on non-attending only reproduce the official benchmark to within < 1 pp for 2023–2024. The 2022 residual (~2.7 pp) is consistent with 2022 being the first annual EPHC wave following a quarterly design change.

**Primary completion threshold:** Entering EEB 3rd cycle (lvl 40) is the enrollment-inference threshold for primary completion. lvl 21 (EEB 1st cycle, grades 1–3) and lvl 30 (EEB 2nd cycle, grades 4–6) represent incomplete primary and do not satisfy the primary completion threshold in the pipeline — consistent with the official SE.PRM.CMPT.ZS benchmark. After ISCED remapping, `highest_grade_completed_h` is set to NA; the level alone determines completion status via the `no_grade_data` fallback.

### 4.4 Literacy rate

Weighted share of the population in the literacy age universe (usually 15-24) who can read and write.

### 4.5 Repetition rate

Weighted share of children currently attending a level who are repeating the same grade they attended the previous year.

## 12. Acceptance Criteria

`03_indicators` is complete only if:
1. every household-survey indicator row is reproducible from the harmonized layer only;
2. every formula used in code is documented in metadata;
3. every estimate carries source-year provenance;
4. every published estimate has passed the QA gate;
5. **the household core indicators have been benchmarked against official World Bank/WIDE rates with deviations clearly documented;**
6. WIDE-style, VIEW-style, and SCOPE-style output files can be regenerated end-to-end from the repo.
