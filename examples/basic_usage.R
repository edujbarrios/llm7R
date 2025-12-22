# Example: Basic Usage of LLM7.IO R Wrapper
# ===========================================
# This script demonstrates basic chat and text completions

# Load the LLM7 wrapper (works when sourced from project root)
if (file.exists("llm7.R")) {
  source("llm7.R")
} else if (file.exists("../llm7.R")) {
  source("../llm7.R")
} else {
  stop("Cannot find llm7.R. Please run from project root directory.")
}

# Required packages are loaded automatically
# If you need to install them:
# install.packages(c("httr", "jsonlite", "base64enc"))

# ===========================
# Example 1: Simple Completion
# ===========================
cat("Example 1: Simple Completion\n")
cat("============================\n\n")

# Create a client (uses default config)
client <- create_llm7_client()

# Send a simple completion request
tryCatch({
  response <- client$simple_completion(
    prompt = "What is the capital of France?"
  )
  cat("Response:", response, "\n\n")
}, error = function(e) {
  cat("Error:", conditionMessage(e), "\n\n")
})

# ===========================
# Example 2: Simple Completion with Custom Parameters
# ===========================
cat("Example 2: Custom Parameters\n")
cat("=============================\n\n")

tryCatch({
  response <- client$simple_completion(
    prompt = "Explain quantum computing in one sentence.",
    model = "gpt-4",
    temperature = 0.3,  # Lower temperature for more focused responses
    max_tokens = 100
  )
  cat("Response:", response, "\n\n")
}, error = function(e) {
  cat("Error:", conditionMessage(e), "\n\n")
})
