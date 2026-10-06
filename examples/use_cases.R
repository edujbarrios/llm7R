# Data analysis and vision examples for the current LLM7.io API.

if (file.exists("llm7.R")) {
  source("llm7.R")
} else if (file.exists("../llm7.R")) {
  source("../llm7.R")
} else {
  stop("Cannot find llm7.R.")
}

# Sys.setenv(LLM7_API_KEY = "your-token")
client <- create_llm7_client()

if (!nzchar(Sys.getenv("LLM7_API_KEY")) && !nzchar(Sys.getenv("LLM7_API_TOKEN"))) {
  stop("Set LLM7_API_KEY before running this example.")
}

# Data-frame analysis
data(iris)
answer <- client$analyze_dataframe(
  iris,
  "What are the most important differences between the three species?",
  model = "default"
)
cat(answer, "\n\n")

# Vision / image recognition
# The current LLM7 documentation requires a publicly reachable HTTPS image URL.
vision_models <- client$find_models(model_type = "chat", input_modality = "image")
if (length(vision_models) > 0) {
  image_url <- "https://images.weserv.nl/?url=wsrv.nl/lichtenstein.jpg&w=600&output=webp"
  description <- client$analyze_image(
    image_url,
    "Describe this image in one concise paragraph.",
    model = vision_models[[1]]$id
  )
  cat(description, "\n")
} else {
  cat("No vision-capable chat model is currently available.\n")
}

# For local plot files, upload the image to a reachable HTTPS URL first.
# A legacy, undocumented data-URI fallback remains available as:
# client$analyze_plot("plot.png", "Describe this plot", allow_data_uri = TRUE)
