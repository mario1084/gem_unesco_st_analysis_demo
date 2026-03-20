load_source_registry <- function(path = cfg_path("source_registry.csv")) {
  data.table::fread(path, encoding = "UTF-8")
}
