# LLM7.IO Configuration File
# ===========================
# This file contains all configuration settings for the LLM7.IO wrapper

# API Configuration
LLM7_CONFIG <- list(
  # Base URL for the API
  base_url = "https://api.llm7.io/v1",
  
  # Default API key (can be overridden when creating client)
  api_key = "unused",
  
  # Default models for different tasks
  models = list(
    text = "gpt-4",           # Default text model
    vision = "gpt-4o",        # Default vision model
    fast = "fast",            # Fast model
    pro = "pro"               # Pro model
  ),
  
  # Default generation parameters
  generation = list(
    temperature = 0.7,        # Default temperature (0-2)
    max_tokens = NULL,        # Default max tokens (NULL = no limit)
    stream = FALSE            # Default streaming setting
  ),
  
  # Data analysis settings
  data_analysis = list(
    include_summary = TRUE,   # Include statistical summary
    max_rows = 10,           # Max rows to include in context
    max_columns = 20         # Max columns to include
  ),
  
  # Vision/Image analysis settings
  vision = list(
    detail = "auto",          # Image detail level: "auto", "low", "high"
    supported_formats = c("png", "jpg", "jpeg", "gif", "webp")
  ),
  
  # Request settings
  request = list(
    timeout = 60,             # Request timeout in seconds
    retry_attempts = 3,       # Number of retry attempts on failure
    retry_delay = 1           # Delay between retries (seconds)
  ),
  
  # Logging and debugging
  debug = list(
    verbose = FALSE,          # Print detailed request/response info
    log_requests = FALSE,     # Log all API requests
    log_file = NULL          # Log file path (NULL = no file logging)
  )
)

#' Get configuration value
#' 
#' @param key Configuration key (e.g., "base_url", "models.text")
#' @param default Default value if key not found
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
  
  return(value)
}

#' Set configuration value
#' 
#' @param key Configuration key
#' @param value New value
set_config <- function(key, value) {
  keys <- strsplit(key, "\\.")[[1]]
  
  if (length(keys) == 1) {
    LLM7_CONFIG[[keys[1]]] <<- value
  } else {
    # Navigate to parent and set value
    parent <- LLM7_CONFIG
    for (i in 1:(length(keys) - 1)) {
      if (!is.list(parent[[keys[i]]])) {
        parent[[keys[i]]] <- list()
      }
      parent <- parent[[keys[i]]]
    }
    parent[[keys[length(keys)]]] <- value
    
    # Update in global config
    temp <- LLM7_CONFIG
    current <- temp
    for (i in 1:(length(keys) - 1)) {
      current <- current[[keys[i]]]
    }
    current[[keys[length(keys)]]] <- value
    LLM7_CONFIG <<- temp
  }
}

#' Load configuration from file
#' 
#' @param file Path to configuration file
load_config <- function(file) {
  if (file.exists(file)) {
    source(file)
    message("Configuration loaded from: ", file)
  } else {
    warning("Configuration file not found: ", file)
  }
}

#' Print current configuration
print_config <- function() {
  cat("LLM7.IO Configuration\n")
  cat("=====================\n\n")
  str(LLM7_CONFIG, max.level = 2)
}
