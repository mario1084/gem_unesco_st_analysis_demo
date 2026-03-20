#' Learning Layer Integration
#'
#' Integrates source-native learning indicators from ERCE, PISA, PISA-D,
#' and the UIS Learning API into a standardized format.
#'
#' @param raw_data_dir Path to the directory containing the raw, source-native data.
#'
#' @return A data.table with integrated learning indicators.
#' @export
run_learning_layer_integration <- function(raw_data_dir) {
  message("
", strrep("=", 60))
  message("Running Learning Layer Integration")
  message(strrep("=", 60))
  
  all_learning_indicators <- list()
  
  # --- 1. UIS Learning API Integration ---
  uis_learning_path <- file.path(raw_data_dir, "UIS_LEARNING_API", "indicator_records_learning_sample.csv")
  if (file.exists(uis_learning_path)) {
    message("  - Integrating UIS Learning API data...")
    tryCatch({
      uis_data <- data.table::fread(uis_learning_path)
      
      # Basic transformation to standard format
      setnames(uis_data, 
               old = c("geoUnit", "indicatorId", "year", "value"), 
               new = c("country_code", "indicator_id", "survey_year", "estimate"), 
               skip_absent = TRUE)
      
      uis_data[, indicator_family := "learning_layer"]
      uis_data[, source_program := "UIS_LEARNING_API"]
      uis_data[, disaggregation_level := "national"]
      uis_data[, level := "national"]
      
      # Filter for non-NA estimates
      uis_data <- uis_data[!is.na(estimate)]
      
      # Select and reorder columns
      std_cols <- c("country_code", "source_program", "survey_year", "indicator_family", "indicator_id", "estimate", "disaggregation_level", "level")
      uis_data <- uis_data[, ..std_cols]
      
      all_learning_indicators[["UIS_LEARNING"]] <- uis_data
      message("    ...found ", nrow(uis_data), " indicator records.")
    }, error = function(e) {
      warning("Failed to process UIS Learning API data: ", e$message)
    })
  } else {
    warning("UIS Learning API data not found at: ", uis_learning_path)
  }
  
  # --- Placeholders for other learning data ---
  # A full implementation would read and transform ERCE, PISA, PISA-D data here
  message("  - ERCE, PISA, PISA-D integration is a placeholder.")
  
  if (length(all_learning_indicators) > 0) {
    combined_data <- data.table::rbindlist(all_learning_indicators, fill = TRUE)
    message("✓ Learning layer integration complete. Total records: ", nrow(combined_data))
    return(combined_data)
  } else {
    warning("No learning layer data could be integrated.")
    return(data.table())
  }
}
