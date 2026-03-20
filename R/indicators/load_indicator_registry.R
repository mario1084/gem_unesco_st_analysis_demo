load_indicator_registry <- function(path = cfg_path("indicator_registry.csv")) {
  readr::read_csv(path, show_col_types = FALSE)
}
