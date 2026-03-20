#' Literacy rate estimator
#'
#' Implements literacy rate estimation according to UIS methodology:
#' Weighted share of population that is literate over appropriate age universe.
#' Only computed where direct literacy item exists in survey.
#' Produces indicators per year per country.
#'
#' @param harmonized_data A data.table containing harmonized person-level data
#' @param age_universe Numeric vector of length 2 specifying age range for literacy rate.
#'   Default: c(15, 24) for youth literacy (15-24 years)
#' @param group_vars Character vector of grouping variables (default: 
#'   c("country_code", "source_program", "survey_year", "wave_id"))
#' @param include_se Logical indicating whether to include standard errors
#'
#' @return A data.table with literacy rate estimates per year per country
#' @export
estimate_literacy <- function(harmonized_data,
                              age_universe = c(15, 24),
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
  required_vars <- c("age_h", "literacy_h", "weight_h",
                     "country_code", "source_program", "survey_year", "wave_id")
  missing_vars <- setdiff(required_vars, names(harmonized_data))
  if (length(missing_vars) > 0) {
    stop("Missing required variables: ", paste(missing_vars, collapse = ", "))
  }
  
  # Verify we have year and country grouping
  if (!all(c("country_code", "survey_year") %in% group_vars)) {
    warning("Grouping variables should include 'country_code' and 'survey_year' for per-year per-country estimates")
  }
  
  # Check if literacy_h variable exists and has valid values
  if (!"literacy_h" %in% names(harmonized_data)) {
    stop("literacy_h variable not found in harmonized data")
  }
  
  # Check for structural missingness
  literacy_missing <- all(is.na(harmonized_data$literacy_h))
  if (literacy_missing) {
    warning("literacy_h is completely missing (structural missingness). No literacy rates can be computed.")
    return(data.table())
  }
  
  # Define eligible universe: age in specified range
  eligible_condition <- function(dt) {
    return(dt$age_h >= age_universe[1] & dt$age_h <= age_universe[2])
  }
  
  # Define indicator condition: literate (literacy_h == 1)
  indicator_condition <- function(dt) {
    # literacy_h should be 1 for literate, 0 for not literate
    return(dt$literacy_h == 1)
  }
  
  # Compute literacy rate
  if (include_se) {
    literacy_rates <- weighted_rate_with_se(
      data = harmonized_data,
      eligible_condition = eligible_condition,
      indicator_condition = indicator_condition,
      weight_var = "weight_h",
      group_vars = group_vars,
      se_method = "binomial"
    )
  } else {
    literacy_rates <- weighted_rate(
      data = harmonized_data,
      eligible_condition = eligible_condition,
      indicator_condition = indicator_condition,
      weight_var = "weight_h",
      group_vars = group_vars,
      include_counts = TRUE
    )
  }
  
  # Add indicator information
  literacy_rates[, indicator_id := "LIT_RATE"]
  literacy_rates[, indicator_name := "Literacy rate"]
  literacy_rates[, indicator_family := "household_core"]
  literacy_rates[, age_range := paste(age_universe, collapse = "-")]
  
  # Ensure we have per-year per-country structure
  unique_combos <- unique(literacy_rates[, .(country_code, survey_year)])
  message("Generated ", nrow(unique_combos), " unique country-year literacy rate combinations")
  
  # Reorder columns
  base_cols <- c("country_code", "source_program", "survey_year", "wave_id", 
                 "age_range", "indicator_id", "indicator_name", "indicator_family",
                 "rate")
  
  if (include_se) {
    base_cols <- c(base_cols, "se", "ci_lower", "ci_upper")
  }
  
  if ("numerator" %in% names(literacy_rates)) {
    base_cols <- c(base_cols, "numerator", "denominator", "n_eligible", "n_indicator")
  }
  
  # Ensure all columns exist
  existing_cols <- intersect(base_cols, names(literacy_rates))
  other_cols <- setdiff(names(literacy_rates), existing_cols)
  
  literacy_rates <- literacy_rates[, c(existing_cols, other_cols), with = FALSE]
  
  return(literacy_rates)
}

#' Estimate literacy rates with country-specific adjustments
#'
#' Applies country-specific rules for literacy estimation based on methodology document
#' Handles structural missingness for countries without literacy items.
#' Produces indicators per year per country.
#'
#' @param harmonized_data A data.table containing harmonized person-level data
#' @param country_codes Character vector of country codes to process (default: all)
#' @param years Numeric vector of years to process (default: all)
#' @param ... Additional arguments passed to estimate_literacy
#'
#' @return A data.table with literacy rate estimates per year per country
#' @export
estimate_literacy_country_specific <- function(harmonized_data,
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
  
  message("Processing literacy rates for ", length(unique_countries), " countries: ", 
          paste(unique_countries, collapse = ", "))
  message("Processing years: ", paste(sort(unique_years), collapse = ", "))
  
  results_list <- list()
  
  # Process each country separately to apply country-specific rules
  for (country in unique_countries) {
    country_data <- harmonized_data[country_code == country]
    
    # Check for structural missingness in literacy_h
    literacy_missing <- all(is.na(country_data$literacy_h))
    
    # Apply country-specific rules based on methodology document
    
    if (country == "ARG") {
      # Argentina: literacy remains structurally missing
      message("Argentina: Literacy structurally missing (no direct literacy item)")
      if (!literacy_missing) {
        warning("Argentina has literacy_h data but methodology says it should be structurally missing")
      }
      next  # Skip Argentina - no literacy estimates
      
    } else if (country == "HND") {
      # Honduras: ED01 supports literacy_h
      message("Honduras: Literacy from ED01")
      if (literacy_missing) {
        warning("Honduras literacy_h is missing but should be available from ED01")
        next
      }
      
    } else if (country == "PRY") {
      # Paraguay: ED02 supports literacy_h
      message("Paraguay: Literacy from ED02")
      if (literacy_missing) {
        warning("Paraguay literacy_h is missing but should be available from ED02")
        next
      }
      
    } else {
      # Default for other countries
      message(country, ": Using standard literacy estimation")
      if (literacy_missing) {
        warning(country, ": literacy_h is completely missing")
        next
      }
    }
    
    # Estimate literacy rates for this country
    country_results <- estimate_literacy(country_data, ...)
    
    # Add country-specific metadata
    if (nrow(country_results) > 0) {
      country_results[, country_specific_notes := get_country_literacy_notes(country)]
      results_list[[country]] <- country_results
    }
  }
  
  # Combine results
  if (length(results_list) == 0) {
    message("No literacy rates generated (structural missingness for all countries)")
    return(data.table())
  }
  
  results <- data.table::rbindlist(results_list, fill = TRUE)
  
  # Verify per-year per-country structure
  summary_stats <- results[, .(
    n_estimates = .N,
    min_year = min(survey_year, na.rm = TRUE),
    max_year = max(survey_year, na.rm = TRUE)
  ), by = country_code]
  
  message("\nSummary of literacy estimates:")
  for (i in 1:nrow(summary_stats)) {
    message("  ", summary_stats$country_code[i], ": ", 
            summary_stats$n_estimates[i], " estimates (", 
            summary_stats$min_year[i], "-", summary_stats$max_year[i], ")")
  }
  
  return(results)
}

#' Get country-specific literacy estimation notes
#'
#' @param country_code Character country code
#'
#' @return Character string with country-specific notes
#' @export
get_country_literacy_notes <- function(country_code) {
  notes <- list(
    ARG = "Literacy structurally missing in verified EPH stack",
    HND = "Literacy from ED01",
    PRY = "Literacy from ED02"
  )
  
  return(notes[[country_code]] %||% "Standard literacy estimation")
}

#' Estimate literacy rates for all available countries
#'
#' Main function for literacy rate estimation pipeline.
#' Produces CSV output with per-year per-country indicators.
#' Skips countries with structural missingness.
#'
#' @param harmonized_data_path Path to harmonized data file (Parquet or CSV)
#' @param output_path Path to write output CSV (required)
#' @param years Numeric vector of years to process (default: all available)
#' @param countries Character vector of country codes to process (default: all available)
#' @param age_universe Numeric vector of length 2 specifying age range
#' @param include_se Logical indicating whether to include standard errors
#'
#' @return A data.table with literacy rate estimates per year per country
#' @export
run_literacy_estimation <- function(harmonized_data = NULL,
                                    harmonized_data_path = NULL,
                                    output_path = NULL,
                                    years = NULL,
                                    countries = NULL,
                                    age_universe = c(15, 24),
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
  
  # Estimate literacy rates per year per country
  message("\nEstimating literacy rates per year per country...")
  message("Age universe: ", age_universe[1], "-", age_universe[2], " years")
  
  literacy_rates <- estimate_literacy_country_specific(
    harmonized_data = harmonized_data,
    country_codes = countries,
    years = years,
    age_universe = age_universe,
    group_vars = group_vars,
    include_se = include_se
  )
  
  # Write output CSV
  if (!is.null(output_path)) {
    message("\nWriting literacy rates to: ", output_path)
    data.table::fwrite(literacy_rates, output_path)
  }
  
  # Report summary
  if (nrow(literacy_rates) > 0) {
    unique_countries <- unique(literacy_rates$country_code)
    unique_years <- unique(literacy_rates$survey_year)
    message("\nGenerated ", nrow(literacy_rates), " literacy rate estimates")
    message("Countries with literacy data: ", paste(unique_countries, collapse = ", "))
    message("Years: ", paste(sort(unique_years), collapse = ", "))
    
    # Show sample of output
    message("\nSample of output (first 5 rows):")
    print(literacy_rates[1:min(5, nrow(literacy_rates)), 
                         .(country_code, survey_year, age_range, rate)])
  } else {
    warning("No literacy rates were generated (structural missingness for all countries)")
  }
  
  return(literacy_rates)
}

# Helper function for NULL coalescing
`%||%` <- function(x, y) if (is.null(x)) y else x