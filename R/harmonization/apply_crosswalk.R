suppressPackageStartupMessages({
  library(data.table)
  library(haven)
})

source(file.path(getwd(), "R", "utils", "paths.R"))

read_household_source <- function(registry_row) {
  schema_path <- registry_row$schema_source[[1]]
  fmt <- tolower(registry_row$schema_type[[1]])
  if (!file.exists(schema_path)) stop("Schema source missing: ", schema_path)

  if (fmt == "txt") {
    return(fread(schema_path, sep = ";", encoding = "UTF-8", showProgress = FALSE))
  }
  if (fmt == "parquet") {
    return(as.data.table(arrow::read_parquet(schema_path)))
  }
  if (fmt %chin% c("sav", "zsav")) {
    return(as.data.table(read_sav(schema_path)))
  }
  if (fmt == "csv") {
    return(fread(schema_path, encoding = "UTF-8", showProgress = FALSE))
  }
  stop("Unsupported household schema_type: ", fmt)
}

copy_with_na <- function(dt, col) {
  if (!col %chin% names(dt)) return(rep(NA, nrow(dt)))
  dt[[col]]
}

concat_fields <- function(dt, cols, sep = "_") {
  if (!length(cols)) return(rep(NA_character_, nrow(dt)))
  vals <- lapply(cols, function(col) as.character(copy_with_na(dt, col)))
  do.call(paste, c(vals, list(sep = sep)))
}

parse_constant <- function(raw_variable) {
  sub("^constant\\('(.+)'\\)$", "\\1", raw_variable)
}

extract_year_from_source_id <- function(source_id) {
  m <- regmatches(source_id, regexpr("20[0-9]{2}", source_id))
  if (!length(m) || is.na(m)) NA_integer_ else as.integer(m)
}

extract_period_from_source_id <- function(source_id) {
  if (grepl("_T[1-4]$", source_id)) return(sub("^.*_(T[1-4])$", "\\1", source_id))
  if (grepl("PRY_EPHC_2021", source_id)) return("quarterly")
  if (grepl("PRY_EPHC_20(22|23|24)", source_id)) return("annual")
  if (grepl("HND_EPHPM_20(21|22|23|24)$", source_id)) return("annual_or_june_release")
  NA_character_
}

recode_binary_sex <- function(x) {
  xch <- trimws(as.character(x))
  out <- rep(NA_character_, length(xch))
  out[xch %chin% c("1", "1.0", "M", "MALE", "Masculino", "Hombre")] <- "male"
  out[xch %chin% c("2", "2.0", "F", "FEMALE", "Femenino", "Mujer")] <- "female"
  out
}

recode_binary_yesno <- function(x) {
  xch <- trimws(as.character(x))
  out <- rep(NA_integer_, length(xch))
  out[xch %chin% c("1", "1.0", "Si", "Sí", "YES", "Y")] <- 1L
  out[xch %chin% c("2", "2.0", "No", "NO", "N")] <- 0L
  out
}

recode_location_generic <- function(x) {
  xch <- trimws(as.character(x))
  out <- rep(NA_character_, length(xch))
  out[xch %chin% c("1", "1.0", "Urbano", "URBANO")] <- "urban"
  out[xch %chin% c("2", "2.0", "Rural", "RURAL")] <- "rural"
  out
}

recode_arg_location <- function(x) {
  xch <- trimws(toupper(as.character(x)))
  out <- rep(NA_character_, length(xch))
  out[xch %chin% c("S", "SI", "SÍ")] <- "urban"
  out[xch %chin% c("N", "NO")] <- "rural_or_small"
  xnum <- suppressWarnings(as.numeric(xch))
  out[is.na(out) & !is.na(xnum) & xnum == 1] <- "urban"
  out[is.na(out) & !is.na(xnum) & xnum != 1] <- "rural_or_small"
  out
}

recode_arg_attendance <- function(dt) {
  ch10 <- suppressWarnings(as.numeric(as.character(copy_with_na(dt, "CH10"))))
  out <- rep(NA_integer_, nrow(dt))
  out[!is.na(ch10) & ch10 == 1L] <- 1L   # CH10=1: currently attends
  out[!is.na(ch10) & ch10 != 1L] <- 0L   # CH10!=1: does not attend
  out
}

recode_arg_level <- function(x) {
  suppressWarnings(as.integer(as.character(x)))
}

recode_completion_level <- function(x) {
  suppressWarnings(as.integer(as.character(x)))
}

split_pry_ed0504 <- function(x, part = c("level", "grade")) {
  part <- match.arg(part)
  xnum <- suppressWarnings(as.integer(as.character(x)))
  out <- rep(NA_integer_, length(xnum))
  ok <- !is.na(xnum)
  if (part == "level") out[ok] <- xnum[ok] %/% 10L
  if (part == "grade") out[ok] <- xnum[ok] %% 10L
  out
}

recode_pry_level_from_ed08 <- function(x) {
  xnum <- suppressWarnings(as.integer(as.character(x)))
  out <- rep(NA_integer_, length(xnum))
  out[!is.na(xnum) & xnum >= 1 & xnum <= 18] <- xnum[!is.na(xnum) & xnum >= 1 & xnum <= 18]
  out[!is.na(xnum) & xnum == 19] <- NA_integer_
  out
}

apply_rule <- function(dt, rule_row) {
  raw <- rule_row$raw_variable[[1]]
  rule <- rule_row$rule_type[[1]]
  sid <- rule_row$source_id[[1]]

  if (rule == "constant") return(rep(parse_constant(raw), nrow(dt)))
  if (rule == "direct_copy") return(copy_with_na(dt, raw))
  if (rule == "parse_filename") {
    if (raw == "derived_from_filename_year") return(rep(extract_year_from_source_id(sid), nrow(dt)))
    if (raw == "derived_from_filename_period") return(rep(extract_period_from_source_id(sid), nrow(dt)))
  }
  if (rule == "identity_concat") return(concat_fields(dt, trimws(strsplit(raw, "\\+")[[1]])))
  if (rule == "recode_binary") {
    if (rule_row$harmonized_variable[[1]] == "sex_h") return(recode_binary_sex(copy_with_na(dt, raw)))
    return(recode_binary_yesno(copy_with_na(dt, raw)))
  }
  if (rule == "recode_location") {
    if (sid %like% "ARG_EPH") return(recode_arg_location(copy_with_na(dt, raw)))
    return(recode_location_generic(copy_with_na(dt, raw)))
  }
  if (rule == "rule_based_attendance") return(recode_arg_attendance(dt))
  if (rule == "recode_level") return(recode_arg_level(copy_with_na(dt, raw)))
  if (rule == "recode_completion_level") return(recode_completion_level(copy_with_na(dt, raw)))
  if (rule == "split_code_level") return(split_pry_ed0504(copy_with_na(dt, raw), "level"))
  if (rule == "split_code_grade") return(split_pry_ed0504(copy_with_na(dt, raw), "grade"))
  if (rule == "recode_level_from_attendance") return(recode_pry_level_from_ed08(copy_with_na(dt, raw)))
  if (rule == "structural_missing") return(rep(NA, nrow(dt)))

  stop("Unhandled rule_type: ", rule, " for ", sid, " -> ", rule_row$harmonized_variable[[1]])
}

runtime_check <- function(rule_row, value) {
  hv <- rule_row$harmonized_variable[[1]]
  sid <- rule_row$source_id[[1]]
  rule_type <- rule_row$rule_type[[1]]
  issues <- list()

  if (all(is.na(value)) && rule_type != "structural_missing") {
    issues[[length(issues) + 1L]] <- data.table(
      source_id = sid,
      country_code = rule_row$country_code[[1]],
      source_program = rule_row$source_program[[1]],
      survey_year = as.character(rule_row$source_year[[1]]),
      record_scope = "person",
      field_name = hv,
      issue_type = "runtime_all_na",
      issue_description = sprintf("Derived field %s is all NA at runtime.", hv),
      resolution_status = "open",
      resolution_note = "Inspect mapping rule against observed schema and values."
    )
  }

  if (hv == "weight_h") {
    nm <- rule_row$raw_variable[[1]]
    if (sid %like% "PRY_EPHC_" && nm %in% c("FEX", "FEX.2022")) {
      issues[[length(issues) + 1L]] <- data.table(
        source_id = sid,
        country_code = rule_row$country_code[[1]],
        source_program = rule_row$source_program[[1]],
        survey_year = as.character(rule_row$source_year[[1]]),
        record_scope = "person",
        field_name = hv,
        issue_type = "runtime_weight_selected",
        issue_description = sprintf("Runtime selected Paraguay weight variable %s.", nm),
        resolution_status = "resolved",
        resolution_note = "Persist selected weight variable in run log for this source-year."
      )
    }
  }

  if (!length(issues)) return(NULL)
  rbindlist(issues, fill = TRUE)
}

harmonize_source <- function(source_id, registry, crosswalk) {
  sid <- source_id
  rr <- registry[source_id == sid]
  if (nrow(rr) != 1L) stop("Expected one registry row for ", sid)
  rules <- crosswalk[source_id == sid][order(harmonized_variable)]
  raw_dt <- read_household_source(rr)

  out <- data.table(row_id = seq_len(nrow(raw_dt)))
  runtime_issues <- list()
  for (i in seq_len(nrow(rules))) {
    rule_row <- rules[i]
    hv <- rule_row$harmonized_variable[[1]]
    value <- apply_rule(raw_dt, rule_row)
    out[, (hv) := value]
    chk <- runtime_check(rule_row, value)
    if (!is.null(chk) && nrow(chk)) runtime_issues[[length(runtime_issues) + 1L]] <- chk
  }

  out[, source_id := sid]
  setcolorder(out, c("source_id", setdiff(names(out), c("source_id", "row_id")), "row_id"))
  list(
    data = out,
    runtime_issues = if (length(runtime_issues)) unique(rbindlist(runtime_issues, fill = TRUE)) else data.table()
  )
}
