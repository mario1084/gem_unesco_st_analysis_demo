load_crosswalk <- function(path = cfg_path("crosswalk.csv")) {
  data.table::fread(path, encoding = "UTF-8")
}
