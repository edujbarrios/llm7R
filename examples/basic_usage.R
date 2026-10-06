# Basic usage of the current LLM7.io API from R.

if (file.exists("llm7.R")) {
  source("llm7.R")
} else if (file.exists("../llm7.R")) {
  source("../llm7.R")
} else {
  stop("Cannot find llm7.R. Run this example from the project root or examples/ directory.")
}

# Create a token at https://dash.llm7.io/ and expose it through the environment.
# Sys.setenv(LLM7_API_KEY = "your-token")

client <- create_llm7_client()

cat("Live model catalog (first five IDs):\n")
catalog <- client$list_models()
if (!is.null(catalog$data)) {
  print(head(vapply(catalog$data, function(model) model$id, character(1)), 5))
}

if (!nzchar(Sys.getenv("LLM7_API_KEY")) && !nzchar(Sys.getenv("LLM7_API_TOKEN"))) {
  stop("Set LLM7_API_KEY before running authenticated completion examples.")
}

cat("\nSimple completion:\n")
print(client$simple_completion(
  "Explain gradient descent in two sentences.",
  model = "default"
))

cat("\nStreaming completion:\n")
client$simple_completion(
  "Give me three concise R performance tips.",
  model = "fast",
  stream = TRUE,
  on_delta = function(text, chunk) cat(text)
)
cat("\n")

cat("\nJSON mode (requires a model that advertises json_mode = true):\n")
json_models <- client$find_models(model_type = "chat", json_mode = TRUE)
if (length(json_models) > 0) {
  print(client$json_completion(
    "Return an object with fields language and creator for the R language.",
    model = json_models[[1]]$id
  ))
} else {
  cat("No JSON-mode model is currently available.\n")
}
