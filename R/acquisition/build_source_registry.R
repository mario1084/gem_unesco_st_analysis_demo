suppressPackageStartupMessages({
  library(data.table)
  library(haven)
  library(jsonlite)
})

source(file.path(getwd(), "R", "utils", "paths.R"))

normalize_slashes <- function(x) {
  normalizePath(x, winslash = "/", mustWork = FALSE)
}

read_delim_header <- function(path, sep) {
  line <- readLines(path, n = 1, warn = FALSE, encoding = "UTF-8")
  if (length(line) == 0L || is.na(line[[1]]) || identical(line[[1]], "")) {
    return(character(0))
  }
  parts <- strsplit(line[[1]], split = sep, fixed = TRUE)[[1]]
  sub("\r$", "", parts)
}

pick_first_glob <- function(patterns) {
  hits <- unlist(lapply(patterns, Sys.glob), use.names = FALSE)
  if (length(hits) == 0) return(NA_character_)
  normalize_slashes(hits[[1]])
}

schema_info_text <- function(path, type = c("csv", "txt", "sav", "json", "zip", "parquet")) {
  type <- match.arg(type)
  tryCatch({
    if (type == "sav") {
      d <- read_sav(path, n_max = 1)
      vars <- names(d)
    } else if (type == "parquet") {
      vars <- names(arrow::read_parquet(path))
    } else if (type == "zip") {
      vars <- utils::unzip(path, list = TRUE)$Name
    } else if (type %in% c("csv", "txt")) {
      sep <- if (tolower(type) == "txt") ";" else ","
      vars <- tryCatch(
        names(fread(path, nrows = 0, sep = sep, encoding = "UTF-8")),
        error = function(e) read_delim_header(path, sep)
      )
    } else {
      obj <- fromJSON(path, simplifyVector = FALSE)
      vars <- names(obj)
    }
    paste(vars, collapse = "|")
  }, error = function(e) {
    NA_character_
  })
}

schema_var_count <- function(path, type = c("csv", "txt", "sav", "json", "zip", "parquet")) {
  type <- match.arg(type)
  tryCatch({
    if (type == "sav") {
      length(names(read_sav(path, n_max = 1)))
    } else if (type == "parquet") {
      length(names(arrow::read_parquet(path)))
    } else if (type == "zip") {
      nrow(utils::unzip(path, list = TRUE))
    } else if (type %in% c("csv", "txt")) {
      sep <- if (tolower(type) == "txt") ";" else ","
      length(tryCatch(
        names(fread(path, nrows = 0, sep = sep, encoding = "UTF-8")),
        error = function(e) read_delim_header(path, sep)
      ))
    } else {
      length(names(fromJSON(path, simplifyVector = FALSE)))
    }
  }, error = function(e) {
    NA_integer_
  })
}

read_manifest <- function(path) {
  fread(path, encoding = "UTF-8")
}

build_household_registry <- function() {
  stage <- staging_root()
  arg_manifest <- read_manifest(file.path(stage, "NSO", "Argentina", "recent_microdata_manifest.csv"))
  hnd_manifest <- read_manifest(file.path(stage, "NSO", "Honduras", "recent_microdata_manifest.csv"))
  pry_manifest <- read_manifest(file.path(stage, "NSO", "Paraguay", "recent_microdata_manifest.csv"))

  arg_schema_sources <- vapply(
    arg_manifest$filename,
    function(fn) pick_first_glob(c(
      file.path(stage, "NSO", "Argentina", "extracted_recent_microdata",
        sub("\\.zip$", "", fn), "usu_individual_T*.parquet"),
      file.path(stage, "NSO", "Argentina", "extracted_recent_microdata",
        sub("\\.zip$", "", fn), "usu_individual_T*.txt")
    )),
    character(1)
  )
  arg_rows <- arg_manifest[, .(
    source_id = sprintf("ARG_EPH_%d_%s", as.integer(year), gsub("Q", "T", period)),
    country_code = "ARG",
    source_program = "EPH",
    layer = "household_core",
    year = as.integer(year),
    period = period,
    artifact_name = filename,
    artifact_type = asset_class,
    format = "zip",
    source_path = normalize_slashes(output_path),
    schema_source = arg_schema_sources,
    status = status,
    notes = "Canonical Argentina household source for annual indicator reconstruction"
  )]
  arg_rows[, schema_type := fifelse(grepl("\\.parquet$", schema_source, ignore.case = TRUE), "parquet", "txt")]

  hnd_schema_sources <- vapply(
    hnd_manifest$filename,
    function(fn) pick_first_glob(c(
      file.path(stage, "NSO", "Honduras", "extracted_recent_microdata", sub("\\.zip$", "", fn), "*PD.sav"),
      file.path(stage, "NSO", "Honduras", "extracted_recent_microdata", sub("\\.zip$", "", fn), "EPHPM*.sav"),
      file.path(stage, "NSO", "Honduras", "extracted_recent_microdata", sub("\\.zip$", "", fn), "HOGARES*.sav"),
      file.path(stage, "NSO", "Honduras", "extracted_recent_microdata", sub("\\.zip$", "", fn), "*.sav")
    )),
    character(1)
  )
  hnd_rows <- hnd_manifest[, .(
    source_id = sprintf("HND_EPHPM_%s", year),
    country_code = "HND",
    source_program = "EPHPM",
    layer = "household_core",
    year = as.integer(year),
    period = period,
    artifact_name = filename,
    artifact_type = asset_class,
    format = "zip",
    source_path = normalize_slashes(output_path),
    schema_source = hnd_schema_sources,
    status = status,
    notes = "Canonical Honduras household source for annual indicator reconstruction"
  )]
  hnd_rows[, schema_type := "sav"]

  pry_rows <- pry_manifest[grepl("^(INGREFAM|REG0[12])_.*\\.(SAV|csv)$", filename), .(
    source_id = sprintf("PRY_EPHC_%s_%s", year, ifelse(grepl("\\.SAV$", filename, ignore.case = TRUE), "sav", "csv")),
    country_code = "PRY",
    source_program = "EPHC",
    layer = "household_core",
    year = as.integer(year),
    period = period,
    artifact_name = filename,
    artifact_type = asset_class,
    format = fifelse(grepl("\\.SAV$", filename, ignore.case = TRUE), "sav", "csv"),
    source_path = normalize_slashes(output_path),
    schema_source = normalize_slashes(output_path),
    status = status,
    notes = "Canonical Paraguay person-file source for annual indicator reconstruction"
  )]
  # Prefer REG02 > REG01 > INGREFAM, and SAV > CSV for a given year/period.
  pry_rows[, file_priority := fcase(
    grepl("^REG02_", artifact_name), 2L,
    grepl("^REG01_", artifact_name), 1L,
    grepl("^INGREFAM_", artifact_name), 0L,
    default = 0L
  )]
  pry_rows[, format_priority := fifelse(tolower(format) == "sav", 1L, 0L)]
  setorder(pry_rows, year, -file_priority, -format_priority)
  pry_rows <- pry_rows[, .SD[1], by = .(country_code, source_program, year, period)]
  pry_rows[, format_priority := NULL]
  pry_rows[, file_priority := NULL]
  pry_rows[, schema_type := format]

  rbindlist(list(arg_rows, hnd_rows, pry_rows), fill = TRUE)
}

build_nonhousehold_registry <- function() {
  stage <- staging_root()
  rows <- rbindlist(list(
    data.table(
      source_id = "LEARN_ERCE_2019",
      country_code = "ARG;HND;PRY",
      source_program = "ERCE",
      layer = "learning",
      year = 2019L,
      period = "annual",
      artifact_name = "ERCE_2019_databases.zip",
      artifact_type = "microdata_archive",
      format = "zip",
      source_path = normalize_slashes(file.path(stage, "ERCE", "downloads", "ERCE_2019_databases.zip")),
      schema_source = normalize_slashes(file.path(stage, "ERCE", "downloads", "ERCE_2019_databases.zip")),
      schema_type = "zip",
      status = "active",
      notes = "Canonical regional learning assessment layer"
    ),
    data.table(
      source_id = "LEARN_PISA_2022",
      country_code = "ARG;PRY",
      source_program = "PISA",
      layer = "learning",
      year = 2022L,
      period = "annual",
      artifact_name = "STU_QQQ_SPSS.zip",
      artifact_type = "microdata_archive",
      format = "zip",
      source_path = normalize_slashes(file.path(stage, "PISA", "downloads", "STU_QQQ_SPSS.zip")),
      schema_source = normalize_slashes(file.path(stage, "PISA", "downloads", "STU_QQQ_SPSS.zip")),
      schema_type = "zip",
      status = "active",
      notes = "Canonical OECD learning assessment layer"
    ),
    data.table(
      source_id = "LEARN_PISAD_2016",
      country_code = "HND",
      source_program = "PISA-D",
      layer = "learning",
      year = 2016L,
      period = "annual",
      artifact_name = "CY1MDCI_QQQ_SAV.zip",
      artifact_type = "microdata_archive",
      format = "zip",
      source_path = normalize_slashes(file.path(stage, "PISA_D", "downloads", "CY1MDCI_QQQ_SAV.zip")),
      schema_source = normalize_slashes(file.path(stage, "PISA_D", "downloads", "CY1MDCI_QQQ_SAV.zip")),
      schema_type = "zip",
      status = "active",
      notes = "Canonical PISA for Development layer"
    ),
    data.table(
      source_id = "LEARN_UIS_API_2021_2024",
      country_code = "ARG;HND;PRY",
      source_program = "UIS learning API",
      layer = "learning",
      year = 2024L,
      period = "2021-2024_window",
      artifact_name = "indicator_records_learning_sample.csv",
      artifact_type = "api_export",
      format = "csv",
      source_path = normalize_slashes(file.path(stage, "UIS_LEARNING_API", "indicator_records_learning_sample.csv")),
      schema_source = normalize_slashes(file.path(stage, "UIS_LEARNING_API", "indicator_records_learning_sample.csv")),
      schema_type = "csv",
      status = "active",
      notes = "Published UIS learning indicator layer for demo reconstruction"
    ),
    data.table(
      source_id = "ADMIN_UIS_2021_2024",
      country_code = "ARG;HND;PRY",
      source_program = "UIS admin",
      layer = "admin",
      year = 2024L,
      period = "2021-2024_window",
      artifact_name = "sdg_data_sample_recent_2021_2024.csv;opri_data_sample_recent_2021_2024.csv",
      artifact_type = "bulk_csv",
      format = "csv",
      source_path = normalize_slashes(file.path(stage, "UIS_ADMIN")),
      schema_source = normalize_slashes(file.path(stage, "UIS_ADMIN", "sdg_data_sample_recent_2021_2024.csv")),
      schema_type = "csv",
      status = "active",
      notes = "Published UIS administrative indicator layer"
    ),
    data.table(
      source_id = "POP_WPP_API_2021_2024",
      country_code = "ARG;HND;PRY",
      source_program = "WPP API",
      layer = "population",
      year = 2024L,
      period = "2021-2024_window",
      artifact_name = "TPopulation.json;PopByAge5AndSex.json;PopBroadAges.json",
      artifact_type = "api_export",
      format = "json",
      source_path = normalize_slashes(file.path(stage, "WPP_API")),
      schema_source = normalize_slashes(file.path(stage, "WPP_API", "TPopulation.json")),
      schema_type = "json",
      status = "active",
      notes = "Population denominators and age structure reference layer"
    ),
    data.table(
      source_id = "FIN_CRS_2021_2024",
      country_code = "ARG;HND;PRY",
      source_program = "OECD DAC/CRS",
      layer = "finance",
      year = 2024L,
      period = "2021-2024_window",
      artifact_name = "education_oda_disbursements_constant_prices.csv",
      artifact_type = "csv_export",
      format = "csv",
      source_path = normalize_slashes(file.path(stage, "OECD_DAC_CRS", "education_oda_disbursements_constant_prices.csv")),
      schema_source = normalize_slashes(file.path(stage, "OECD_DAC_CRS", "education_oda_disbursements_constant_prices.csv")),
      schema_type = "csv",
      status = "active",
      notes = "Published aid and finance layer"
    )
  ), fill = TRUE)

  rows
}

build_source_registry <- function(write = TRUE) {
  registry <- rbindlist(list(build_household_registry(), build_nonhousehold_registry()), fill = TRUE)
  registry[, source_exists := file.exists(source_path)]
  registry[, schema_exists := file.exists(schema_source)]
  registry[, schema_var_count := mapply(schema_var_count, schema_source, schema_type, SIMPLIFY = TRUE)]
  registry[, schema_signature := mapply(schema_info_text, schema_source, schema_type, SIMPLIFY = TRUE)]
  setorder(registry, layer, country_code, source_program, year, period)

  if (write) {
    fwrite(registry, cfg_path("source_registry.csv"))
  }
  registry
}

if (sys.nframe() == 0) {
  registry <- build_source_registry(write = TRUE)
  print(registry[, .(source_id, country_code, source_program, layer, year, period, source_exists, schema_exists, schema_var_count)])
}
