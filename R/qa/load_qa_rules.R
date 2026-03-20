load_qa_rules <- function(path = cfg_path("qa_rules.csv")) {
  readr::read_csv(path, show_col_types = FALSE)
}
