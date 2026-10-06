# llm7R

Use LLM7.io from R through its current OpenAI-compatible API, with helpers for chat completions, streaming, JSON mode, model discovery, data-frame analysis, vision, image generation/editing, and asynchronous video generation.

> This is an independent third-party client. LLM7.io owns and operates the API.

## What changed for the current LLM7 API

The wrapper now follows the current LLM7.io documentation:

- Base URL: `https://api.llm7.io/v1`
- Bearer-token authentication via `LLM7_API_KEY` (with `LLM7_API_TOKEN` as a compatibility alias)
- Chat selectors default to `default`, `fast`, and `pro` instead of stale hard-coded model IDs
- `/v1/models` is treated as the live source of model IDs and capabilities
- Streaming parses the API's server-sent event chunks instead of trying to parse them as one JSON response
- JSON mode and function/tool-calling payloads can be sent through `chat_completion()`
- Vision examples use publicly reachable HTTPS image URLs, matching the current image-recognition guide
- Image generation/editing follows the strict `/images/generations` and `/images/edits` contracts
- Video helpers cover asynchronous task creation, polling, and content download via `/videos`

LLM7 model availability is dynamic. Prefer selectors for normal chat workloads, or call `client$list_models()` / `client$find_models()` before pinning a concrete model ID.

## Installation

This repository is currently a source-based R client rather than a packaged CRAN-style library. Clone it and source the loader:

```bash
git clone https://github.com/edujbarrios/llm7R.git
cd llm7R
```

```r
install.packages(c("httr", "jsonlite", "base64enc", "curl"))
source("llm7.R")
```

## Authentication

Create or manage an API token at <https://dash.llm7.io/> and expose it through the environment:

```r
Sys.setenv(LLM7_API_KEY = "your-token")
client <- create_llm7_client()
```

You can also pass the token explicitly:

```r
client <- create_llm7_client(api_key = "your-token")
```

`client$list_models()` can be used to inspect the live catalog. Authenticated generation calls require a valid token.

## Chat completions

```r
response <- client$simple_completion(
  "Explain gradient descent in simple terms.",
  model = "default"
)
cat(response)
```

For full control, use `chat_completion()` with OpenAI-compatible messages:

```r
response <- client$chat_completion(
  model = "fast",
  messages = list(
    list(role = "system", content = "Answer concisely."),
    list(role = "user", content = "Give me three useful R debugging tips.")
  ),
  temperature = 0.4
)

cat(response$choices[[1]]$message$content)
cat("\nModel selected:", response$model)
```

## Streaming

```r
text <- client$simple_completion(
  "Write a four-line poem about statistics.",
  model = "fast",
  stream = TRUE,
  on_delta = function(text, chunk) cat(text)
)
cat("\n")
```

The streaming method follows LLM7's SSE format and reads `choices[0].delta.content` until the stream completes.

## Live model discovery

```r
catalog <- client$list_models()

vision_models <- client$find_models(
  model_type = "chat",
  input_modality = "image"
)

json_models <- client$find_models(
  model_type = "chat",
  json_mode = TRUE,
  stream = TRUE
)
```

The live catalog includes model tier, pricing, modalities, context window, and capability flags such as streaming, JSON mode, reasoning, and tool calling.

## JSON mode

Use a model whose live catalog record has `json_mode = true`:

```r
json_models <- client$find_models(model_type = "chat", json_mode = TRUE)

result <- client$json_completion(
  "Return fields city, country, and population_estimate for Madrid.",
  model = json_models[[1]]$id
)

str(result)
```

## Function / tool calling

`chat_completion()` accepts `tools` and `tool_choice`. When building JSON Schema arrays in R, use lists so one-item arrays remain arrays after JSON encoding.

```r
tools <- list(
  list(
    type = "function",
    function = list(
      name = "get_weather",
      description = "Get current weather for a city",
      parameters = list(
        type = "object",
        properties = list(
          city = list(type = "string")
        ),
        required = list("city")
      )
    )
  )
)

tool_models <- client$find_models(model_type = "chat", tools_calling = TRUE)

response <- client$chat_completion(
  model = tool_models[[1]]$id,
  messages = list(list(role = "user", content = "What is the weather in London?")),
  tools = tools,
  tool_choice = "auto"
)

response$choices[[1]]$message$tool_calls
```

Your application is responsible for executing requested tools and sending the tool result back with the matching `tool_call_id`.

## Data-frame analysis

```r
data(iris)

client$analyze_dataframe(
  iris,
  "What are the key differences between the species?"
)
```

The helper limits the rows and columns placed in the prompt according to `LLM7_CONFIG$data_analysis`.

## Vision / image recognition

The current LLM7 documentation specifies a publicly reachable HTTPS image (or signed URL) in the chat message. First find a vision-capable chat model, then call `analyze_image()`:

```r
vision_models <- client$find_models(
  model_type = "chat",
  input_modality = "image"
)

client$analyze_image(
  "https://images.weserv.nl/?url=wsrv.nl/lichtenstein.jpg&w=600&output=webp",
  "Describe this image for alt text.",
  model = vision_models[[1]]$id
)
```

For a local plot, upload it to a reachable HTTPS location and pass that URL. `analyze_plot(..., allow_data_uri = TRUE)` keeps the old base64 data-URI behavior as a best-effort compatibility option, but that path is not documented by the current LLM7 vision guide.

## Image generation and edits

Image endpoints require a concrete image model ID from the live catalog; chat selectors such as `default` are not used here. The API currently returns one base64-encoded image.

```r
image_models <- client$find_models(output_modality = "image")
image_model <- image_models[[1]]$id

result <- client$generate_image(
  prompt = "A clean product photo of a matte black desk lamp on a white desk",
  model = image_model,
  size = "1024x1024",
  output_file = "generated.png"
)

edited <- client$edit_image(
  image_paths = c("room.png"),
  prompt = "Replace the empty wall area with a framed abstract painting",
  model = image_model,
  size = "1024x1024",
  output_file = "edited.png"
)
```

The wrapper intentionally exposes only the fields LLM7 documents for these strict endpoints; unsupported image-generation fields are not forwarded.

## Video generation

Video generation is asynchronous and requires a concrete video model. Inspect each model's live `capabilities` before choosing duration, resolution, request type, or reference-image count.

```r
video_models <- client$find_models(model_type = "video", output_modality = "video")
video_model <- video_models[[1]]

task <- client$create_video(
  prompt = "Waves crashing on rocks, cinematic slow motion",
  model = video_model$id,
  duration = video_model$capabilities$supported_seconds[[1]],
  resolution = video_model$capabilities$supported_sizes[[1]],
  idempotency_key = "my-video-001",
  client_request_id = "my-video-001"
)

finished <- client$wait_for_video(task$id, poll_interval = 5, timeout = 600)
if (finished$status == "completed") {
  client$download_video(task$id, "output.mp4")
}
```

For image-to-video, pass one or more local files through `input_references`; the wrapper switches to multipart form data and uses the documented repeated `input_reference` field.

## Configuration

Defaults live in `config/config.R`. Common overrides:

```r
set_config("models.text", "fast")
set_config("generation.temperature", 0.2)
set_config("request.timeout", 120)
```

You can also pass provider-specific or newly introduced chat fields through `extra_body` without waiting for a wrapper update:

```r
client$chat_completion(
  messages = list(list(role = "user", content = "Hello")),
  extra_body = list(your_new_parameter = "value")
)
```

## LLM7 documentation

- <https://docs.llm7.io/quickstart>
- <https://docs.llm7.io/guides/models>
- <https://docs.llm7.io/guides/models-api>
- <https://docs.llm7.io/guides/streaming>
- <https://docs.llm7.io/guides/function-calling>
- <https://docs.llm7.io/guides/json-mode>
- <https://docs.llm7.io/guides/image-recognition>
- <https://docs.llm7.io/guides/image-generation>
- <https://docs.llm7.io/guides/video-generation>

## Author

Eduardo J. Barrios  
<https://edujbarrios.com>
