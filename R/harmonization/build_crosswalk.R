suppressPackageStartupMessages({
  library(data.table)
})

source(file.path(getwd(), "R", "utils", "paths.R"))
source(file.path(getwd(), "R", "acquisition", "build_source_registry.R"))

schema_vars_for_source <- function(source_id, registry) {
  row <- registry[source_id == ..source_id]
  if (nrow(row) != 1L) {
    stop("Expected exactly one source_registry row for source_id=", source_id)
  }
  sig <- row$schema_signature[[1]]
  if (is.na(sig) || !nzchar(sig)) character() else strsplit(sig, "|", fixed = TRUE)[[1]]
}

arg_rows <- function(source_id, year, period) {
  data.table(
    source_id = source_id,
    country_code = "ARG",
    source_program = "EPH",
    source_year = year,
    source_period = period,
    harmonized_variable = c(
      "country_code","source_program","survey_year","wave_id","household_id_h","person_id_h","weight_h",
      "age_h","sex_h","location_h","attending_currently_h","current_level_h",
      "highest_level_completed_h","highest_grade_completed_h","literacy_h","repetition_h",
      "ch12_raw","ch13_raw","ch14_raw"
    ),
    source_file_group = "usu_individual_T*.txt;usu_hogar_T*.txt",
    raw_variable = c(
      "constant('ARG')","constant('EPH')","ANO4","TRIMESTRE","CODUSU+NRO_HOGAR","CODUSU+NRO_HOGAR+COMPONENTE","PONDERA",
      "CH06","CH04","MAS_500","CH10","CH08","NIVEL_ED","structural_missing","structural_missing","structural_missing",
      "CH12","CH13","CH14"
    ),
    rule_type = c(
      "constant","constant","direct_copy","direct_copy","identity_concat","identity_concat","direct_copy",
      "direct_copy","recode_binary","recode_location","rule_based_attendance","recode_level",
      "recode_completion_level","structural_missing","structural_missing","structural_missing",
      "direct_copy","direct_copy","direct_copy"
    ),
    required_for_indicator_family = c(
      "all","all","all","all","all","all","all",
      "household_core","household_core","household_core","attendance_oos","attendance_completion_postsecondary",
      "completion_postsecondary","completion","literacy","repetition",
      "completion_postsecondary","completion_postsecondary","completion_postsecondary"
    ),
    notes = c(
      "Set to ARG","Set to EPH","Observed annual field","Observed quarter field",
      "Within-source household key","Within-source person key","Verified expansion factor","Completed years of age",
      "Male/Female publication coding","Closest verified publication geography",
      "Direct mapping of CH10 attendance question: 1=currently attending, other values=not attending",
      "Current level attended (CH08)","Highest completed level",
      "No direct grade-completed field verified in active ARG stack",
      "No direct literacy field verified in active ARG stack",
      "No direct repetition field verified in active ARG stack",
      "Raw: highest level attended (CH12 diagnostic for Argentina ISCED mapping)","Raw: completion status of attended level (CH13 diagnostic)","Raw: last approved grade (CH14 diagnostic for Argentina ISCED mapping)"
    )
  )
}

hnd_rows <- function(source_id, year) {
  is_2021 <- identical(year, 2021L)
  household_id <- if (is_2021) "num_rec+num_hog" else if (identical(year, 2023L)) "ID" else "HOGAR"
  person_id <- if (is_2021) "num_rec+num_hog+Nper" else if (identical(year, 2022L)) "HOGAR+NPER" else if (identical(year, 2023L)) "ID+ORDEN" else "HOGAR+ORDEN"
  sex_var <- if (is_2021) "C03" else "SEXO"
  domain_var <- if (is_2021) "dominio" else "DOMINIO"
  age_var <- "EDAD"
  attend_var <- if (is_2021) "CP405" else "ED03"
  level_now_var <- if (is_2021) "structural_missing" else "ED10"
  level_comp_var <- if (is_2021) "CP407" else "ED05"
  grade_comp_var <- if (is_2021) "CP410" else "ED08"
  literacy_var <- if (is_2021) "P403" else "ED01"
  repetition_var <- if (is_2021) "structural_missing" else "ED11"

  data.table(
    source_id = source_id,
    country_code = "HND",
    source_program = "EPHPM",
    source_year = year,
    source_period = "annual_or_june_release",
    harmonized_variable = c(
      "country_code","source_program","survey_year","wave_id","household_id_h","person_id_h","weight_h",
      "age_h","sex_h","location_h","attending_currently_h","current_level_h",
      "highest_level_completed_h","highest_grade_completed_h","literacy_h","repetition_h"
    ),
    source_file_group = "*.sav",
    raw_variable = c(
      "constant('HND')","constant('EPHPM')","derived_from_filename_year","derived_from_filename_period",
      household_id, person_id, "FACTOR",
      age_var, sex_var, domain_var, attend_var, level_now_var,
      level_comp_var, grade_comp_var, literacy_var, repetition_var
    ),
    rule_type = c(
      "constant","constant","parse_filename","parse_filename","identity_concat","identity_concat","direct_copy",
      "direct_copy","recode_binary","recode_location","direct_copy",
      if (is_2021) "structural_missing" else "direct_copy",
      "recode_completion_level","direct_copy","recode_binary",
      if (is_2021) "structural_missing" else "direct_copy"
    ),
    required_for_indicator_family = c(
      "all","all","all","all","all","all","all",
      "household_core","household_core","household_core","attendance_oos","attendance_completion_postsecondary",
      "completion_postsecondary","completion","literacy","repetition"
    ),
    notes = c(
      "Set to HND","Set to EPHPM","No survey-year variable observed; use filename year","Annual/june release from filename",
      "Verified household identifier","Verified person identifier","Verified expansion factor","Completed years of age",
      "Male/Female publication coding","Verified public disaggregation field",
      if (is_2021) "CP405 = currently attends an educational center" else "ED03 = currently attends an educational center or virtual modality",
      if (is_2021) "No current study level field verified in 2021 EPHPM" else "ED10 = current level studying",
      if (is_2021) "CP407 = highest educational level reached" else "ED05 = highest educational level reached",
      if (is_2021) "CP410 = last approved grade/year" else "ED08 = last approved grade/year",
      if (is_2021) "P403 = can read and write" else "ED01 = can read and write",
      if (is_2021) "No repetition field verified in 2021 EPHPM" else "ED11 = repeating year"
    )
  )
}

pry_rows <- function(source_id, year) {
  year_field <- if (identical(year, 2021L)) "derived_from_filename_year" else "AÑO"
  weight_var <- if (identical(year, 2021L)) "FEX" else "FEX.2022"
  weight_note <- if (identical(year, 2021L)) {
    "Factor de expansion field verified as FEX in 2021"
  } else {
    "Factor de diseno field verified as FEX.2022 in 2022-2024"
  }
  data.table(
    source_id = source_id,
    country_code = "PRY",
    source_program = "EPHC",
    source_year = year,
    source_period = if (identical(year, 2021L)) "quarterly" else "annual",
    harmonized_variable = c(
      "country_code","source_program","survey_year","wave_id","household_id_h","person_id_h","weight_h",
      "age_h","sex_h","location_h","attending_currently_h","current_level_h",
      "highest_level_completed_h","highest_grade_completed_h","literacy_h","repetition_h"
    ),
    source_file_group = "REG02_EPHC*.SAV|REG02_EPHC*.csv",
    raw_variable = c(
      "constant('PRY')","constant('EPHC')",year_field,"derived_from_filename_period",
      "UPM+NVIVI+NHOGA","UPM+NVIVI+NHOGA+L02",weight_var,
      "P02","P06","AREA","ED08","ED08","ED0504","ED0504","ED02","structural_missing"
    ),
    rule_type = c(
      "constant","constant",
      if (identical(year, 2021L)) "parse_filename" else "direct_copy",
      "parse_filename","identity_concat","identity_concat","direct_copy",
      "direct_copy","recode_binary","recode_location","direct_copy","recode_level_from_attendance",
      "split_code_level","split_code_grade","recode_binary","structural_missing"
    ),
    required_for_indicator_family = c(
      "all","all","all","all","all","all","all",
      "household_core","household_core","household_core","attendance_oos","attendance_completion_postsecondary",
      "completion_postsecondary","completion","literacy","repetition"
    ),
    notes = c(
      "Set to PRY","Set to EPHC",
      if (identical(year, 2021L)) "No explicit survey-year field observed in 2021 file; use filename year" else "Observed survey year field",
      if (identical(year, 2021L)) "Quarterly release inferred from filename" else "Annual release from filename",
      "Verified household identifier","Verified person identifier",weight_note,
      "P02 = age in years","P06 = sexo; P02 = edad and must not be used as sex","Verified public disaggregation field",
      "ED08 = currently attends an institution of education",
      "ED08 current-attendance categories are also the current-study level ladder; 19 = does not attend and must map to missing current level",
      "ED0504 = combined level and approved grade code; split to extract completed level",
      "ED0504 = combined level and approved grade code; split to extract completed grade",
      "ED02 = knows how to read and write",
      "No repetition field directly observed in active PRY stack"
    )
  )
}

crosswalk_rows <- function(registry) {
  hh <- registry[layer == "household_core", .(source_id, country_code, source_program, year, period)]
  rows <- rbindlist(lapply(seq_len(nrow(hh)), function(i) {
    r <- hh[i]
    if (r$country_code == "ARG") return(arg_rows(r$source_id, r$year, r$period))
    if (r$country_code == "HND") return(hnd_rows(r$source_id, r$year))
    if (r$country_code == "PRY") return(pry_rows(r$source_id, r$year))
    stop("Unhandled country in household core: ", r$country_code)
  }), fill = TRUE)
  rows[]
}

required_raw_vars <- function(raw_variable) {
  if (grepl("^constant\\(", raw_variable) || grepl("^derived_from_", raw_variable) || raw_variable == "structural_missing") {
    return(character())
  }
  parts <- trimws(unlist(strsplit(raw_variable, "\\+|\\|", perl = TRUE)))
  parts[nzchar(parts)]
}

validate_crosswalk <- function(crosswalk, registry) {
  hh_sources <- registry[layer == "household_core", .(source_id, country_code, source_program)]
  x_keys <- unique(crosswalk[, .(source_id, country_code, source_program)])
  missing_sources <- fsetdiff(hh_sources, x_keys)
  if (nrow(missing_sources) > 0L) {
    stop("Crosswalk missing household sources: ", paste(missing_sources$source_id, collapse = ", "))
  }

  dupes <- crosswalk[, .N, by = .(source_id, harmonized_variable)][N > 1L]
  if (nrow(dupes) > 0L) {
    stop("Crosswalk has duplicate harmonized-variable rows for source_id entries.")
  }

  schema_map <- registry[layer == "household_core", .(source_id, schema_signature)]
  schema_map[, schema_vars := lapply(schema_signature, function(sig) if (is.na(sig) || !nzchar(sig)) character() else strsplit(sig, "|", fixed = TRUE)[[1]])]
  check_rows <- merge(crosswalk, schema_map[, .(source_id, schema_vars)], by = "source_id", all.x = TRUE)
  bad <- check_rows[, {
    required <- required_raw_vars(raw_variable)
    missing <- setdiff(required, schema_vars[[1]])
    .(missing = paste(missing, collapse = "|"))
  }, by = .(source_id, country_code, source_program, harmonized_variable, raw_variable)]
  bad <- bad[nzchar(missing)]
  if (nrow(bad) > 0L) {
    stop(
      "Crosswalk references raw variables absent from observed schema: ",
      paste(sprintf("%s-%s -> %s", bad$source_id, bad$harmonized_variable, bad$missing), collapse = "; ")
    )
  }
  invisible(TRUE)
}

build_exception_log <- function(crosswalk, write = TRUE) {
  structural <- crosswalk[rule_type == "structural_missing",
    .(
      source_id,
      country_code,
      source_program,
      survey_year = as.character(source_year),
      record_scope = "person",
      field_name = harmonized_variable,
      issue_type = "structural_missing",
      issue_description = notes,
      resolution_status = "open",
      resolution_note = "Carry as structural missing in harmonized outputs until a verified raw field is found."
    )
  ]

  caveats <- rbindlist(list(
    crosswalk[country_code == "PRY" & harmonized_variable == "weight_h",
      .(
        source_id,
        country_code,
        source_program,
        survey_year = as.character(source_year),
        record_scope = "person",
        field_name = harmonized_variable,
        issue_type = "label_caveat",
        issue_description = "Paraguay uses FEX in 2021 and FEX.2022 in 2022-2024; the execution log must record the actual weight variable used by source-year.",
        resolution_status = "open",
        resolution_note = "Select the observed weight variable by source_id and log it at runtime."
      )
    ],
    crosswalk[country_code == "PRY" & harmonized_variable == "sex_h",
      .(
        source_id,
        country_code,
        source_program,
        survey_year = as.character(source_year),
        record_scope = "person",
        field_name = harmonized_variable,
        issue_type = "schema_correction",
        issue_description = "Schema inspection confirms P06 is sex and P02 is age in active PRY EPHC files.",
        resolution_status = "resolved",
        resolution_note = "Use P06 for sex_h across all PRY source-years."
      )
    ],
    crosswalk[country_code == "PRY" & harmonized_variable == "current_level_h",
      .(
        source_id,
        country_code,
        source_program,
        survey_year = as.character(source_year),
        record_scope = "person",
        field_name = harmonized_variable,
        issue_type = "derived_from_multicategory_attendance",
        issue_description = "Current study level is derived from the ED08 attendance category ladder rather than a separate field.",
        resolution_status = "resolved",
        resolution_note = "Recode ED08 categories into the annual current-level ladder and log the category mapping."
      )
    ]
  ), fill = TRUE)

  exceptions <- rbindlist(list(structural, caveats), fill = TRUE)
  setorder(exceptions, source_id, field_name, issue_type)
  if (write) fwrite(exceptions, cfg_path("exception_log.csv"))
  exceptions[]
}

build_crosswalk <- function(write = TRUE) {
  registry <- build_source_registry(write = FALSE)
  crosswalk <- crosswalk_rows(registry)
  validate_crosswalk(crosswalk, registry)
  setorder(crosswalk, source_id, harmonized_variable)
  if (write) {
    fwrite(crosswalk, cfg_path("crosswalk.csv"))
    build_exception_log(crosswalk, write = TRUE)
  }
  crosswalk[]
}

if (sys.nframe() == 0L) {
  crosswalk <- build_crosswalk(write = TRUE)
  print(crosswalk[, .(source_id, harmonized_variable, raw_variable, rule_type)])
}
