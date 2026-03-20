#' Admin/Reference Layer Integration
#'
#' Integrates source-native administrative and reference indicators from 
#' UIS Admin data and World Population Prospects (WPP) API data.
#'
#' @param raw_data_dir Path to the directory containing the raw, source-native data.
#'
#' @return A data.table with integrated admin/reference indicators.
#' @export
run_admin_reference_layer_integration <- function(raw_data_dir) {
  message("
", strrep("=", 60))
  message("Running Admin/Reference Layer Integration")
  message(strrep("=", 60))
  
  all_admin_ref_indicators <- list()
  
  # --- 1. UIS Admin Data Integration ---
  uis_admin_path_sdg <- file.path(raw_data_dir, "UIS_ADMIN", "sdg_data_sample_recent_2021_2024.csv")
  if (file.exists(uis_admin_path_sdg)) {
    message("  - Integrating UIS Admin (SDG) data...")
    tryCatch({
      uis_data <- data.table::fread(uis_admin_path_sdg)
      
      # Basic transformation
      setnames(uis_data, 
               old = c("COUNTRY_ID", "INDICATOR_ID", "YEAR", "VALUE"), 
               new = c("country_code", "indicator_id", "survey_year", "estimate"),
               skip_absent = TRUE)
      
      uis_data[, indicator_family := "admin_reference"]
      uis_data[, source_program := "UIS_ADMIN"]
      uis_data[, disaggregation_level := "national"]
      uis_data[, level := "national"]
      
      # Filter non-NA
      uis_data <- uis_data[!is.na(estimate)]
      
      std_cols <- c("country_code", "source_program", "survey_year", "indicator_family", "indicator_id", "estimate", "disaggregation_level", "level")
      uis_data <- uis_data[, ..std_cols]
      
      all_admin_ref_indicators[["UIS_ADMIN"]] <- uis_data
      message("    ...found ", nrow(uis_data), " indicator records.")
    }, error = function(e) {
      warning("Failed to process UIS Admin data: ", e$message)
    })
  } else {
    warning("UIS Admin (SDG) data not found at: ", uis_admin_path_sdg)
  }
  
  # --- 2. WPP API Data Integration (Placeholder) ---
  # A full implementation would parse the JSON files
  wpp_path <- file.path(raw_data_dir, "WPP_API")
  if (dir.exists(wpp_path)) {
     message("  - WPP API integration is a placeholder.")
     # Placeholder logic:
     # files <- list.files(wpp_path, "*.json", full.names = TRUE)
     # for (file in files) {
     #   data <- jsonlite::fromJSON(file)
     #   # ... transformation logic ...
     # }
  }
  
  if (length(all_admin_ref_indicators) > 0) {
    combined_data <- data.table::rbindlist(all_admin_ref_indicators, fill = TRUE)
    message("✓ Admin/Reference layer integration complete. Total records: ", nrow(combined_data))
    return(combined_data)
  } else {
    warning("No admin/reference layer data could be integrated.")
    return(data.table())
  }
}
