#' Attendance rate estimator
#'
#' Implements attendance rate estimation according to UIS methodology:
#' Level-specific weighted shares over official age universes.
#' Produces indicators per year per country.
#'
#' @param harmonized_data A data.table containing harmonized person-level data
#' @param level Character vector specifying education levels to estimate.
#'   Options: "primary", "lower_secondary", "upper_secondary", "tertiary"
#' @param group_vars Character vector of grouping variables (default: 
#'   c("country_code", "source_program", "survey_year", "wave_id"))
#' @param include_se Logical indicating whether to include standard errors
#'
#' @return A data.table with attendance rate estimates per year per country
#' @export
estimate_attendance <- function(harmonized_data,
                                level = c("primary", "lower_secondary", "upper_secondary"),
                                group_vars = c("country_code", "source_program", "survey_year", "wave_id"),
                                include_se = FALSE,
                                na_as_attending = FALSE) {
  
  # Load utility functions
  source_path <- file.path(dirname(dirname(getwd())), "indicators", "utils", "weighted_rate.R")
  if (file.exists(source_path)) {
    source(source_path)
  }
  
  # Ensure data.table
  if (!data.table::is.data.table(harmonized_data)) {
    harmonized_data <- data.table::as.data.table(harmonized_data)
  }
  
  # Check required variables
  required_vars <- c("age_h", "attending_currently_h", "current_level_h", "weight_h",
                     "country_code", "source_program", "survey_year", "wave_id")
  missing_vars <- setdiff(required_vars, names(harmonized_data))
  if (length(missing_vars) > 0) {
    stop("Missing required variables: ", paste(missing_vars, collapse = ", "))
  }
  
  # Verify we have year and country grouping
  if (!all(c("country_code", "survey_year") %in% group_vars)) {
    warning("Grouping variables should include 'country_code' and 'survey_year' for per-year per-country estimates")
  }
  
  # Define level-specific age universes (based on UIS definitions)
  age_universes <- list(
    primary = c(6, 11),           # Ages 6-11
    lower_secondary = c(12, 14),  # Ages 12-14
    upper_secondary = c(15, 17),  # Ages 15-17
    tertiary = c(18, 24)          # Ages 18-24 (approximate)
  )
  
  # Define level codes in harmonized data (these may need adjustment based on actual data)
  level_codes <- list(
    primary = 1,
    lower_secondary = 2,
    upper_secondary = 3,
    tertiary = 4
  )
  
  results_list <- list()
  
  for (lvl in level) {
    if (!lvl %in% names(age_universes)) {
      warning("Unknown level: ", lvl, ". Skipping.")
      next
    }
    
    age_range <- age_universes[[lvl]]
    level_code <- level_codes[[lvl]]
    
    # Eligible universe is strictly age-based (U_i^(l) in gem_method_indicator.md).
    # current_level_h is NOT used here: including it would exclude non-attending
    # children whose level field is populated, collapsing the denominator to
    # attending-only and forcing attendance → 100 %.
    eligible_condition <- function(dt) {
      return(dt$age_h >= age_range[1] & dt$age_h <= age_range[2])
    }

    # Indicator condition: currently attending.
    # na_as_attending = TRUE is used for ARG where recode_arg_attendance can
    # return NA for children with ESTADO==3 (studying) but missing level fields;
    # those children are in school and must not be counted as non-attending.
    indicator_condition <- function(dt) {
      if (na_as_attending) {
        return(dt$attending_currently_h == 1 | is.na(dt$attending_currently_h))
      }
      return(dt$attending_currently_h == 1)
    }
    
    # Compute attendance rate - will produce per year per country due to group_vars
    if (include_se) {
      attendance_rates <- weighted_rate_with_se(
        data = harmonized_data,
        eligible_condition = eligible_condition,
        indicator_condition = indicator_condition,
        weight_var = "weight_h",
        group_vars = group_vars,
        se_method = "binomial"
      )
    } else {
      attendance_rates <- weighted_rate(
        data = harmonized_data,
        eligible_condition = eligible_condition,
        indicator_condition = indicator_condition,
        weight_var = "weight_h",
        group_vars = group_vars,
        include_counts = TRUE
      )
    }
    
    # Add level information
    attendance_rates[, level := lvl]
    attendance_rates[, indicator_id := "ATTEND_LVL"]
    attendance_rates[, indicator_name := "Attendance rate"]
    attendance_rates[, indicator_family := "household_core"]
    
    results_list[[lvl]] <- attendance_rates
  }
  
  # Combine all levels
  if (length(results_list) == 0) {
    return(data.table())
  }
  
  results <- data.table::rbindlist(results_list, fill = TRUE)
  
  # Ensure we have per-year per-country structure
  # Check that we have unique combinations of country_code, survey_year, level
  unique_combos <- unique(results[, .(country_code, survey_year, level)])
  message("Generated ", nrow(unique_combos), " unique country-year-level combinations")
  
  # Reorder columns to have country and year first
  base_cols <- c("country_code", "source_program", "survey_year", "wave_id", 
                 "level", "indicator_id", "indicator_name", "indicator_family",
                 "rate")
  
  if (include_se) {
    base_cols <- c(base_cols, "se", "ci_lower", "ci_upper")
  }
  
  if ("numerator" %in% names(results)) {
    base_cols <- c(base_cols, "numerator", "denominator", "n_eligible", "n_indicator")
  }
  
  # Ensure all columns exist
  existing_cols <- intersect(base_cols, names(results))
  other_cols <- setdiff(names(results), existing_cols)
  
  results <- results[, c(existing_cols, other_cols), with = FALSE]
  
  return(results)
}

#' Estimate attendance rates with country-specific adjustments
#'
#' Applies country-specific rules for attendance estimation based on methodology document
#' Produces indicators per year per country.
#'
#' @param harmonized_data A data.table containing harmonized person-level data
#' @param country_codes Character vector of country codes to process (default: all)
#' @param years Numeric vector of years to process (default: all)
#' @param ... Additional arguments passed to estimate_attendance
#'
#' @return A data.table with attendance rate estimates per year per country
#' @export
estimate_attendance_country_specific <- function(harmonized_data, 
                                                 country_codes = NULL,
                                                 years = NULL,
                                                 ...) {
  
  if (!data.table::is.data.table(harmonized_data)) {
    harmonized_data <- data.table::as.data.table(harmonized_data)
  }
  
  # Filter by country if specified
  if (!is.null(country_codes)) {
    harmonized_data <- harmonized_data[country_code %in% country_codes]
  }
  
  # Filter by year if specified
  if (!is.null(years)) {
    harmonized_data <- harmonized_data[survey_year %in% years]
  }
  
  # Get unique countries and years for reporting
  unique_countries <- unique(harmonized_data$country_code)
  unique_years <- unique(harmonized_data$survey_year)
  
  message("Processing ", length(unique_countries), " countries: ", 
          paste(unique_countries, collapse = ", "))
  message("Processing ", length(unique_years), " years: ", 
          paste(sort(unique_years), collapse = ", "))
  
  results_list <- list()
  
  # Process each country separately to apply country-specific rules
  for (country in unique_countries) {
    country_data <- harmonized_data[country_code == country]
    
    # Apply country-specific rules based on methodology document
    
    if (country == "ARG") {
      # Argentina: recode_arg_attendance uses CH08 directly (1=attends, 2=not).
      # NA values only occur when CH08 is missing; treat those as true NAs.
      message("Argentina: Using CH08-based attendance with NIVEL_ED level mapping")
      country_results <- estimate_attendance(country_data, na_as_attending = FALSE, ...)

    } else if (country == "HND") {
      # Honduras: attending_currently_h is direct_copy of ED03 (1 = yes, 2 = no).
      # indicator_condition == 1 correctly captures attending children; no recode needed.
      message("Honduras: Using ED03 attendance with ED10 level assignment")
      country_results <- estimate_attendance(country_data, ...)

    } else if (country == "PRY") {
      # Paraguay: attending_currently_h is direct_copy of ED08, a multi-category
      # variable (1–18 = attending some level, 19 = not attending).
      # Recode to binary at the indicator layer without modifying harmonized data.
      message("Paraguay: Using ED08 attendance (recoded to binary at indicator layer)")
      country_data_proc <- data.table::copy(country_data)
      country_data_proc[, attending_currently_h := data.table::fifelse(
        attending_currently_h == 19L, 0L,
        data.table::fifelse(is.na(attending_currently_h), NA_integer_, 1L)
      )]
      country_results <- estimate_attendance(country_data_proc, ...)
      
    } else {
      # Default for other countries
      message(country, ": Using standard attendance estimation")
      country_results <- estimate_attendance(country_data, ...)
    }
    
    # Add country-specific metadata
    if (nrow(country_results) > 0) {
      country_results[, country_specific_notes := get_country_attendance_notes(country)]
      results_list[[country]] <- country_results
    }
  }
  
  # Combine results
  if (length(results_list) == 0) {
    return(data.table())
  }
  
  results <- data.table::rbindlist(results_list, fill = TRUE)
  
  # Verify per-year per-country structure
  summary_stats <- results[, .(
    n_estimates = .N,
    min_year = min(survey_year, na.rm = TRUE),
    max_year = max(survey_year, na.rm = TRUE)
  ), by = country_code]
  
  message("\nSummary of attendance estimates:")
  for (i in 1:nrow(summary_stats)) {
    message("  ", summary_stats$country_code[i], ": ", 
            summary_stats$n_estimates[i], " estimates (", 
            summary_stats$min_year[i], "-", summary_stats$max_year[i], ")")
  }
  
  return(results)
}

#' Get country-specific attendance estimation notes
#'
#' @param country_code Character country code
#'
#' @return Character string with country-specific notes
#' @export
get_country_attendance_notes <- function(country_code) {
  notes <- list(
    ARG = "Attendance from CH08-based harmonization with NIVEL_ED level mapping",
    HND = "Attendance from ED03 with level assignment from ED10",
    PRY = "Attendance from ED08; current_level_h not validated for level-specific outputs"
  )
  
  return(notes[[country_code]] %||% "Standard attendance estimation")
}

#' Estimate attendance rates for all available levels and countries
#'
#' Main function for attendance rate estimation pipeline.
#' Produces CSV output with per-year per-country indicators.
#'
#' @param harmonized_data_path Path to harmonized data file (Parquet or CSV)
#' @param output_path Path to write output CSV (required)
#' @param years Numeric vector of years to process (default: all available)
#' @param countries Character vector of country codes to process (default: all available)
#' @param levels Character vector of education levels to estimate
#' @param include_se Logical indicating whether to include standard errors
#'
#' @return A data.table with attendance rate estimates per year per country
#' @export
run_attendance_estimation <- function(harmonized_data = NULL,
                                      harmonized_data_path = NULL,
                                      output_path = NULL,
                                      years = NULL,
                                      countries = NULL,
                                      levels = c("primary", "lower_secondary", "upper_secondary"),
                                      group_vars = c("country_code", "source_program", "survey_year", "wave_id"),
                                      include_se = FALSE) {
  
  # Load harmonized data if not provided directly
  if (is.null(harmonized_data)) {
    if (!is.null(harmonized_data_path)) {
      message("Loading harmonized data from: ", harmonized_data_path)
      if (grepl("\\.parquet$", harmonized_data_path, ignore.case = TRUE)) {
        if (!requireNamespace("arrow", quietly = TRUE)) {
          stop("Package 'arrow' required for Parquet files")
        }
        harmonized_data <- arrow::read_parquet(harmonized_data_path)
      } else if (grepl("\\.csv$", harmonized_data_path, ignore.case = TRUE)) {
        harmonized_data <- data.table::fread(harmonized_data_path)
      } else if (grepl("\\.csv\\.gz$", harmonized_data_path, ignore.case = TRUE)) {
        harmonized_data <- data.table::fread(harmonized_data_path)
      } else {
        stop("Unsupported file format. Use .parquet, .csv, or .csv.gz")
      }
    } else {
      stop("Either harmonized_data or harmonized_data_path is required")
    }
  }
  
  # Convert to data.table if not already
  if (!data.table::is.data.table(harmonized_data)) {
    harmonized_data <- data.table::as.data.table(harmonized_data)
  }
  
  # Estimate attendance rates per year per country
  message("\nEstimating attendance rates per year per country...")
  attendance_rates <- estimate_attendance_country_specific(
    harmonized_data = harmonized_data,
    country_codes = countries,
    years = years,
    level = levels,
    group_vars = group_vars,
    include_se = include_se
  )
  
  # Write output CSV
  if (!is.null(output_path)) {
    message("\nWriting attendance rates to: ", output_path)
    data.table::fwrite(attendance_rates, output_path)
  }
  
  # Report summary
  if (nrow(attendance_rates) > 0) {
    unique_countries <- unique(attendance_rates$country_code)
    unique_years <- unique(attendance_rates$survey_year)
    message("\nGenerated ", nrow(attendance_rates), " attendance rate estimates")
    message("Countries: ", paste(unique_countries, collapse = ", "))
    message("Years: ", paste(sort(unique_years), collapse = ", "))
    message("Levels: ", paste(unique(attendance_rates$level), collapse = ", "))
    
    # Show sample of output
    message("\nSample of output (first 5 rows):")
    print(attendance_rates[1:min(5, nrow(attendance_rates)), 
                           .(country_code, survey_year, level, rate)])
  } else {
    warning("No attendance rates were generated")
  }
  
  return(attendance_rates)
}

# Helper function for NULL coalescing
`%||%` <- function(x, y) if (is.null(x)) y else x