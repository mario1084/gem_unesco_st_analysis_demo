#' Finance Layer Integration
#'
#' Integrates source-native finance indicators from the OECD DAC/CRS database.
#'
#' @param raw_data_dir Path to the directory containing the raw, source-native data.
#'
#' @return A data.table with integrated finance indicators.
#' @export
run_finance_layer_integration <- function(raw_data_dir) {
  message("
", strrep("=", 60))
  message("Running Finance Layer Integration")
  message(strrep("=", 60))
  
  all_finance_indicators <- list()
  
  # --- 1. OECD DAC/CRS Data Integration ---
  crs_path <- file.path(raw_data_dir, "OECD_DAC_CRS", "education_oda_disbursements_constant_prices.csv")
  if (file.exists(crs_path)) {
    message("  - Integrating OECD DAC/CRS data...")
    tryCatch({
      crs_data <- data.table::fread(crs_path)
      
      # Basic transformation
      # This data is already in long format.
      # We need to map: RECIPIENT -> country_code, TIME_PERIOD -> survey_year, OBS_VALUE -> estimate
      setnames(crs_data, 
               old = c("RECIPIENT", "TIME_PERIOD", "OBS_VALUE"), 
               new = c("country_code", "survey_year", "estimate"), 
               skip_absent = TRUE)
               
      long_data <- crs_data[, .(country_code, survey_year, estimate)]
      
      long_data[, survey_year := as.numeric(as.character(survey_year))]
      long_data[, estimate := as.numeric(as.character(estimate))]
      
      # Filter for valid rows
      long_data <- long_data[!is.na(estimate)]
      
      long_data[, indicator_family := "finance_layer"]
      long_data[, source_program := "OECD_DAC_CRS"]
      long_data[, indicator_id := "FIN_CRS"]
      long_data[, indicator_name := "Education ODA Disbursements (Constant USD)"]
      long_data[, disaggregation_level := "national"]
      long_data[, level := "national"]
      
      # Select and reorder columns
      std_cols <- c("country_code", "source_program", "survey_year", "indicator_family", "indicator_id", "indicator_name", "estimate", "disaggregation_level", "level")
      long_data <- long_data[, ..std_cols]
      
      all_finance_indicators[["OECD_DAC_CRS"]] <- long_data
      message("    ...found ", nrow(long_data), " indicator records.")
    }, error = function(e) {
      warning("Failed to process OECD DAC/CRS data: ", e$message)
    })
  } else {
    warning("OECD DAC/CRS data not found at: ", crs_path)
  }
  
  if (length(all_finance_indicators) > 0) {
    combined_data <- data.table::rbindlist(all_finance_indicators, fill = TRUE)
    message("✓ Finance layer integration complete. Total records: ", nrow(combined_data))
    return(combined_data)
  } else {
    warning("No finance layer data could be integrated.")
    return(data.table())
  }
}
