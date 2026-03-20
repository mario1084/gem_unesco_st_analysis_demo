repo_root <- function() {
  normalizePath(file.path(getwd()), winslash = "/", mustWork = TRUE)
}

cfg_path <- function(name) {
  file.path(repo_root(), "config", name)
}

doc_path <- function(name) {
  file.path(repo_root(), "docs", name)
}

data_path <- function(...) {
  file.path(repo_root(), "data", ...)
}

r_path <- function(...) {
  file.path(repo_root(), "R", ...)
}

ensure_dir <- function(path) {
  dir.create(path, recursive = TRUE, showWarnings = FALSE)
  normalizePath(path, winslash = "/", mustWork = TRUE)
}

staging_root <- function() {
  normalizePath(
    file.path(repo_root(), "data", "raw"),
    winslash = "/",
    mustWork = TRUE
  )
}
