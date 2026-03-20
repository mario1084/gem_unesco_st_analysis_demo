# scripts/combine_harmonized_data.R
#
# This script combines all individual harmonized CSV.GZ files into a single
# Parquet file for easier processing by the indicator estimation script.
#
# Usage: Rscript scripts/combine_harmonized_data.R

suppressPackageStartupMessages({
  library(data.table)
  library(arrow)
  library(readr)
})

# Define paths
repo_root <- getwd()
harmonized_dir <- file.path(repo_root, "data", "interim", "harmonized")
output_file <- file.path(harmonized_dir, "persons_harmonized.parquet")

message("Starting data combination...")
message("Harmonized data directory: ", harmonized_dir)

# Find all harmonized .csv.gz files
files_to_combine <- list.files(
  path = harmonized_dir,
  pattern = "\\.csv\\.gz$",
  recursive = TRUE,
  full.names = TRUE
)

if (length(files_to_combine) == 0) {
  stop("No harmonized .csv.gz files found to combine in ", harmonized_dir)
}

message("Found ", length(files_to_combine), " files to combine.")

# Read and combine all files
all_data_list <- lapply(files_to_combine, function(f) {
  message("  Reading: ", basename(f))
  tryCatch({
    fread(f)
  }, error = function(e) {
    message("    Error reading file: ", f, " - ", e$message)
    return(NULL)
  })
})

# Remove any nulls from failed reads
all_data_list <- all_data_list[!sapply(all_data_list, is.null)]

if (length(all_data_list) == 0) {
  stop("Failed to read any harmonized data files. Aborting.")
}

message("Combining ", length(all_data_list), " data tables...")
combined_data <- rbindlist(all_data_list, use.names = TRUE, fill = TRUE)

message("Combined data has ", nrow(combined_data), " rows and ", ncol(combined_data), " columns.")

# Write to Parquet
message("Writing combined data to Parquet file: ", output_file)
tryCatch({
  write_parquet(combined_data, output_file)
}, error = function(e) {
  stop("Failed to write Parquet file: ", e$message)
})

message("✓ Successfully created combined Parquet file.")

# Final summary
summary_info <- combined_data[, .(
    .N,
    countries = paste(sort(unique(country_code)), collapse = ", "),
    years = paste(sort(unique(as.character(combined_data$survey_year))), collapse = ", ")
  ), by = .(source_program)]

message("\nSummary of combined data:")
print(summary_info)

message("\nPipeline ready for indicator estimation stage (03_indicators.R).")
