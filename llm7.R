# LLM7.IO R Wrapper - Main Loader
# =================================
# This is the main entry point for loading the LLM7 wrapper
# 
# Usage:
#   source("llm7.R")
#   client <- create_llm7_client()

# Get the directory where this script is located
script_dir <- tryCatch({
  if (sys.nframe() > 0) {
    # If sourced
    getSrcDirectory(function() {})
  } else {
    # If run interactively
    getwd()
  }
}, error = function(e) {
  getwd()
})

# If script_dir is empty, use current working directory
if (is.null(script_dir) || script_dir == "") {
  script_dir <- getwd()
}

# Print loading message
cat("Loading LLM7.IO R Wrapper...\n")

# Load configuration first
config_file <- file.path(script_dir, "config", "config.R")
if (file.exists(config_file)) {
  source(config_file)
  cat("✓ Configuration loaded\n")
} else {
  warning("Configuration file not found: ", config_file)
}

# Load required packages
required_packages <- c("httr", "jsonlite", "base64enc")
missing_packages <- required_packages[!sapply(required_packages, requireNamespace, quietly = TRUE)]

if (length(missing_packages) > 0) {
  cat("\nMissing required packages:", paste(missing_packages, collapse = ", "), "\n")
  cat("Install them with: install.packages(c('", paste(missing_packages, collapse = "', '"), "'))\n\n", sep = "")
  stop("Required packages are missing")
}

library(httr)
library(jsonlite)
library(base64enc)
cat("✓ Required packages loaded\n")

# Load core client
client_file <- file.path(script_dir, "src", "client.R")
if (file.exists(client_file)) {
  source(client_file)
  cat("✓ Core client loaded\n")
} else {
  stop("Client file not found: ", client_file)
}

# Load data analysis module
data_analysis_file <- file.path(script_dir, "src", "data_analysis.R")
if (file.exists(data_analysis_file)) {
  source(data_analysis_file)
  cat("✓ Data analysis module loaded\n")
} else {
  warning("Data analysis module not found: ", data_analysis_file)
}

# Load vision module
vision_file <- file.path(script_dir, "src", "vision.R")
if (file.exists(vision_file)) {
  source(vision_file)
  cat("✓ Vision module loaded\n")
} else {
  warning("Vision module not found: ", vision_file)
}

cat("\n✓ LLM7.IO wrapper ready to use!\n")
cat("\nQuick start:\n")
cat("  client <- create_llm7_client()\n")
cat("  response <- client$simple_completion('Hello!')\n")
cat("\nFor examples, see the 'examples/' folder\n")
cat("For configuration, edit 'config/config.R'\n\n")
