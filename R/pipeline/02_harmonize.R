suppressPackageStartupMessages({
  library(data.table)
})

source(file.path(getwd(), "R", "utils", "paths.R"))
source(file.path(getwd(), "R", "acquisition", "build_source_registry.R"))
source(file.path(getwd(), "R", "harmonization", "build_crosswalk.R"))
source(file.path(getwd(), "R", "harmonization", "apply_crosswalk.R"))

ensure_dir(data_path("interim"))
ensure_dir(data_path("interim", "harmonized"))
ensure_dir(data_path("interim", "qa"))

message("[02_harmonize] Rebuilding R-driven contracts before harmonization.")
registry <- build_source_registry(write = TRUE)
crosswalk <- build_crosswalk(write = TRUE)
base_exceptions <- fread(cfg_path("exception_log.csv"), encoding = "UTF-8")

hh_registry <- registry[layer == "household_core"][order(country_code, year, period, source_id)]
if (!nrow(hh_registry)) stop("[02_harmonize] No household_core sources available in source_registry.")

harmonization_summary <- vector("list", nrow(hh_registry))
runtime_logs <- list()

for (i in seq_len(nrow(hh_registry))) {
  rr <- hh_registry[i]
  sid <- rr$source_id[[1]]
  message(sprintf("[02_harmonize] Harmonizing %s ...", sid))
  res <- harmonize_source(sid, registry, crosswalk)

  out_dir <- ensure_dir(data_path("interim", "harmonized", rr$country_code[[1]], as.character(rr$year[[1]])))
  out_file <- file.path(out_dir, sprintf("%s.csv.gz", sid))
  fwrite(res$data, out_file)

  runtime_count <- if (nrow(res$runtime_issues)) nrow(res$runtime_issues) else 0L
  if (runtime_count > 0L) {
    runtime_logs[[length(runtime_logs) + 1L]] <- res$runtime_issues
  }

  harmonization_summary[[i]] <- data.table(
    source_id = sid,
    country_code = rr$country_code[[1]],
    source_program = rr$source_program[[1]],
    survey_year = rr$year[[1]],
    period = rr$period[[1]],
    input_rows = nrow(res$data),
    output_rows = nrow(res$data),
    output_file = out_file,
    runtime_issue_count = runtime_count
  )
}

summary_dt <- rbindlist(harmonization_summary, fill = TRUE)
runtime_dt <- if (length(runtime_logs)) unique(rbindlist(runtime_logs, fill = TRUE)) else data.table()

run_log <- unique(rbindlist(list(base_exceptions, runtime_dt), fill = TRUE))

fwrite(summary_dt, data_path("interim", "qa", "harmonization_summary.csv"))
fwrite(run_log, data_path("interim", "qa", "harmonization_run_exception_log.csv"))

message("[02_harmonize] Harmonization complete.")
print(summary_dt)
message(sprintf("[02_harmonize] Runtime issues appended: %d", if (nrow(runtime_dt)) nrow(runtime_dt) else 0L))
