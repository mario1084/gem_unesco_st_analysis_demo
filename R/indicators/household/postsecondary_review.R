#' Post-secondary review procedure
#'
#' Implements post-secondary review according to methodology document:
#' Source-review and publication-readiness procedure for tertiary/post-secondary indicators.
#' Not a published estimator, but a review of data availability and comparability.
#' Produces review results per year per country.
#'
#' @param harmonized_data A data.table containing harmonized person-level data
#' @param country_codes Character vector of country codes to review (default: all)
#' @param years Numeric vector of years to review (default: all)
#' @param group_vars Character vector of grouping variables (default: 
#'   c("country_code", "source_program", "survey_year", "wave_id"))
#'
#' @return A data.table with post-secondary review results per year per country
#' @export
review_postsecondary <- function(harmonized_data,
                                 country_codes = NULL,
                                 years = NULL,
                                 group_vars = c("country_code", "source_program", "survey_year", "wave_id")) {
  
  # Ensure data.table
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
  
  # Get unique country-year combinations
  unique_combos <- unique(harmonized_data[, .SD, .SDcols = group_vars])
  
  if (nrow(unique_combos) == 0) {
    message("No data for the specified country/year combinations")
    return(data.table())
  }
  
  message("Reviewing post-secondary support for ", nrow(unique_combos), " country-year combinations")
  
  # Initialize results list
  results_list <- list()
  
  # Review each combination
  for (i in 1:nrow(unique_combos)) {
    combo <- unique_combos[i]
    
    # Filter data for this combination
    combo_data <- harmonized_data
    for (var in group_vars) {
      if (var %in% names(combo)) {
        combo_data <- combo_data[get(var) == combo[[var]]]
      }
    }
    
    # Apply review rules from methodology document
    review_result <- review_postsecondary_combo(combo_data, combo)
    
    results_list[[i]] <- review_result
  }
  
  # Combine results
  results <- data.table::rbindlist(results_list, fill = TRUE)
  
  # Summary statistics
  if (nrow(results) > 0) {
    publishable_count <- sum(results$publishable, na.rm = TRUE)
    message("\nPost-secondary review complete:")
    message("  Total combinations reviewed: ", nrow(results))
    message("  Publishable: ", publishable_count)
    message("  Not publishable: ", nrow(results) - publishable_count)
    
    # Show countries with publishable post-secondary data
    publishable_countries <- unique(results[publishable == TRUE]$country_code)
    if (length(publishable_countries) > 0) {
      message("  Countries with publishable post-secondary data: ", 
              paste(publishable_countries, collapse = ", "))
    }
  }
  
  return(results)
}

#' Review post-secondary support for a single country-year combination
#'
#' @param combo_data Data for a single country-year combination
#' @param combo_info data.table row with combination information
#'
#' @return data.table with review results
review_postsecondary_combo <- function(combo_data, combo_info) {
  
  # Extract country and year
  country <- combo_info$country_code
  year <- combo_info$survey_year
  
  # Initialize review components
  # E: whether post-secondary/tertiary construct is present
  E_ps <- check_ps_construct_presence(combo_data, country, year)
  
  # V: whether variable block is sufficiently documented
  V_ps <- check_ps_variable_documentation(combo_data, country, year)
  
  # C: comparability status
  C_ps <- assess_ps_comparability(combo_data, country, year)
  
  # Determine publishability
  publishable <- (E_ps == 1) && (V_ps == 1) && (C_ps != "non-comparable")
  
  # Create result row
  result <- data.table(
    country_code = country,
    source_program = combo_info$source_program,
    survey_year = year,
    wave_id = combo_info$wave_id,
    postsecondary_construct_present = E_ps,
    variable_block_documented = V_ps,
    comparability_status = C_ps,
    publishable = publishable,
    review_notes = get_country_ps_review_notes(country, year, E_ps, V_ps, C_ps, publishable)
  )
  
  return(result)
}

#' Check if post-secondary/tertiary construct is present
#'
#' @param data Country-year data
#' @param country Country code
#' @param year Survey year
#'
#' @return 1 if present, 0 otherwise
check_ps_construct_presence <- function(data, country, year) {
  
  # Check for tertiary level codes in current_level_h or highest_level_completed_h
  tertiary_codes <- c(4, 5, 6)  # Assuming 4=tertiary, 5=post-secondary, 6=higher education
  
  has_current_tertiary <- FALSE
  has_completed_tertiary <- FALSE
  
  if ("current_level_h" %in% names(data)) {
    current_levels <- unique(data$current_level_h)
    has_current_tertiary <- any(current_levels %in% tertiary_codes, na.rm = TRUE)
  }
  
  if ("highest_level_completed_h" %in% names(data)) {
    completed_levels <- unique(data$highest_level_completed_h)
    has_completed_tertiary <- any(completed_levels %in% tertiary_codes, na.rm = TRUE)
  }
  
  # Country-specific checks based on methodology document
  if (country == "ARG") {
    # Argentina: check NIVEL_ED and related state/status variables
    # This is a simplified check - actual implementation would need to examine raw variables
    return(as.integer(has_current_tertiary || has_completed_tertiary))
    
  } else if (country == "HND") {
    # Honduras: check ED05/ED08/ED10 ladder for tertiary codes
    return(as.integer(has_current_tertiary || has_completed_tertiary))
    
  } else if (country == "PRY") {
    # Paraguay: check ED0504 and any current-study level fields
    # No validated direct current_level_h field in active harmonization
    return(as.integer(has_completed_tertiary))  # Only completed level might be available
    
  } else {
    # Default check
    return(as.integer(has_current_tertiary || has_completed_tertiary))
  }
}

#' Check if post-secondary variable block is sufficiently documented
#'
#' @param data Country-year data
#' @param country Country code
#' @param year Survey year
#'
#' @return 1 if documented, 0 otherwise
check_ps_variable_documentation <- function(data, country, year) {
  
  # This would ideally check codebook or metadata
  # For now, we check if we have the necessary variables
  
  required_vars <- c()
  
  if (country == "ARG") {
    # Argentina: need NIVEL_ED and related variables
    required_vars <- c("current_level_h", "highest_level_completed_h")
    
  } else if (country == "HND") {
    # Honduras: need ED05, ED08, ED10 or their harmonized equivalents
    required_vars <- c("current_level_h", "highest_level_completed_h", "highest_grade_completed_h")
    
  } else if (country == "PRY") {
    # Paraguay: need ED0504 or its split components
    required_vars <- c("highest_level_completed_h", "highest_grade_completed_h")
    
  } else {
    # Default: check for standard variables
    required_vars <- c("current_level_h", "highest_level_completed_h")
  }
  
  # Check if all required variables are present and not completely missing
  all_present <- all(required_vars %in% names(data))
  
  if (!all_present) {
    return(0L)
  }
  
  # Check if variables have non-missing values for tertiary levels
  tertiary_codes <- c(4, 5, 6)
  
  has_tertiary_data <- FALSE
  for (var in required_vars) {
    if (var %in% names(data)) {
      values <- unique(data[[var]])
      if (any(values %in% tertiary_codes, na.rm = TRUE)) {
        has_tertiary_data <- TRUE
        break
      }
    }
  }
  
  return(as.integer(has_tertiary_data))
}

#' Assess post-secondary comparability
#'
#' @param data Country-year data
#' @param country Country code
#' @param year Survey year
#'
#' @return "direct", "partial", or "non-comparable"
assess_ps_comparability <- function(data, country, year) {
  
  # This is a simplified implementation
  # Actual comparability assessment would require cross-wave and cross-country analysis
  
  if (country == "ARG") {
    # Argentina: need to check wave stability across 2021-2024
    if (year >= 2021 && year <= 2024) {
      # Within the demo window, assume partial comparability
      return("partial")
    } else {
      return("non-comparable")
    }
    
  } else if (country == "HND") {
    # Honduras: check for explicit tertiary level codes
    if (check_ps_construct_presence(data, country, year) == 1) {
      return("direct")
    } else {
      return("non-comparable")
    }
    
  } else if (country == "PRY") {
    # Paraguay: no validated direct current_level_h field
    # Only completed level might be comparable
    if (check_ps_variable_documentation(data, country, year) == 1) {
      return("partial")
    } else {
      return("non-comparable")
    }
    
  } else {
    # Default: assume partial comparability if data exists
    if (check_ps_construct_presence(data, country, year) == 1 &&
        check_ps_variable_documentation(data, country, year) == 1) {
      return("partial")
    } else {
      return("non-comparable")
    }
  }
}

#' Get country-specific post-secondary review notes
#'
#' @param country Country code
#' @param year Survey year
#' @param E_ps Construct presence (0/1)
#' @param V_ps Variable documentation (0/1)
#' @param C_ps Comparability status
#' @param publishable Whether publishable
#'
#' @return Character string with review notes
get_country_ps_review_notes <- function(country, year, E_ps, V_ps, C_ps, publishable) {
  
  base_notes <- paste(
    "Construct present:", E_ps,
    "| Documented:", V_ps,
    "| Comparability:", C_ps,
    "| Publishable:", publishable
  )
  
  country_notes <- list(
    ARG = "Review NIVEL_ED and state variables for tertiary mapping; requires wave-stability across 2021-2024",
    HND = "Review ED05/ED08/ED10 ladder for explicit tertiary codes",
    PRY = "No validated direct current_level_h field; review ED0504 for tertiary attainment evidence"
  )
  
  country_note <- country_notes[[country]] %||% "Standard post-secondary review"
  
  return(paste(country_note, "|", base_notes))
}

#' Run post-secondary review for all available countries and years
#'
#' Main function for post-secondary review pipeline.
#' Produces CSV output with review results per year per country.
#'
#' @param harmonized_data_path Path to harmonized data file (Parquet or CSV)
#' @param output_path Path to write output CSV (required)
#' @param years Numeric vector of years to review (default: all available)
#' @param countries Character vector of country codes to review (default: all available)
#'
#' @return A data.table with post-secondary review results per year per country
#' @export
run_postsecondary_review <- function(harmonized_data = NULL,
                                     harmonized_data_path = NULL,
                                     output_path = NULL,
                                     years = NULL,
                                     countries = NULL,
                                     group_vars = c("country_code", "source_program", "survey_year", "wave_id")) {
  
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
  
  # Run post-secondary review per year per country
  message("\nRunning post-secondary review per year per country...")
  review_results <- review_postsecondary(
    harmonized_data = harmonized_data,
    country_codes = countries,
    years = years,
    group_vars = group_vars
  )
  
  # Write output CSV
  if (!is.null(output_path)) {
    message("\nWriting post-secondary review results to: ", output_path)
    data.table::fwrite(review_results, output_path)
  }
  
  # Report summary
  if (nrow(review_results) > 0) {
    unique_countries <- unique(review_results$country_code)
    unique_years <- unique(review_results$survey_year)
    message("\nGenerated ", nrow(review_results), " post-secondary review results")
    message("Countries reviewed: ", paste(unique_countries, collapse = ", "))
    message("Years reviewed: ", paste(sort(unique_years), collapse = ", "))
    
    # Show publishability summary by country
    publish_summary <- review_results[, .(
      n_combinations = .N,
      n_publishable = sum(publishable, na.rm = TRUE),
      publishable_pct = round(100 * sum(publishable, na.rm = TRUE) / .N, 1)
    ), by = country_code]
    
    message("\nPublishability summary by country:")
    for (i in 1:nrow(publish_summary)) {
      msg <- sprintf("  %s: %d/%d (%.1f%%) publishable",
                     publish_summary$country_code[i],
                     publish_summary$n_publishable[i],
                     publish_summary$n_combinations[i],
                     publish_summary$publishable_pct[i])
      message(msg)
    }
    
    # Show sample of output
    message("\nSample of output (first 5 rows):")
    print(review_results[1:min(5, nrow(review_results)), 
                         .(country_code, survey_year, publishable, comparability_status)])
  } else {
    warning("No post-secondary review results were generated")
  }
  
  return(review_results)
}

# Helper function for NULL coalescing
`%||%` <- function(x, y) if (is.null(x)) y else x