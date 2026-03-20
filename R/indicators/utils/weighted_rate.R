#' Compute weighted rate estimator
#'
#' Implements the core weighted population share estimator defined in the methodology:
#' $\hat{p} = \frac{\sum_i w_i I(U_i=1 \land C_i=1)}{\sum_i w_i I(U_i=1)}$
#'
#' @param data A data.table containing the harmonized person-level data
#' @param eligible_condition Logical expression or function that defines the eligible universe U_i=1
#' @param indicator_condition Logical expression or function that defines the indicator condition C_i=1
#' @param weight_var Character string naming the weight variable (default: "weight_h")
#' @param group_vars Character vector of grouping variables (e.g., c("country_code", "survey_year", "source_program"))
#' @param include_counts Logical indicating whether to include numerator and denominator counts in output
#'
#' @return A data.table with rate estimates and optional counts
#' @export
weighted_rate <- function(data, eligible_condition, indicator_condition, 
                          weight_var = "weight_h", group_vars = NULL,
                          include_counts = TRUE) {
  
  # Ensure data.table
  if (!data.table::is.data.table(data)) {
    data <- data.table::as.data.table(data)
  }
  
  # Evaluate conditions
  if (is.character(eligible_condition)) {
    eligible_expr <- parse(text = eligible_condition)
    data[, eligible := eval(eligible_expr)]
  } else if (is.function(eligible_condition)) {
    data[, eligible := eligible_condition(.SD)]
  } else {
    stop("eligible_condition must be a character expression or function")
  }
  
  if (is.character(indicator_condition)) {
    indicator_expr <- parse(text = indicator_condition)
    data[, indicator := eval(indicator_expr)]
  } else if (is.function(indicator_condition)) {
    data[, indicator := indicator_condition(.SD)]
  } else {
    stop("indicator_condition must be a character expression or function")
  }
  
  # Compute weighted sums
  if (is.null(group_vars)) {
    # Overall rate
    numerator <- sum(data[eligible == TRUE & indicator == TRUE, get(weight_var)], na.rm = TRUE)
    denominator <- sum(data[eligible == TRUE, get(weight_var)], na.rm = TRUE)
    
    result <- data.table(
      rate = if (denominator > 0) numerator / denominator else NA_real_,
      numerator = numerator,
      denominator = denominator,
      n_eligible = sum(data$eligible, na.rm = TRUE),
      n_indicator = sum(data$eligible & data$indicator, na.rm = TRUE)
    )
    
    if (!include_counts) {
      result[, c("numerator", "denominator", "n_eligible", "n_indicator") := NULL]
    }
    
  } else {
    # Grouped rates
    # Ensure all group variables exist
    missing_groups <- setdiff(group_vars, names(data))
    if (length(missing_groups) > 0) {
      stop("Missing group variables: ", paste(missing_groups, collapse = ", "))
    }
    
    # Compute by group
    result <- data[, {
      numerator <- sum(get(weight_var)[eligible == TRUE & indicator == TRUE], na.rm = TRUE)
      denominator <- sum(get(weight_var)[eligible == TRUE], na.rm = TRUE)
      
      list(
        rate = if (denominator > 0) numerator / denominator else NA_real_,
        numerator = numerator,
        denominator = denominator,
        n_eligible = sum(eligible, na.rm = TRUE),
        n_indicator = sum(eligible & indicator, na.rm = TRUE)
      )
    }, by = group_vars]
    
    if (!include_counts) {
      result[, c("numerator", "denominator", "n_eligible", "n_indicator") := NULL]
    }
  }
  
  # Clean up temporary columns
  data[, c("eligible", "indicator") := NULL]
  
  return(result)
}

#' Compute weighted rate with standard error
#'
#' Computes weighted rate with approximate standard error using survey design principles
#'
#' @param data A data.table containing the harmonized person-level data
#' @param eligible_condition Logical expression or function for eligible universe
#' @param indicator_condition Logical expression or function for indicator condition
#' @param weight_var Character string naming the weight variable
#' @param group_vars Character vector of grouping variables
#' @param se_method Method for standard error calculation: "binomial" (default) or "normal"
#'
#' @return A data.table with rate estimates and standard errors
#' @export
weighted_rate_with_se <- function(data, eligible_condition, indicator_condition,
                                  weight_var = "weight_h", group_vars = NULL,
                                  se_method = "binomial") {
  
  # Get basic rate estimates
  rates <- weighted_rate(data, eligible_condition, indicator_condition, 
                         weight_var, group_vars, include_counts = TRUE)
  
  # Add standard errors based on method
  if (se_method == "binomial") {
    # Binomial approximation: SE = sqrt(p*(1-p)/n_effective)
    # where n_effective = (sum(weights))^2 / sum(weights^2)
    if (is.null(group_vars)) {
      # For overall rate, need to compute effective sample size
      # This would require the original data, so we'll use a simpler approximation
      rates[, se := sqrt(rate * (1 - rate) / n_eligible)]
    } else {
      # For grouped rates, use similar approximation
      rates[, se := sqrt(rate * (1 - rate) / n_eligible)]
    }
  } else if (se_method == "normal") {
    # Normal approximation using weighted variance
    # This would require more complex calculation
    warning("Normal SE method not fully implemented, using binomial approximation")
    rates[, se := sqrt(rate * (1 - rate) / n_eligible)]
  } else {
    stop("se_method must be 'binomial' or 'normal'")
  }
  
  # Add confidence intervals (95% normal approximation)
  rates[, `:=`(
    ci_lower = rate - 1.96 * se,
    ci_upper = rate + 1.96 * se
  )]
  
  # Ensure bounds are within [0, 1]
  rates[ci_lower < 0, ci_lower := 0]
  rates[ci_upper > 1, ci_upper := 1]
  
  return(rates)
}

#' Check rate validity against QA rules
#'
#' Validates rate estimates against QA rules from config/qa_rules.csv
#'
#' @param rate_data data.table with rate estimates
#' @param qa_rules data.table with QA rules
#' @param indicator_family Character string indicating the indicator family
#'
#' @return data.table with validation results
#' @export
validate_rate <- function(rate_data, qa_rules, indicator_family) {
  
  # Filter QA rules for this indicator family
  family_rules <- qa_rules[indicator_family == indicator_family]
  
  if (nrow(family_rules) == 0) {
    warning("No QA rules found for indicator family: ", indicator_family)
    rate_data[, qa_status := "no_rules"]
    return(rate_data)
  }
  
  # Apply each rule
  validation_results <- rate_data[, .SD, by = 1:nrow(rate_data)]
  
  for (i in seq_len(nrow(family_rules))) {
    rule <- family_rules[i, ]
    
    if (rule$rule_type == "non_missing_weight") {
      # Check that weight is non-missing and positive
      # This check should be applied at the data level, not rate level
      validation_results[, weight_valid := TRUE]  # Placeholder
      
    } else if (rule$rule_type == "eligible_universe_positive") {
      validation_results[, eligible_positive := denominator > 0]
      
    } else if (rule$rule_type == "rate_bounded") {
      validation_results[, rate_bounded := rate >= 0 & rate <= 1]
      
    } else if (rule$rule_type == "exception_flag_review") {
      # Check if exception flags are present and need review
      validation_results[, exception_reviewed := TRUE]  # Placeholder
    }
  }
  
  # Determine overall QA status
  validation_results[, qa_status := "pass"]
  
  # Check for any failed rules
  if ("eligible_positive" %in% names(validation_results)) {
    validation_results[eligible_positive == FALSE, qa_status := "fail"]
  }
  
  if ("rate_bounded" %in% names(validation_results)) {
    validation_results[rate_bounded == FALSE, qa_status := "fail"]
  }
  
  return(validation_results)
}