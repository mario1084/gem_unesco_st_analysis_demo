suppressPackageStartupMessages({
  library(data.table)
})

source(file.path(getwd(), "R", "utils", "paths.R"))
source(file.path(getwd(), "R", "acquisition", "build_source_registry.R"))

message("[01_data_acquisition] Building source registry from canonical manifests and observed source files.")
registry <- build_source_registry(write = TRUE)

print(registry[, .(source_id, source_program, layer, year, period, source_exists, schema_exists, schema_var_count)])

missing_sources <- registry[source_exists == FALSE | schema_exists == FALSE]
if (nrow(missing_sources) > 0) {
  stop("[01_data_acquisition] Missing source or schema paths detected. Review generated config/source_registry.csv.")
}

message("[01_data_acquisition] Canonical source registry generated successfully.")
