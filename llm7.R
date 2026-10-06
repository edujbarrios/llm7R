# LLM7.IO R Wrapper - Main Loader
# ================================
# Usage:
#   source("llm7.R")
#   Sys.setenv(LLM7_API_KEY = "your-token")
#   client <- create_llm7_client()

resolve_script_dir <- function() {
  frames <- sys.frames()
  for (i in rev(seq_along(frames))) {
    ofile <- frames[[i]]$ofile
    if (!is.null(ofile) && nzchar(ofile)) {
      return(dirname(normalizePath(ofile, mustWork = FALSE)))
    }
  }
  getwd()
}

script_dir <- resolve_script_dir()
cat("Loading LLM7.IO R Wrapper...\n")

config_file <- file.path(script_dir, "config", "config.R")
if (!file.exists(config_file)) stop("Configuration file not found: ", config_file)
source(config_file)
cat("✓ Configuration loaded\n")

required_packages <- c("httr", "jsonlite", "base64enc", "curl")
missing_packages <- required_packages[!vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing_packages) > 0) {
  stop(
    "Missing required packages: ", paste(missing_packages, collapse = ", "),
    ". Install them with install.packages(c('",
    paste(missing_packages, collapse = "', '"), "'))."
  )
}
cat("✓ Required packages available\n")

for (relative_path in c("src/client.R", "src/data_analysis.R", "src/vision.R", "src/media.R")) {
  file <- file.path(script_dir, relative_path)
  if (!file.exists(file)) stop("Required source file not found: ", file)
  source(file)
}
cat("✓ Client modules loaded\n")

cat("\n✓ LLM7.IO wrapper ready\n")
cat("Set LLM7_API_KEY, then run:\n")
cat("  client <- create_llm7_client()\n")
cat("  client$simple_completion('Hello!')\n")
cat("\nUse client$list_models() to inspect the live model catalog.\n\n")
