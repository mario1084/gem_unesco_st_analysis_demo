#' Test script for indicator estimation pipeline
#'
#' This script tests the indicator estimation pipeline with synthetic data
#' to verify that all functions work correctly.

# Load required packages
library(data.table)

# Set up paths
SCRIPT_DIR <- dirname(sys.frame(1)$ofile)
if (is.null(SCRIPT_DIR)) SCRIPT_DIR <- getwd()

# Source indicator functions
source_files <- function(pattern, dir) {
  files <- list.files(dir, pattern = pattern, full.names = TRUE, recursive = TRUE)
  for (f in files) {
    source(f)
  }
}

# Source all indicator functions
INDICATORS_DIR <- file.path(SCRIPT_DIR, "indicators")
if (dir.exists(INDICATORS_DIR)) {
  source_files("\\.R$", file.path(INDICATORS_DIR, "utils"))
  source_files("\\.R$", file.path(INDICATORS_DIR, "household"))
  source_files("\\.R$", file.path(INDICATORS_DIR, "output"))
} else {
  stop("Indicators directory not found: ", INDICATORS_DIR)
}

#' Create synthetic harmonized data for testing
create_test_data <- function(n = 1000) {
  set.seed(123)
  
  # Create synthetic data
  test_data <- data.table(
    country_code = sample(c("ARG", "HND", "PRY"), n, replace = TRUE, prob = c(0.4, 0.3, 0.3)),
    source_program = "test",
    survey_year = sample(2021:2024, n, replace = TRUE),
    wave_id = paste0("W", sample(1:4, n, replace = TRUE)),
    weight_h = runif(n, 0.5, 2.0),
    age_h = sample(5:30, n, replace = TRUE),
    sex_h = sample(c("M", "F"), n, replace = TRUE),
    location_h = sample(c("urban", "rural"), n, replace = TRUE),
    
    # Education variables
    attending_currently_h = sample(c(0, 1), n, replace = TRUE, prob = c(0.2, 0.8)),
    current_level_h = sample(c(1, 2, 3, 4, NA), n, replace = TRUE, prob = c(0.3, 0.25, 0.2, 0.1, 0.15)),
    highest_level_completed_h = sample(c(0, 1, 2, 3, 4), n, replace = TRUE, prob = c(0.1, 0.3, 0.25, 0.2, 0.15)),
    highest_grade_completed_h = sample(0:12, n, replace = TRUE),
    
    # Literacy (available for some countries)
    literacy_h = sample(c(0, 1, NA), n, replace = TRUE, prob = c(0.1, 0.8, 0.1)),
    
    # Repetition (only available for Honduras 2022-2024)
    repetition_h = sample(c(0, 1, NA), n, replace = TRUE, prob = c(0.85, 0.1, 0.05))
  )
  
  # Apply country-specific patterns
  test_data[country_code == "ARG", literacy_h := NA]  # Argentina: literacy structurally missing
  test_data[country_code == "ARG", repetition_h := NA]  # Argentina: repetition structurally missing
  
  test_data[country_code == "PRY", repetition_h := NA]  # Paraguay: repetition structurally missing
  
  # Honduras 2022-2024 has repetition data
  test_data[country_code == "HND" & survey_year >= 2022 & survey_year <= 2024, 
            repetition_h := sample(c(0, 1), sum(country_code == "HND" & survey_year >= 2022 & survey_year <= 2024), 
                                   replace = TRUE, prob = c(0.9, 0.1))]
  
  return(test_data)
}

#' Test weighted rate utility function
test_weighted_rate <- function() {
  message("Testing weighted_rate utility function...")
  
  test_data <- create_test_data(500)
  
  # Define simple conditions
  eligible_condition <- function(dt) dt$age_h >= 6 & dt$age_h <= 11
  indicator_condition <- function(dt) dt$attending_currently_h == 1
  
  result <- weighted_rate(
    data = test_data,
    eligible_condition = eligible_condition,
    indicator_condition = indicator_condition,
    weight_var = "weight_h",
    group_vars = c("country_code", "survey_year"),
    include_counts = TRUE
  )
  
  if (nrow(result) > 0) {
    message("✓ weighted_rate function works")
    message("  Generated ", nrow(result), " rate estimates")
    return(TRUE)
  } else {
    warning("✗ weighted_rate function failed")
    return(FALSE)
  }
}

#' Test attendance rate estimator
test_attendance <- function() {
  message("\nTesting attendance rate estimator...")
  
  test_data <- create_test_data(1000)
  
  result <- estimate_attendance(
    harmonized_data = test_data,
    level = c("primary", "lower_secondary"),
    group_vars = c("country_code", "survey_year"),
    include_se = FALSE
  )
  
  if (nrow(result) > 0) {
    message("✓ attendance rate estimator works")
    message("  Generated ", nrow(result), " attendance rate estimates")
    return(TRUE)
  } else {
    warning("✗ attendance rate estimator failed")
    return(FALSE)
  }
}

#' Test out-of-school rate estimator
test_out_of_school <- function() {
  message("\nTesting out-of-school rate estimator...")
  
  test_data <- create_test_data(1000)
  
  result <- estimate_out_of_school(
    harmonized_data = test_data,
    level = c("primary", "lower_secondary"),
    group_vars = c("country_code", "survey_year"),
    include_se = FALSE
  )
  
  if (nrow(result) > 0) {
    message("✓ out-of-school rate estimator works")
    message("  Generated ", nrow(result), " out-of-school rate estimates")
    return(TRUE)
  } else {
    warning("✗ out-of-school rate estimator failed")
    return(FALSE)
  }
}

#' Test completion rate estimator
test_completion <- function() {
  message("\nTesting completion rate estimator...")
  
  test_data <- create_test_data(1000)
  
  result <- estimate_completion(
    harmonized_data = test_data,
    level = c("primary", "lower_secondary"),
    group_vars = c("country_code", "survey_year"),
    include_se = FALSE
  )
  
  if (nrow(result) > 0) {
    message("✓ completion rate estimator works")
    message("  Generated ", nrow(result), " completion rate estimates")
    return(TRUE)
  } else {
    warning("✗ completion rate estimator failed")
    return(FALSE)
  }
}

#' Test literacy rate estimator
test_literacy <- function() {
  message("\nTesting literacy rate estimator...")
  
  test_data <- create_test_data(1000)
  
  result <- estimate_literacy(
    harmonized_data = test_data,
    age_universe = c(15, 24),
    group_vars = c("country_code", "survey_year"),
    include_se = FALSE
  )
  
  if (nrow(result) > 0) {
    message("✓ literacy rate estimator works")
    message("  Generated ", nrow(result), " literacy rate estimates")
    return(TRUE)
  } else {
    warning("✗ literacy rate estimator failed")
    return(FALSE)
  }
}

#' Test repetition rate estimator
test_repetition <- function() {
  message("\nTesting repetition rate estimator...")
  
  test_data <- create_test_data(1000)
  
  result <- estimate_repetition(
    harmonized_data = test_data,
    level = c("primary", "lower_secondary"),
    group_vars = c("country_code", "survey_year"),
    include_se = FALSE
  )
  
  if (nrow(result) > 0) {
    message("✓ repetition rate estimator works")
    message("  Generated ", nrow(result), " repetition rate estimates")
    return(TRUE)
  } else {
    warning("✗ repetition rate estimator failed")
    return(FALSE)
  }
}

#' Test post-secondary review
test_postsecondary_review <- function() {
  message("\nTesting post-secondary review...")
  
  test_data <- create_test_data(500)
  
  result <- review_postsecondary(
    harmonized_data = test_data,
    country_codes = c("ARG", "HND"),
    years = c(2023, 2024),
    group_vars = c("country_code", "source_program", "survey_year", "wave_id")
  )
  
  if (nrow(result) > 0) {
    message("✓ post-secondary review works")
    message("  Generated ", nrow(result), " review results")
    return(TRUE)
  } else {
    warning("✗ post-secondary review failed")
    return(FALSE)
  }
}

#' Test output format writers
test_output_writers <- function() {
  message("\nTesting output format writers...")
  
  # Create test indicator data
  test_data <- create_test_data(1000)
  
  attendance_rates <- estimate_attendance(
    harmonized_data = test_data,
    level = c("primary"),
    group_vars = c("country_code", "survey_year"),
    include_se = FALSE
  )
  
  if (nrow(attendance_rates) == 0) {
    warning("No attendance rates to test output writers")
    return(FALSE)
  }
  
  # Create temporary output directory
  temp_dir <- file.path(tempdir(), "test_indicators_output")
  if (!dir.exists(temp_dir)) {
    dir.create(temp_dir, recursive = TRUE)
  }
  
  # Test writing CSV
  output_files <- write_household_indicators_csv(
    indicator_data = attendance_rates,
    output_dir = temp_dir,
    combine = TRUE,
    per_country_year = FALSE
  )
  
  if (length(output_files) > 0 && file.exists(output_files[[1]])) {
    message("✓ output format writers work")
    message("  Created output file: ", output_files[[1]])
    
    # Clean up
    unlink(temp_dir, recursive = TRUE)
    return(TRUE)
  } else {
    warning("✗ output format writers failed")
    return(FALSE)
  }
}

#' Run all tests
run_all_tests <- function() {
  message(strrep("=", 60))
  message("RUNNING INDICATOR PIPELINE TESTS")
  message(strrep("=", 60))
  
  test_results <- list(
    weighted_rate = test_weighted_rate(),
    attendance = test_attendance(),
    out_of_school = test_out_of_school(),
    completion = test_completion(),
    literacy = test_literacy(),
    repetition = test_repetition(),
    postsecondary_review = test_postsecondary_review(),
    output_writers = test_output_writers()
  )
  
  # Summary
  message("\n" + strrep("=", 60))
  message("TEST SUMMARY")
  message(strrep("=", 60))
  
  passed <- sum(unlist(test_results))
  total <- length(test_results)
  
  for (test_name in names(test_results)) {
    status <- if (test_results[[test_name]]) "✓ PASS" else "✗ FAIL"
    message(sprintf("  %-25s: %s", test_name, status))
  }
  
  message("\nTotal: ", passed, "/", total, " tests passed")
  
  if (passed == total) {
    message("\n" + strrep("=", 60))
    message("✓ ALL TESTS PASSED - PIPELINE IS FUNCTIONAL")
    message(strrep("=", 60))
    return(TRUE)
  } else {
    message("\n" + strrep("=", 60))
    message("✗ SOME TESTS FAILED - CHECK IMPLEMENTATION")
    message(strrep("=", 60))
    return(FALSE)
  }
}

# Run tests if script is executed directly
if (sys.nframe() == 0) {
  success <- run_all_tests()
  quit(save = "no", status = if (success) 0 else 1)
}