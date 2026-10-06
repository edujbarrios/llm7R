# LLM7.IO Configuration File
# ===========================
# Configuration defaults aligned with the current LLM7.io API.

LLM7_CONFIG <- list(
  # OpenAI-compatible API base URL.
  base_url = "https://api.llm7.io/v1",

  # Prefer LLM7_API_KEY. LLM7_API_TOKEN is kept as a compatibility alias.
  api_key = Sys.getenv(
    "LLM7_API_KEY",
    unset = Sys.getenv("LLM7_API_TOKEN", unset = "")
  ),

  # LLM7 recommends selectors for chat workloads because concrete model IDs
  # can change with upstream availability.
  models = list(
    text = "default",
    vision = "default",
    fast = "fast",
    pro = "pro"
  ),

  generation = list(
    temperature = 0.7,
    max_tokens = NULL,
    stream = FALSE
  ),

  data_analysis = list(
    include_summary = TRUE,
    max_rows = 10,
    max_columns = 20
  ),

  vision = list(
    detail = NULL,
    supported_formats = c("png", "jpg", "jpeg", "gif", "webp")
  ),

  request = list(
    timeout = 60,
    retry_attempts = 3,
    retry_delay = 1
  ),

  debug = list(
    verbose = FALSE,
    log_requests = FALSE,
    log_file = NULL
  )
)

#' Get configuration value
#'
#' @param key Configuration key (for example, "base_url" or "models.text")
#' @param default Default value if the key is not found
#' @return Configuration value
get_config <- function(key, default = NULL) {
  keys <- strsplit(key, "\\.")[[1]]
  value <- LLM7_CONFIG

  for (k in keys) {
    if (is.list(value) && k %in% names(value)) {
      value <- value[[k]]
    } else {
      return(default)
    }
  }

  value
}

#' Set configuration value
#'
#' @param key Configuration key
#' @param value New value
#' @return The assigned value, invisibly
set_config <- function(key, value) {
  keys <- strsplit(key, "\\.")[[1]]

  set_nested <- function(x, remaining, new_value) {
    current <- remaining[[1]]

    if (length(remaining) == 1) {
      x[[current]] <- new_value
      return(x)
    }

    if (is.null(x[[current]]) || !is.list(x[[current]])) {
      x[[current]] <- list()
    }

    x[[current]] <- set_nested(x[[current]], remaining[-1], new_value)
    x
  }

  LLM7_CONFIG <<- set_nested(LLM7_CONFIG, keys, value)
  invisible(value)
}

#' Load configuration from file
#'
#' @param file Path to a configuration file defining LLM7_CONFIG
load_config <- function(file) {
  if (!file.exists(file)) {
    stop("Configuration file not found: ", file)
  }

  sys.source(file, envir = .GlobalEnv)
  invisible(LLM7_CONFIG)
}

#' Print current configuration
print_config <- function() {
  cat("LLM7.IO Configuration\n")
  cat("=====================\n\n")

  safe_config <- LLM7_CONFIG
  if (!is.null(safe_config$api_key) && nzchar(safe_config$api_key)) {
    safe_config$api_key <- "<configured>"
  }
  str(safe_config, max.level = 2)
}
