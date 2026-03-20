#' Out-of-school rate estimator
#'
#' Implements out-of-school rate estimation according to UIS/VIEW methodology:
#' Complement of attendance rate over the same eligible universe.
#' Produces indicators per year per country.
#'
#' @param harmonized_data A data.table containing harmonized person-level data
#' @param attendance_rates Optional data.table with pre-computed attendance rates.
#'   If provided, out-of-school rates are computed as 1 - attendance rate.
#'   If NULL, attendance rates are computed internally.
#' @param level Character vector specifying education levels to estimate.
#'   Options: "primary", "lower_secondary", "upper_secondary", "tertiary"
#' @param group_vars Character vector of grouping variables (default: 
#'   c("country_code", "source_program", "survey_year", "wave_id"))
#' @param include_se Logical indicating whether to include standard errors
#'
#' @return A data.table with out-of-school rate estimates per year per country
#' @export
estimate_out_of_school <- function(harmonized_data,
                                   attendance_rates = NULL,
                                   level = c("primary", "lower_secondary", "upper_secondary"),
                                   group_vars = c("country_code", "source_program", "survey_year", "wave_id"),
                                   include_se = FALSE) {
  
  # Load utility functions
  source_path <- file.path(dirname(dirname(getwd())), "indicators", "utils", "weighted_rate.R")
  if (file.exists(source_path)) {
    source(source_path)
  }
  
  # Load attendance functions if needed
  attendance_path <- file.path(dirname(getwd()), "household", "attendance.R")
  if (file.exists(attendance_path)) {
    source(attendance_path)
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
  
  # Method 1: Compute from pre-computed attendance rates
  if (!is.null(attendance_rates)) {
    message("Computing out-of-school rates from pre-computed attendance rates")
    
    # Filter to requested levels
    if (!is.null(level)) {
      attendance_rates <- attendance_rates[level %in% level]
    }
    
    # Compute out-of-school as complement
    oos_rates <- copy(attendance_rates)
    
    # Update indicator information
    oos_rates[, indicator_id := "OOS_LVL"]
    oos_rates[, indicator_name := "Out-of-school rate"]
    
    # Compute out-of-school rate: 1 - attendance rate
    oos_rates[, rate := 1 - rate]
    
    # Update numerator and denominator (numerator becomes denominator - original numerator)
    if ("numerator" %in% names(oos_rates) && "denominator" %in% names(oos_rates)) {
      oos_rates[, numerator := denominator - numerator]
      oos_rates[, n_indicator := n_eligible - n_indicator]
    }
    
    # Update confidence intervals if present
    if (include_se && "ci_lower" %in% names(oos_rates) && "ci_upper" %in% names(oos_rates)) {
      # For complement, swap and invert bounds
      old_lower <- oos_rates$ci_lower
      old_upper <- oos_rates$ci_upper
      oos_rates[, ci_lower := 1 - old_upper]
      oos_rates[, ci_upper := 1 - old_lower]
    }
    
    return(oos_rates)
  }
  
  # Method 2: Compute directly from harmonized data
  message("Computing out-of-school rates directly from harmonized data")
  
  # Define level-specific age universes (based on UIS definitions)
  age_universes <- list(
    primary = c(6, 11),           # Ages 6-11
    lower_secondary = c(12, 14),  # Ages 12-14
    upper_secondary = c(15, 17),  # Ages 15-17
    tertiary = c(18, 24)          # Ages 18-24 (approximate)
  )
  
  # Define level codes in harmonized data
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
    
    # Define eligible universe: strictly based on Age
    eligible_condition <- function(dt) {
      return(dt$age_h >= age_range[1] & dt$age_h <= age_range[2])
    }
    
    # Define indicator condition: NOT attending ANY formal education
    indicator_condition <- function(dt) {
      # A child is out-of-school if attending_currently_h is 0 OR NA 
      # (treating non-response as out of school for this rate calculation)
      is_out <- dt$attending_currently_h == 0 | is.na(dt$attending_currently_h)
      return(is_out)
    }
    
    # Compute out-of-school rate directly
    if (include_se) {
      oos_rates <- weighted_rate_with_se(
        data = harmonized_data,
        eligible_condition = eligible_condition,
        indicator_condition = indicator_condition,
        weight_var = "weight_h",
        group_vars = group_vars,
        se_method = "binomial"
      )
    } else {
      oos_rates <- weighted_rate(
        data = harmonized_data,
        eligible_condition = eligible_condition,
        indicator_condition = indicator_condition,
        weight_var = "weight_h",
        group_vars = group_vars,
        include_counts = TRUE
      )
    }
    
    # Add level information
    oos_rates[, level := lvl]
    oos_rates[, indicator_id := "OOS_LVL"]
    oos_rates[, indicator_name := "Out-of-school rate"]
    oos_rates[, indicator_family := "household_core"]
    
    results_list[[lvl]] <- oos_rates
  }
  
  # Combine all levels
  if (length(results_list) == 0) {
    return(data.table())
  }
  
  results <- data.table::rbindlist(results_list, fill = TRUE)
  
  # Ensure we have per-year per-country structure
  unique_combos <- unique(results[, .(country_code, survey_year, level)])
  message("Generated ", nrow(unique_combos), " unique country-year-level out-of-school rate combinations")
  
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

#' Estimate out-of-school rates with country-specific adjustments
#'
#' Applies country-specific rules for out-of-school estimation based on methodology document
#' Produces indicators per year per country.
#'
#' @param harmonized_data A data.table containing harmonized person-level data
#' @param country_codes Character vector of country codes to process (default: all)
#' @param years Numeric vector of years to process (default: all)
#' @param use_attendance_complement Logical indicating whether to compute from attendance rates
#' @param ... Additional arguments passed to estimate_out_of_school
#'
#' @return A data.table with out-of-school rate estimates per year per country
#' @export
estimate_out_of_school_country_specific <- function(harmonized_data,
                                                    country_codes = NULL,
                                                    years = NULL,
                                                    use_attendance_complement = TRUE,
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
  
  message("Processing out-of-school rates for ", length(unique_countries), " countries: ", 
          paste(unique_countries, collapse = ", "))
  message("Processing years: ", paste(sort(unique_years), collapse = ", "))
  
  # Compute attendance rates if using complement method
  attendance_rates <- NULL
  if (use_attendance_complement) {
    message("Computing attendance rates as basis for out-of-school complement...")
    
    # Load attendance function
    attendance_path <- file.path(dirname(getwd()), "household", "attendance.R")
    if (file.exists(attendance_path)) {
      source(attendance_path)
      attendance_rates <- estimate_attendance_country_specific(
        harmonized_data = harmonized_data,
        country_codes = country_codes,
        years = years,
        ...
      )
    } else {
      warning("Attendance functions not found. Computing out-of-school rates directly.")
      use_attendance_complement <- FALSE
    }
  }
  
  results_list <- list()
  
  # Process each country separately to apply country-specific rules
  for (country in unique_countries) {
    country_data <- harmonized_data[country_code == country]
    
    # Apply country-specific rules based on methodology document
    
    if (country == "ARG") {
      # Argentina: OOS as complement of the (NA-corrected) attendance rate.
      # NA handling for attending_currently_h is applied inside estimate_attendance
      # via na_as_attending = TRUE; no additional pre-processing needed here.
      message("Argentina: Out-of-school as complement of CH08-based attendance")

    } else if (country == "HND") {
      # Honduras: attending_currently_h is direct_copy of ED03 (1=yes, 2=no).
      # Method 1 (complement) works correctly after the attendance eligible-universe
      # fix (age-only denominator).  For Method 2 robustness, recode 2 → 0.
      message("Honduras: Out-of-school as complement of ED03-based attendance")
      if (!use_attendance_complement) {
        country_data <- data.table::copy(country_data)
        country_data[, attending_currently_h := data.table::fifelse(
          attending_currently_h == 2L, 0L, attending_currently_h
        )]
      }

    } else if (country == "PRY") {
      # Paraguay: attending_currently_h is direct_copy of ED08 (1–18 = attending,
      # 19 = not attending).  Recode to binary so that attending_currently_h == 0
      # fires correctly in Method 2, and so Method 1 complement is consistent.
      message("Paraguay: Out-of-school as complement of ED08-based attendance (recoded to binary)")
      country_data <- data.table::copy(country_data)
      country_data[, attending_currently_h := data.table::fifelse(
        attending_currently_h == 19L, 0L,
        data.table::fifelse(is.na(attending_currently_h), NA_integer_, 1L)
      )]

    } else {
      # Default for other countries
      message(country, ": Using standard out-of-school estimation")
    }
    
    # Get country-specific attendance rates if using complement
    country_attendance <- NULL
    if (use_attendance_complement && !is.null(attendance_rates)) {
      country_attendance <- attendance_rates[country_code == country]
    }
    
    # Estimate out-of-school rates
    country_results <- estimate_out_of_school(
      harmonized_data = country_data,
      attendance_rates = country_attendance,
      ...
    )
    
    # Add country-specific metadata
    if (nrow(country_results) > 0) {
      country_results[, country_specific_notes := get_country_oos_notes(country)]
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
  
  message("\nSummary of out-of-school estimates:")
  for (i in 1:nrow(summary_stats)) {
    message("  ", summary_stats$country_code[i], ": ", 
            summary_stats$n_estimates[i], " estimates (", 
            summary_stats$min_year[i], "-", summary_stats$max_year[i], ")")
  }
  
  return(results)
}

#' Get country-specific out-of-school estimation notes
#'
#' @param country_code Character country code
#'
#' @return Character string with country-specific notes
#' @export
get_country_oos_notes <- function(country_code) {
  notes <- list(
    ARG = "Out-of-school as complement of CH08-based attendance",
    HND = "Out-of-school as complement of ED03-based attendance",
    PRY = "Out-of-school as complement of ED08-based attendance (current_level_h not validated)"
  )
  
  return(notes[[country_code]] %||% "Standard out-of-school estimation")
}

#' Estimate out-of-school rates for all available levels and countries
#'
#' Main function for out-of-school rate estimation pipeline.
#' Produces CSV output with per-year per-country indicators.
#'
#' @param harmonized_data_path Path to harmonized data file (Parquet or CSV)
#' @param output_path Path to write output CSV (required)
#' @param years Numeric vector of years to process (default: all available)
#' @param countries Character vector of country codes to process (default: all available)
#' @param levels Character vector of education levels to estimate
#' @param include_se Logical indicating whether to include standard errors
#' @param use_attendance_complement Logical indicating whether to compute from attendance rates
#'
#' @return A data.table with out-of-school rate estimates per year per country
#' @export
run_out_of_school_estimation <- function(harmonized_data = NULL,
                                         harmonized_data_path = NULL,
                                         output_path = NULL,
                                         years = NULL,
                                         countries = NULL,
                                         levels = c("primary", "lower_secondary", "upper_secondary"),
                                         group_vars = c("country_code", "source_program", "survey_year", "wave_id"),
                                         include_se = FALSE,
                                         use_attendance_complement = TRUE) {
  
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
  
  # Estimate out-of-school rates per year per country
  message("\nEstimating out-of-school rates per year per country...")
  oos_rates <- estimate_out_of_school_country_specific(
    harmonized_data = harmonized_data,
    country_codes = countries,
    years = years,
    use_attendance_complement = use_attendance_complement,
    level = levels,
    group_vars = group_vars,
    include_se = include_se
  )
  
  # Write output CSV
  if (!is.null(output_path)) {
    message("\nWriting out-of-school rates to: ", output_path)
    data.table::fwrite(oos_rates, output_path)
  }

  if (nrow(oos_rates) > 0) {
    # Get unique years for reporting
    unique_years <- unique(oos_rates$survey_year)

    # Report summary
    message("\n✓ Successfully generated ", nrow(oos_rates), " out-of-school rate estimates")
    message("Countries: ", paste(unique(oos_rates$country_code), collapse = ", "))
    message("Years: ", paste(sort(unique_years), collapse = ", "))
    message("Levels: ", paste(unique(oos_rates$level), collapse = ", "))
    
    # Show sample of output
    message("\nSample of output (first 5 rows):")
    print(oos_rates[1:min(5, nrow(oos_rates)),
                    .(country_code, survey_year, level, rate)])
  } else {
    warning("No out-of-school rates were generated")
  }
  
  return(oos_rates)
}

# Helper function for NULL coalescing
`%||%` <- function(x, y) if (is.null(x)) y else x
