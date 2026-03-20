#' Repetition rate estimator
#'
#' Implements repetition rate estimation according to UIS methodology:
#' Share of current students who are repeating a grade/level.
#' Only computed where direct repetition item exists in survey.
#' Currently publishable mainly for Honduras (ED11).
#' Produces indicators per year per country.
#'
#' @param harmonized_data A data.table containing harmonized person-level data
#' @param level Character vector specifying education levels to estimate.
#'   Options: "primary", "lower_secondary", "upper_secondary"
#' @param group_vars Character vector of grouping variables (default: 
#'   c("country_code", "source_program", "survey_year", "wave_id"))
#' @param include_se Logical indicating whether to include standard errors
#'
#' @return A data.table with repetition rate estimates per year per country
#' @export
estimate_repetition <- function(harmonized_data,
                                level = c("primary", "lower_secondary", "upper_secondary"),
                                group_vars = c("country_code", "source_program", "survey_year", "wave_id"),
                                include_se = FALSE) {
  
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
  required_vars <- c("age_h", "repetition_h", "current_level_h", "attending_currently_h", "weight_h",
                     "country_code", "source_program", "survey_year", "wave_id")
  missing_vars <- setdiff(required_vars, names(harmonized_data))
  if (length(missing_vars) > 0) {
    stop("Missing required variables: ", paste(missing_vars, collapse = ", "))
  }
  
  # Verify we have year and country grouping
  if (!all(c("country_code", "survey_year") %in% group_vars)) {
    warning("Grouping variables should include 'country_code' and 'survey_year' for per-year per-country estimates")
  }
  
  # Check if repetition_h variable exists and has valid values
  if (!"repetition_h" %in% names(harmonized_data)) {
    stop("repetition_h variable not found in harmonized data")
  }
  
  # Check for structural missingness
  repetition_missing <- all(is.na(harmonized_data$repetition_h))
  if (repetition_missing) {
    warning("repetition_h is completely missing (structural missingness). No repetition rates can be computed.")
    return(data.table())
  }
  
  # Define level-specific age ranges for current students
  # These are approximate age ranges for students at each level
  student_age_ranges <- list(
    primary = c(6, 11),           # Ages 6-11 for primary students
    lower_secondary = c(12, 14),  # Ages 12-14 for lower secondary students
    upper_secondary = c(15, 17)   # Ages 15-17 for upper secondary students
  )
  
  # Define level codes in harmonized data
  level_codes <- list(
    primary = 1,
    lower_secondary = 2,
    upper_secondary = 3
  )
  
  results_list <- list()
  
  for (lvl in level) {
    if (!lvl %in% names(student_age_ranges)) {
      warning("Unknown level: ", lvl, ". Skipping.")
      next
    }
    
    age_range <- student_age_ranges[[lvl]]
    level_code <- level_codes[[lvl]]
    
    # Define eligible universe: current students at this level
    # Must be: 1) age in range, 2) currently attending, 3) at this level
    eligible_condition <- function(dt) {
      age_eligible <- dt$age_h >= age_range[1] & dt$age_h <= age_range[2]
      attending <- dt$attending_currently_h == 1
      at_level <- dt$current_level_h == level_code
      
      return(age_eligible & attending & at_level)
    }
    
    # Define indicator condition: repeating (repetition_h == 1)
    indicator_condition <- function(dt) {
      # repetition_h should be 1 for repeating, 0 for not repeating
      return(dt$repetition_h == 1)
    }
    
    # Compute repetition rate
    if (include_se) {
      repetition_rates <- weighted_rate_with_se(
        data = harmonized_data,
        eligible_condition = eligible_condition,
        indicator_condition = indicator_condition,
        weight_var = "weight_h",
        group_vars = group_vars,
        se_method = "binomial"
      )
    } else {
      repetition_rates <- weighted_rate(
        data = harmonized_data,
        eligible_condition = eligible_condition,
        indicator_condition = indicator_condition,
        weight_var = "weight_h",
        group_vars = group_vars,
        include_counts = TRUE
      )
    }
    
    # Add level information
    repetition_rates[, level := lvl]
    repetition_rates[, indicator_id := "REP_RATE"]
    repetition_rates[, indicator_name := "Repetition rate"]
    repetition_rates[, indicator_family := "household_core"]
    
    results_list[[lvl]] <- repetition_rates
  }
  
  # Combine all levels
  if (length(results_list) == 0) {
    return(data.table())
  }
  
  results <- data.table::rbindlist(results_list, fill = TRUE)
  
  # Ensure we have per-year per-country structure
  unique_combos <- unique(results[, .(country_code, survey_year, level)])
  message("Generated ", nrow(unique_combos), " unique country-year-level repetition rate combinations")
  
  # Reorder columns
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

#' Estimate repetition rates with country-specific adjustments
#'
#' Applies country-specific rules for repetition estimation based on methodology document
#' Handles structural missingness for countries without repetition items.
#' Currently only Honduras 2022-2024 has validated repetition data (ED11).
#' Produces indicators per year per country.
#'
#' @param harmonized_data A data.table containing harmonized person-level data
#' @param country_codes Character vector of country codes to process (default: all)
#' @param years Numeric vector of years to process (default: all)
#' @param ... Additional arguments passed to estimate_repetition
#'
#' @return A data.table with repetition rate estimates per year per country
#' @export
estimate_repetition_country_specific <- function(harmonized_data,
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
  
  message("Processing repetition rates for ", length(unique_countries), " countries: ", 
          paste(unique_countries, collapse = ", "))
  message("Processing years: ", paste(sort(unique_years), collapse = ", "))
  
  results_list <- list()
  
  # Process each country separately to apply country-specific rules
  for (country in unique_countries) {
    country_data <- harmonized_data[country_code == country]
    
    # Check for structural missingness in repetition_h
    repetition_missing <- all(is.na(country_data$repetition_h))
    
    # Apply country-specific rules based on methodology document
    
    if (country == "ARG") {
      # Argentina: repetition structurally missing
      message("Argentina: Repetition structurally missing")
      if (!repetition_missing) {
        warning("Argentina has repetition_h data but methodology says it should be structurally missing")
      }
      next  # Skip Argentina - no repetition estimates
      
    } else if (country == "HND") {
      # Honduras: ED11 supports repetition_h for 2022-2024
      # Check if we have data for the appropriate years
      hnd_years <- unique(country_data$survey_year)
      valid_hnd_years <- hnd_years[hnd_years >= 2022]
      
      if (length(valid_hnd_years) == 0) {
        message("Honduras: No data for 2022-2024 (only have years: ", 
                paste(hnd_years, collapse = ", "), ")")
        next
      }
      
      if (repetition_missing) {
        warning("Honduras repetition_h is missing but should be available from ED11 for 2022-2024")
        next
      }
      
      message("Honduras: Repetition from ED11 (valid for 2022-2024)")
      
    } else if (country == "PRY") {
      # Paraguay: repetition structurally missing
      message("Paraguay: Repetition structurally missing")
      if (!repetition_missing) {
        warning("Paraguay has repetition_h data but methodology says it should be structurally missing")
      }
      next  # Skip Paraguay - no repetition estimates
      
    } else {
      # Default for other countries
      message(country, ": Checking for repetition data")
      if (repetition_missing) {
        message(country, ": repetition_h is completely missing")
        next
      }
    }
    
    # Estimate repetition rates for this country
    country_results <- estimate_repetition(country_data, ...)
    
    # Add country-specific metadata
    if (nrow(country_results) > 0) {
      country_results[, country_specific_notes := get_country_repetition_notes(country)]
      results_list[[country]] <- country_results
    }
  }
  
  # Combine results
  if (length(results_list) == 0) {
    message("No repetition rates generated (structural missingness for all countries)")
    return(data.table())
  }
  
  results <- data.table::rbindlist(results_list, fill = TRUE)
  
  # Verify per-year per-country structure
  summary_stats <- results[, .(
    n_estimates = .N,
    min_year = min(survey_year, na.rm = TRUE),
    max_year = max(survey_year, na.rm = TRUE)
  ), by = country_code]
  
  message("\nSummary of repetition estimates:")
  for (i in 1:nrow(summary_stats)) {
    message("  ", summary_stats$country_code[i], ": ", 
            summary_stats$n_estimates[i], " estimates (", 
            summary_stats$min_year[i], "-", summary_stats$max_year[i], ")")
  }
  
  return(results)
}

#' Get country-specific repetition estimation notes
#'
#' @param country_code Character country code
#'
#' @return Character string with country-specific notes
#' @export
get_country_repetition_notes <- function(country_code) {
  notes <- list(
    ARG = "Repetition structurally missing",
    HND = "Repetition from ED11 (valid for 2022-2024 only)",
    PRY = "Repetition structurally missing"
  )
  
  return(notes[[country_code]] %||% "Standard repetition estimation")
}

#' Estimate repetition rates for all available countries
#'
#' Main function for repetition rate estimation pipeline.
#' Produces CSV output with per-year per-country indicators.
#' Only computes for countries with validated repetition data.
#'
#' @param harmonized_data_path Path to harmonized data file (Parquet or CSV)
#' @param output_path Path to write output CSV (required)
#' @param years Numeric vector of years to process (default: all available)
#' @param countries Character vector of country codes to process (default: all available)
#' @param levels Character vector of education levels to estimate
#' @param include_se Logical indicating whether to include standard errors
#'
#' @return A data.table with repetition rate estimates per year per country
#' @export
run_repetition_estimation <- function(harmonized_data = NULL,
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
  
  # Estimate repetition rates per year per country
  message("\nEstimating repetition rates per year per country...")
  message("Note: Only Honduras 2022-2024 has validated repetition data (ED11)")
  
  repetition_rates <- estimate_repetition_country_specific(
    harmonized_data = harmonized_data,
    country_codes = countries,
    years = years,
    level = levels,
    group_vars = group_vars,
    include_se = include_se
  )
  
  # Write output CSV
  if (!is.null(output_path)) {
    message("\nWriting repetition rates to: ", output_path)
    data.table::fwrite(repetition_rates, output_path)
  }
  
  # Report summary
  if (nrow(repetition_rates) > 0) {
    unique_countries <- unique(repetition_rates$country_code)
    unique_years <- unique(repetition_rates$survey_year)
    message("\nGenerated ", nrow(repetition_rates), " repetition rate estimates")
    message("Countries with repetition data: ", paste(unique_countries, collapse = ", "))
    message("Years: ", paste(sort(unique_years), collapse = ", "))
    message("Levels: ", paste(unique(repetition_rates$level), collapse = ", "))
    
    # Show sample of output
    message("\nSample of output (first 5 rows):")
    print(repetition_rates[1:min(5, nrow(repetition_rates)), 
                           .(country_code, survey_year, level, rate)])
  } else {
    warning("No repetition rates were generated (structural missingness for all countries)")
  }
  
  return(repetition_rates)
}

# Helper function for NULL coalescing
`%||%` <- function(x, y) if (is.null(x)) y else x