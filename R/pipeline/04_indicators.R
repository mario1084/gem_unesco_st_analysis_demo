#' 03_indicators.R - Main orchestration script for indicator estimation
#'
#' This script runs the complete indicator estimation pipeline for the
#' gem_unesco_st_analysis_demo repository. It produces a comprehensive set of indicators
#' including household core, learning, admin/reference, and finance layers.
#'
#' Usage:
#'   Rscript 03_indicators.R [options]
#'
#' Options:
#'   --harmonized_data_path PATH  Path to harmonized data file
#'   --raw_data_dir DIR           Path to raw source-native data directory
#'   --output_dir DIR             Output directory for indicator files
#'   --years YEAR1,YEAR2,...      Years to process for household data (default: all)
#'   --countries CODE1,CODE2,...  Countries to process for household data (default: all)
#'   --include_se                 Include standard errors in household output
#'   --help                       Show this help message
#'
#' Example:
#'   Rscript 03_indicators.R \
#'     --harmonized_data_path "data/interim/harmonized/persons_harmonized.parquet" \
#'     --raw_data_dir "data/raw" \
#'     --output_dir "output/indicators" \
#'     --years "2021,2022,2023,2024" \
#'     --countries "ARG,HND,PRY"

# Load required packages
suppressPackageStartupMessages({
  library(data.table)
  library(arrow, quietly = TRUE)
  library(future)
  library(furrr)
  library(progressr)
  library(magrittr)
})

# Set up paths
# Get script path in a way that works with Rscript
args <- commandArgs(trailingOnly = FALSE)
file_arg <- "--file="
script_path <- sub(file_arg, "", args[grep(file_arg, args)])
SCRIPT_DIR <- dirname(script_path)
PIPELINE_DIR <- dirname(SCRIPT_DIR)
REPO_ROOT <- dirname(PIPELINE_DIR)

# Source indicator functions
source_files <- function(pattern, dir) {
  files <- list.files(dir, pattern = pattern, full.names = TRUE, recursive = TRUE)
  for (f in files) {
    source(f)
  }
}

# Source all indicator functions
INDICATORS_DIR <- file.path(REPO_ROOT, "R", "indicators")
if (dir.exists(INDICATORS_DIR)) {
  # Household core indicators
  source_files("\\.R$", file.path(INDICATORS_DIR, "utils"))
  source_files("\\.R$", file.path(INDICATORS_DIR, "household"))
  source_files("\\.R$", file.path(INDICATORS_DIR, "output"))
  # New integration layers
  source_files("\\.R$", file.path(INDICATORS_DIR, "learning"))
  source_files("\\.R$", file.path(INDICATORS_DIR, "admin_reference"))
  source_files("\\.R$", file.path(INDICATORS_DIR, "finance"))
} else {
  stop("Indicators directory not found: ", INDICATORS_DIR)
}

#' Parse command line arguments
parse_args <- function() {
  args <- commandArgs(trailingOnly = TRUE)

  # Default values
  config <- list(
    harmonized_data_path = "data/interim/harmonized/persons_harmonized.parquet",
    raw_data_dir = "data/raw",
    output_dir = "output/indicators",
    years = NULL,
    countries = NULL,
    include_se = FALSE,
    run_household = TRUE,
    run_learning = TRUE,
    run_admin_reference = TRUE,
    run_finance = TRUE,
    disaggregate_by = "sex_h,location_h"
  )

  i <- 1
  while (i <= length(args)) {
    arg <- args[i]

    if (arg == "--harmonized_data_path" && i + 1 <= length(args)) {
      config$harmonized_data_path <- args[i + 1]
      i <- i + 2
    } else if (arg == "--raw_data_dir" && i + 1 <= length(args)) {
      config$raw_data_dir <- args[i + 1]
      i <- i + 2
    } else if (arg == "--output_dir" && i + 1 <= length(args)) {
      config$output_dir <- args[i + 1]
      i <- i + 2
    } else if (arg == "--years" && i + 1 <= length(args)) {
      config$years <- as.numeric(strsplit(args[i + 1], ",")[[1]])
      i <- i + 2
    } else if (arg == "--countries" && i + 1 <= length(args)) {
      config$countries <- strsplit(args[i + 1], ",")[[1]]
      i <- i + 2
    } else if (arg == "--include_se") {
      config$include_se <- TRUE
      i <- i + 1
    } else if (arg == "--disaggregate_by" && i + 1 <= length(args)) {
      config$disaggregate_by <- args[i + 1]
      i <- i + 2
    } else if (arg == "--help") {
      cat(get_help_message())
      quit(save = "no", status = 0)
    } else {
      # Add flags to skip layers
      if(grepl("--no-", arg)) {
          clean_arg = sub("--no-", "run_", arg)
          if(clean_arg %in% names(config)) {
              config[[clean_arg]] <- FALSE
          }
      }
      i <- i + 1
    }
  }

  return(config)
}


#' Get help message
get_help_message <- function() {
  help_text <- '
03_indicators.R - Main orchestration script for indicator estimation

This script runs the complete indicator estimation pipeline, producing household,
learning, admin, and finance indicators.

Usage:
  Rscript 03_indicators.R [options]

Options:
  --harmonized_data_path PATH  Path to harmonized data file (default: data/interim/harmonized/persons_harmonized.parquet)
  --raw_data_dir DIR           Path to raw data directory (default: data/raw)
  --output_dir DIR             Output directory for indicator files (default: output/indicators)
  --years YEAR1,YEAR2,...      Years to process for household data (default: all)
  --countries CODE1,CODE2,...  Countries to process for household data (default: all)
  --include_se                 Include standard errors in household output
  --disaggregate_by VARS       Comma-separated list of disaggregation variables for household data
  --no-household               Skip household core indicator estimation
  --no-learning                Skip learning layer integration
  --no-admin-reference         Skip admin/reference layer integration
  --no-finance                 Skip finance layer integration
  --help                       Show this help message

Example:
  Rscript 03_indicators.R --countries "ARG,HND" --years 2022,2023
'
  return(help_text)
}

#' Load harmonized data
load_harmonized_data <- function(data_path) {
  message("Loading harmonized data from: ", data_path)

  if (is.null(data_path) || !file.exists(data_path)) {
    stop("Harmonized data file not found: ", data_path)
  }

  if (grepl("\\.parquet$", data_path, ignore.case = TRUE)) {
    data <- arrow::read_parquet(data_path)
  } else if (grepl("\\.csv(\\.gz)?$", data_path, ignore.case = TRUE)) {
    data <- data.table::fread(data_path)
  } else {
    stop("Unsupported file format. Use .parquet, .csv, or .csv.gz")
  }

  if (!data.table::is.data.table(data)) {
    data <- data.table::as.data.table(data)
  }

  message("Loaded ", nrow(data), " rows with ", ncol(data), " columns")

  required_cols <- c("country_code", "survey_year", "weight_h", "age_h")
  missing_cols <- setdiff(required_cols, names(data))
  if (length(missing_cols) > 0) {
    warning("Missing recommended columns in harmonized data: ", paste(missing_cols, collapse = ", "))
  }

  return(data)
}

#' Run household core indicator estimation
run_household_core_indicators <- function(harmonized_data, config) {
  message("\n", strrep("=", 60))
  message("Running Household Core Indicator Estimation")
  message(strrep("=", 60))

  disaggregation_vars <- trimws(strsplit(config$disaggregate_by, ",")[[1]])

  grouping_sets <- list(
    "national" = c("country_code", "source_program", "survey_year", "wave_id")
  )
  for (var in disaggregation_vars) {
    if (var %in% names(harmonized_data)) {
      grouping_sets[[var]] <- c("country_code", "source_program", "survey_year", "wave_id", var)
    }
  }

  all_indicators <- list()

  for (group_name in names(grouping_sets)) {
    group_vars <- grouping_sets[[group_name]]
    message(sprintf("\nCalculating indicators for disaggregation: %s", group_name))

    # Define a helper to run and bind estimation functions
    run_and_bind <- function(func, name, ...) {
      message(sprintf("  - Estimating %s...", name))
      tryCatch({
        result <- func(harmonized_data = harmonized_data, group_vars = group_vars, ...)
        if (nrow(result) > 0) {
          result[, disaggregation_level := group_name]
          all_indicators[[length(all_indicators) + 1]] <<- result
        }
      }, error = function(e) {
        warning(sprintf("Failed to estimate %s for group '%s': %s", name, group_name, e$message))
      })
    }

    # Run estimations (data already filtered to single country, so don't re-filter)
    run_and_bind(run_attendance_estimation, "attendance rates", include_se = config$include_se)
    run_and_bind(run_out_of_school_estimation, "out-of-school rates", include_se = config$include_se, use_attendance_complement = TRUE)
    run_and_bind(run_completion_estimation, "completion rates", include_se = config$include_se)
    run_and_bind(run_literacy_estimation, "literacy rates", include_se = config$include_se)
    run_and_bind(run_repetition_estimation, "repetition rates", include_se = config$include_se)
  }

  # Post-secondary review (computed separately, not included in household_core benchmarking)
  # Kept for contextual reference but excluded from the unified household_core output
  # message("\n- Running post-secondary review...")
  # tryCatch({
  #   postsecondary_review <- run_postsecondary_review(harmonized_data = harmonized_data, years = config$years, countries = config$countries)
  #   if (nrow(postsecondary_review) > 0) {
  #       postsecondary_review[, disaggregation_level := "national"]
  #       all_indicators[[length(all_indicators) + 1]] <- postsecondary_review
  #   }
  # }, error = function(e) {
  #   warning("Failed to run post-secondary review: ", e$message)
  # })

  if (length(all_indicators) > 0) {
    household_core_indicators <- data.table::rbindlist(all_indicators, fill = TRUE)
    message("\n✓ Household core estimation complete. Total records: ", nrow(household_core_indicators))
    return(household_core_indicators)
  } else {
    warning("No household core indicators were generated.")
    return(data.table())
  }
}

#' Main function
main <- function() {
  config <- parse_args()

  create_output_structure(config$output_dir, create_subdirs = TRUE)

  all_results <- list()

  # --- Run Integration Layers (run once) ---
  if (config$run_learning) {
    all_results[["learning_layer"]] <- run_learning_layer_integration(config$raw_data_dir)
  }
  if (config$run_admin_reference) {
    all_results[["admin_reference"]] <- run_admin_reference_layer_integration(config$raw_data_dir)
  }
  if (config$run_finance) {
    all_results[["finance_layer"]] <- run_finance_layer_integration(config$raw_data_dir)
  }

  # --- Run Household Layer (can be run in parallel per country) ---
  if (config$run_household) {
    harmonized_data <- load_harmonized_data(config$harmonized_data_path)

    # Optional filtering for development
    if (!is.null(config$countries)) {
        harmonized_data <- harmonized_data[country_code %in% config$countries]
    }
    if (!is.null(config$years)) {
        harmonized_data <- harmonized_data[survey_year %in% config$years]
    }

    # Set up parallel processing
    if(future::supportsMulticore()) {
        plan(multicore)
    } else {
        plan(multisession)
    }

    message("\nProcessing household data for countries: ", paste(unique(harmonized_data$country_code), collapse = ", "))

    # Process sequentially for stability (parallelization can hide errors)
    household_results_list <- list()
    for (country in unique(harmonized_data$country_code)) {
      message(sprintf("  Processing household core for %s...", country))
      country_data <- harmonized_data[country_code == country]
      country_result <- tryCatch({
        run_household_core_indicators(country_data, config)
      }, error = function(e) {
        warning(sprintf("Error processing %s: %s", country, e$message))
        return(data.table())
      })
      household_results_list[[country]] <- country_result
    }

    household_core_combined <- rbindlist(household_results_list, fill = TRUE)
    all_results[["household_core"]] <- household_core_combined
    message(sprintf("✓ Household core: %d total estimates across %d countries",
                    nrow(household_core_combined), length(household_results_list)))
  }

  print("DEBUG: names of all_results before rbindlist:")
  print(names(all_results))

  # --- Combine and Write All Results ---
  final_indicators <- rbindlist(all_results, fill = TRUE, use.names = TRUE)

  message("\n", strrep("=", 60))
  message("INDICATOR PIPELINE COMPLETE")
  message(strrep("=", 60))

  if (nrow(final_indicators) > 0) {
    # Ensure indicator_family column exists for all layers
    if (!("indicator_family" %in% names(final_indicators))) {
      final_indicators[, indicator_family := "unknown"]
    }

    # Write unified combined output (all indicator families in one file)
    combined_path <- file.path(config$output_dir, "all_indicators_combined.csv")
    fwrite(final_indicators, combined_path)
    message("✓ All indicators combined and written to: ", combined_path)
    message("  Indicator families present: ", paste(unique(final_indicators$indicator_family), collapse = ", "))

    # Write platform-specific formats (using combined data)
    message("\nWriting platform-specific formats...")
    write_platform_outputs(
      indicator_data = final_indicators,
      output_dir = file.path(config$output_dir, "platform_formats")
    )

    # Write metadata
    message("\nWriting metadata...")
    write_metadata(
      indicator_data = final_indicators,
      output_dir = file.path(config$output_dir, "metadata"),
      run_id = format(Sys.time(), "%Y%m%d_%H%M%S")
    )
  }

  # Final summary
  total_estimates <- 0
  for (layer in names(all_results)) {
    n <- if (is.data.table(all_results[[layer]])) nrow(all_results[[layer]]) else 0
    if (n > 0) {
      message(sprintf("  %-20s: %d estimates", layer, n))
      total_estimates <- total_estimates + n
    }
  }

  message("\nTotal estimates generated: ", total_estimates)
  message("Output directory: ", normalizePath(config$output_dir))

  # Write run log
  log_path <- file.path(config$output_dir, "logs", "run_log.txt")
  log_content <- paste(
    "Run completed: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
    "\nTotal estimates: ", total_estimates,
    "\nHarmonized data: ", config$harmonized_data_path,
    "\nRaw data dir: ", config$raw_data_dir,
    "\nOutput directory: ", config$output_dir,
    "\nLayers processed: ", paste(names(all_results), collapse = ", "),
    sep = ""
  )
  writeLines(log_content, log_path)
  message("Run log written to: ", log_path)

  message("\n", strrep("=", 60))
  message("✓ PIPELINE EXECUTION SUCCESSFUL")
  message(strrep("=", 60))
}

# Run main function if script is executed directly
if (sys.nframe() == 0) {
  main()
}