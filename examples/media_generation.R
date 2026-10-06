# Image and video generation examples for the current LLM7.io API.

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

# Generate an image using a concrete image-output model from the live catalog.
image_models <- client$find_models(output_modality = "image")
if (length(image_models) > 0) {
  client$generate_image(
    prompt = "A clean product photo of a matte black desk lamp on a white desk",
    model = image_models[[1]]$id,
    size = "1024x1024",
    output_file = "generated.png"
  )
} else {
  cat("No image-output model is currently available.\n")
}

# Create a text-to-video task using capabilities advertised by a live video model.
video_models <- client$find_models(model_type = "video", output_modality = "video")
if (length(video_models) > 0) {
  video_model <- video_models[[1]]
  seconds <- video_model$capabilities$supported_seconds[[1]]
  resolution <- video_model$capabilities$supported_sizes[[1]]

  request_id <- paste0("llm7r-example-", as.integer(Sys.time()))
  task <- client$create_video(
    prompt = "Waves crashing on rocks, cinematic slow motion",
    model = video_model$id,
    duration = seconds,
    resolution = resolution,
    client_request_id = request_id,
    idempotency_key = request_id
  )
  print(task)

  # Poll only when you intentionally want to block until completion:
  # completed <- client$wait_for_video(task$id, poll_interval = 5, timeout = 600)
  # if (completed$status == "completed") client$download_video(task$id, "output.mp4")
} else {
  cat("No video model is currently available.\n")
}
