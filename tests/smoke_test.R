# Offline smoke checks. No network calls are made.
source("llm7.R")

stopifnot(get_config("base_url") == "https://api.llm7.io/v1")
stopifnot(get_config("models.text") == "default")
stopifnot(get_config("models.fast") == "fast")

original_temperature <- get_config("generation.temperature")
set_config("generation.temperature", 0.25)
stopifnot(identical(get_config("generation.temperature"), 0.25))
set_config("generation.temperature", original_temperature)

client <- create_llm7_client(api_key = "test-token")
stopifnot(client$base_url == "https://api.llm7.io/v1")
stopifnot(client$api_key == "test-token")
stopifnot(is.function(client$chat_completion))
stopifnot(is.function(client$stream_chat_completion))
stopifnot(is.function(client$list_models))
stopifnot(is.function(client$find_models))
stopifnot(is.function(client$analyze_dataframe))
stopifnot(is.function(client$analyze_image))
stopifnot(is.function(client$generate_image))
stopifnot(is.function(client$edit_image))
stopifnot(is.function(client$create_video))
stopifnot(is.function(client$get_video))
stopifnot(is.function(client$wait_for_video))
stopifnot(is.function(client$download_video))

cat("Offline smoke checks passed.\n")
