# =============================================================================
# inspect_edu_vars.R
# Purpose : For each amber COMP_LVL lower_secondary case, show the weighted
#           frequency of the NSO education level variable in the reference-age
#           cohort (ages 17-19), apply the pipeline ISCED remapping inline,
#           and compare the resulting estimate against the WIDE reference.
#
# Key finding from crosswalk.csv:
#   - highest_level_completed_h stores RAW NSO codes, not ISCED 0-4
#   - ISCED remapping (split HND level 4 by grade) happens at indicator time
#   - HND 2021 uses CP407 (not ED05); HND 2022-2024 uses ED05
#   - PRY uses ED0504 split into level (quotient) + grade (remainder)
#   - ARG uses NIVEL_ED recoded into national attainment levels
#
# Run: Rscript benchmark/inspect_edu_vars.R   (from repo root)
# =============================================================================

REPO_ROOT <- "C:/Users/mglez/Documents/MGS/v0013/git_model/gem_unesco_st_analysis_demo"
HARM_ROOT <- file.path(REPO_ROOT, "data/interim/harmonized")

# WIDE reference values for amber cases (from ind_benchmark.md)
WIDE_REF <- list(
  ARG_2021 = 1.087,
  HND_2021 = 0.378, HND_2023 = 0.361, HND_2024 = 0.366,
  PRY_2022 = 0.702, PRY_2023 = 0.736, PRY_2024 = 0.755
)

# ── Helpers ───────────────────────────────────────────────────────────────────
load_harm <- function(country, year, wave = NULL) {
  survey  <- switch(country, ARG = "EPH", HND = "EPHPM", PRY = "EPHC")
  suffix  <- switch(country,
    ARG = paste0("_T", ifelse(is.null(wave), 1, wave)),
    PRY = "_sav",
    "")
  fname <- paste0(country, "_", survey, "_", year, suffix, ".csv.gz")
  path  <- file.path(HARM_ROOT, country, year, fname)
  if (!file.exists(path)) stop("Not found: ", path)
  read.csv(gzfile(path), stringsAsFactors = FALSE)
}

# For ARG: average T1-T4 waves for a given year
load_arg_annual <- function(year) {
  waves <- lapply(1:4, function(t) {
    tryCatch(load_harm("ARG", year, wave = t), error = function(e) NULL)
  })
  do.call(rbind, Filter(Negate(is.null), waves))
}

wtd_pct <- function(x, w) round(tapply(w, x, sum, na.rm=TRUE) /
                                   sum(w, na.rm=TRUE) * 100, 2)

hdr <- function(txt) cat("\n", strrep("=", 68), "\n", txt, "\n",
                         strrep("=", 68), "\n\n", sep="")
sep <- function() cat(strrep("-", 68), "\n")

# ── HND NSO level labels (ED05 / CP407 share the same scale) ─────────────────
hnd_labels <- c(
  "1"  = "Pre-escolar (below primary)",
  "2"  = "Alfabetizacion (literacy program)",
  "3"  = "Primaria (incomplete/other)",
  "4"  = "Educacion Basica gr 1-9  [ISCED 1+2 combined]",
  "5"  = "Bachillerato             [ISCED 3 upper secondary]",
  "6"  = "Carrera tecnica media    [ISCED 5 technical]",
  "7"  = "Carrera universitaria    [ISCED 6 university]",
  "8"  = "Postgrado / Maestria     [ISCED 7]",
  "9"  = "Doctorado                [ISCED 8]",
  "10" = "Educacion especial",
  "11" = "Secundaria (other code)",
  "99" = "NS/NR (unknown)"
)

# ── PRY harmonized level codes (already split from ED0504 quotient) ───────────
pry_labels <- c(
  "0" = "Pre-primaria / 1er ciclo EEB  [below ISCED 1]",
  "1" = "EEB 2do ciclo (gr 1-6)         [ISCED 1 primary]",
  "2" = "EEB 3er ciclo (gr 7-9)         [ISCED 2 lower secondary]",
  "3" = "Bachillerato                    [ISCED 3 upper secondary]",
  "4" = "Terciario / universitario       [ISCED 4+]"
)

# ── ARG NIVEL_ED national attainment codes ────────────────────────────────────
arg_labels <- c(
  "1"  = "Sin instruccion / pre-primaria  [below ISCED 1]",
  "2"  = "Primaria incompleta             [ISCED 1 incomplete]",
  "3"  = "Primaria completa               [ISCED 1 complete]",
  "4"  = "Secundaria incompleta           [ISCED 2/3 incomplete]",
  "5"  = "Secundaria completa             [ISCED 3 complete]",
  "6"  = "Superior no univ. incompleta    [ISCED 5 incomplete]",
  "7"  = "Superior no univ. completa      [ISCED 5 complete]",
  "8"  = "Universitaria incompleta        [ISCED 6 incomplete]",
  "9"  = "Universitaria completa          [ISCED 6 complete]",
  "10" = "Posgrado incompleto             [ISCED 7 incomplete]",
  "11" = "Posgrado completo               [ISCED 7 complete]"
)

# =============================================================================
# HONDURAS
# =============================================================================
hdr("HONDURAS — COMP_LVL lower_secondary amber cases")
cat("NSO variable: ED05 (2022-2024) / CP407 (2021)\n")
cat("Pipeline ISCED remapping applied here:\n")
cat("  level == 4 + grade >= 7  →  ISCED 2 (lower secondary) ✓\n")
cat("  level == 4 + grade <  7  →  ISCED 1 (primary only)    ✗\n")
cat("  level == 4 + grade NA    →  ISCED 1 (conservative)    ✗\n")
cat("  level >= 5               →  above lower secondary      ✓\n")
cat("  attending + level NA     →  attending inference NOT applied for lower sec\n\n")

for (yr in c(2021, 2023, 2024)) {
  sep()
  cat(sprintf("HND %d\n\n", yr))
  df  <- tryCatch(load_harm("HND", yr), error = function(e) { cat("ERROR:", e$message, "\n\n"); NULL })
  if (is.null(df)) next

  ref <- df[!is.na(df$age_h) & df$age_h >= 17 & df$age_h <= 19, ]
  w   <- ifelse(is.na(ref$weight_h), 1, ref$weight_h)
  N   <- sum(w)

  # Attending breakdown
  att_pct <- wtd_pct(ifelse(is.na(ref$attending_currently_h), "NA",
                             as.character(ref$attending_currently_h)), w)
  cat(sprintf("  Cohort ages 17-19: %d obs (%.0f weighted)\n", nrow(ref), N))
  cat(sprintf("  Attending (=1): %.1f%%   Not attending (=0/2): %.1f%%   NA: %.1f%%\n\n",
              ifelse(!is.na(att_pct["1"]), att_pct["1"], 0),
              ifelse(!is.na(att_pct["0"]), att_pct["0"],
                     ifelse(!is.na(att_pct["2"]), att_pct["2"], 0)),
              ifelse(!is.na(att_pct["NA"]), att_pct["NA"], 0)))

  # Raw level distribution
  lvl <- ref$highest_level_completed_h
  grd <- ref$highest_grade_completed_h
  cat("  Raw NSO level distribution (highest_level_completed_h):\n")
  tbl <- sort(wtd_pct(ifelse(is.na(lvl), "NA", as.character(lvl)), w))
  for (v in names(tbl)) {
    lbl    <- ifelse(v == "NA", "missing (attending or unknown)",
                     ifelse(!is.na(hnd_labels[v]), hnd_labels[v], paste("code", v)))
    note   <- if (!is.na(suppressWarnings(as.integer(v))) &&
                  !is.na(as.integer(v)) &&
                  as.integer(v) >= 5) " → ISCED 3+ (counts as completed)" else
              if (v == "4") " → needs grade split (see below)" else ""
    cat(sprintf("    %3s | %-52s | %5.1f%%%s\n", v, lbl, tbl[v], note))
  }

  # Grade split for level == 4
  cat("\n  Grade split within level=4 (Educacion Basica) respondents:\n")
  sub4 <- ref[!is.na(lvl) & lvl == 4, ]
  w4   <- ifelse(is.na(sub4$weight_h), 1, sub4$weight_h)
  if (nrow(sub4) > 0) {
    grd4 <- sub4$highest_grade_completed_h
    grd_tbl <- sort(wtd_pct(ifelse(is.na(grd4), "NA", as.character(grd4)), w4))
    for (v in names(grd_tbl)) {
      isced_note <- if (v == "NA") "grade missing → ISCED 1 (conservative)" else
                    if (as.integer(v) >= 7) paste0("grade ", v, " → ISCED 2 lower_sec ✓") else
                    paste0("grade ", v, " → ISCED 1 primary ✗")
      cat(sprintf("    grade %3s | %5.1f%% of level=4  |  %s\n", v, grd_tbl[v], isced_note))
    }
  }

  # Apply ISCED remapping and compute estimate
  isced2_w <- sum(w[!is.na(lvl) & ((lvl == 4 & !is.na(grd) & grd >= 7) |
                                     lvl >= 5)], na.rm=TRUE)
  our_est  <- isced2_w / N
  wide_val <- WIDE_REF[[paste0("HND_", yr)]]
  cat(sprintf("\n  Pipeline COMP_LVL (lower_sec, age 17-19): %.3f  (%.1f%%)\n",
              our_est, our_est*100))
  cat(sprintf("  WIDE reference                           : %.3f  (%.1f%%)\n",
              wide_val, wide_val*100))
  cat(sprintf("  Difference                               : %.3f  (%.1f pp)\n\n",
              abs(our_est - wide_val), abs(our_est - wide_val)*100))
}

# =============================================================================
# PARAGUAY
# =============================================================================
hdr("PARAGUAY — COMP_LVL lower_secondary amber cases")
cat("NSO variable: ED0504 (combined level-grade code)\n")
cat("Pipeline: level = ED0504 %/% 10, grade set to NA (no within-cycle grade recoverable)\n")
cat("  ED0504  1-39  → ISCED 0 pre-primary\n")
cat("  ED0504 40-89  → ISCED 1 primary\n")
cat("  ED0504 90-99  → ISCED 2 lower secondary ✓\n")
cat("  ED0504 100+   → ISCED 3+ upper secondary / tertiary ✓\n\n")

for (yr in c(2022, 2023, 2024)) {
  sep()
  cat(sprintf("PRY %d\n\n", yr))
  df  <- tryCatch(load_harm("PRY", yr), error = function(e) { cat("ERROR:", e$message, "\n\n"); NULL })
  if (is.null(df)) next

  ref <- df[!is.na(df$age_h) & df$age_h >= 17 & df$age_h <= 19, ]
  w   <- ifelse(is.na(ref$weight_h), 1, ref$weight_h)
  N   <- sum(w)
  lvl <- ref$highest_level_completed_h

  cat(sprintf("  Cohort ages 17-19: %d obs\n\n", nrow(ref)))
  cat("  Harmonized level distribution (after ED0504 split):\n")
  tbl <- sort(wtd_pct(ifelse(is.na(lvl), "NA", as.character(lvl)), w))
  for (v in names(tbl)) {
    lbl  <- ifelse(v == "NA", "missing",
                   ifelse(!is.na(pry_labels[v]), pry_labels[v], paste("code", v)))
    note <- if (!is.na(suppressWarnings(as.integer(v))) &&
                as.integer(v) >= 2) " → counts as completed ✓" else ""
    cat(sprintf("    %3s | %-50s | %5.1f%%%s\n", v, lbl, tbl[v], note))
  }

  isced2_w <- sum(w[!is.na(lvl) & lvl >= 2], na.rm=TRUE)
  our_est  <- isced2_w / N
  wide_val <- WIDE_REF[[paste0("PRY_", yr)]]
  cat(sprintf("\n  Pipeline COMP_LVL (lower_sec, age 17-19): %.3f  (%.1f%%)\n",
              our_est, our_est*100))
  cat(sprintf("  WIDE reference                           : %.3f  (%.1f%%)\n",
              wide_val, wide_val*100))
  cat(sprintf("  Difference                               : %.3f  (%.1f pp)\n\n",
              abs(our_est - wide_val), abs(our_est - wide_val)*100))
}

# =============================================================================
# ARGENTINA
# =============================================================================
hdr("ARGENTINA — COMP_LVL lower_secondary 2021 amber case")
cat("NSO variable: NIVEL_ED (annual average across 4 quarterly EPH waves)\n")
cat("  NIVEL_ED 4  = Secundaria incompleta  [entered but not completed secondary]\n")
cat("  NIVEL_ED 5  = Secundaria completa    [completed secondary = ISCED 3] ✓\n")
cat("  NIVEL_ED 6+ = Superior / university                                   ✓\n\n")
cat("  NOTE: 'Secundaria' in EPH spans ISCED 2+3 (lower+upper secondary combined)\n")
cat("  Completion of lower secondary cannot be separated from upper secondary.\n\n")

sep()
cat("ARG 2021 (mean of T1-T4 waves)\n\n")
df  <- tryCatch(load_arg_annual(2021),
                error = function(e) { cat("ERROR:", e$message, "\n\n"); NULL })
if (!is.null(df)) {
  ref <- df[!is.na(df$age_h) & df$age_h >= 17 & df$age_h <= 19, ]
  w   <- ifelse(is.na(ref$weight_h), 1, ref$weight_h)
  N   <- sum(w)
  lvl <- ref$highest_level_completed_h

  cat(sprintf("  Cohort ages 17-19: %d obs across all waves\n\n", nrow(ref)))
  cat("  NIVEL_ED distribution:\n")
  tbl <- sort(wtd_pct(ifelse(is.na(lvl), "NA", as.character(lvl)), w))
  for (v in names(tbl)) {
    lbl  <- ifelse(v == "NA", "missing",
                   ifelse(!is.na(arg_labels[v]), arg_labels[v], paste("code", v)))
    note <- if (!is.na(suppressWarnings(as.integer(v))) &&
                as.integer(v) >= 5) " → counts as completed ✓" else ""
    cat(sprintf("    %3s | %-52s | %5.1f%%%s\n", v, lbl, tbl[v], note))
  }

  # ARG completion: NIVEL_ED >= 5 (secundaria completa or above)
  isced2_w <- sum(w[!is.na(lvl) & lvl >= 5], na.rm=TRUE)
  our_est  <- isced2_w / N
  wide_val <- WIDE_REF[["ARG_2021"]]
  cat(sprintf("\n  Pipeline COMP_LVL (lower_sec, age 17-19): %.3f  (%.1f%%)\n",
              our_est, our_est*100))
  cat(sprintf("  WIDE reference (note: > 1.0 in 2021)    : %.3f  (%.1f%%)\n",
              wide_val, wide_val*100))
  cat(sprintf("  Difference                               : %.3f  (%.1f pp)\n\n",
              abs(our_est - wide_val), abs(our_est - wide_val)*100))
}

cat(strrep("=", 68), "\nDone.\n")
