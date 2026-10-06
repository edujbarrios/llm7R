# llm7R

**llm7R v2.0.0** is a lightweight R client for the current [LLM7.io](https://llm7.io/) API.

It supports chat completions, live model discovery, streaming, JSON mode, tool calling, data-frame analysis, vision, image generation/editing, and asynchronous video generation.

> **Third-party client:** this project is not maintained by LLM7.io. The API belongs to its respective owner.

## Version

Current stable release:

```text
v2.0.0
```

Release notes:

<https://github.com/edujbarrios/llm7R/releases/tag/v2.0.0>

The v2 release updates the client for the current LLM7.io API, including dynamic model discovery, proper SSE streaming, JSON/tool support, updated vision handling, and image/video generation.

---

## Installation

Install the required R packages:

```r
install.packages(c(
  "httr",
  "jsonlite",
  "base64enc",
  "curl"
))
```

Clone the repository:

```bash
git clone https://github.com/edujbarrios/llm7R.git
cd llm7R
```

Load the library:

```r
source("llm7.R")
```

To use the exact stable v2.0.0 release:

```bash
git clone https://github.com/edujbarrios/llm7R.git
cd llm7R
git checkout v2.0.0
```

This project is currently loaded with `source("llm7.R")`; it is not yet structured as a CRAN package.

---

## Authentication

Create or manage an API token at:

<https://dash.llm7.io/>

Set the token before creating the client:

```r
Sys.setenv(
  LLM7_API_KEY = "your-token"
)

source("llm7.R")

client <- create_llm7_client()
```

You can also provide it directly:

```r
client <- create_llm7_client(
  api_key = "your-token"
)
```

The compatibility environment variable `LLM7_API_TOKEN` is also supported.

---

# Quick start

## Ask a question

For normal chat requests, LLM7 provides three useful selectors:

- `default` — general-purpose model selection
- `fast` — optimized for speed
- `pro` — higher-capability model selection

A complete example:

```r
Sys.setenv(LLM7_API_KEY = "your-token")

source("llm7.R")
client <- create_llm7_client()

answer <- client$simple_completion(
  prompt = "Explain linear regression in simple terms and give a small R example.",
  model = "default"
)

cat(answer)
```

For a short, fast answer:

```r
answer <- client$simple_completion(
  prompt = "What is the difference between a list and a data.frame in R?",
  model = "fast",
  temperature = 0.2
)

cat(answer)
```

For a more demanding prompt:

```r
answer <- client$simple_completion(
  prompt = paste(
    "Compare random forests and gradient boosting.",
    "Discuss bias, variance, interpretability,",
    "training speed, and appropriate use cases."
  ),
  model = "pro"
)

cat(answer)
```

---

# Model selection

LLM7 model availability can change over time.

For ordinary text chat, using `default`, `fast`, or `pro` is usually the simplest option.

For features such as JSON mode, vision, tool calling, image generation, or video generation, query the live catalog first.

## List available models

```r
catalog <- client$list_models()

models <- catalog$data

for (model in head(models, 10)) {
  cat(
    model$id,
    "| type:", model$model_type,
    "| tier:", model$tier,
    "\n"
  )
}
```

## Select the first available chat model

```r
chat_models <- client$find_models(
  model_type = "chat"
)

if (length(chat_models) == 0) {
  stop("No chat model is currently available.")
}

selected_model <- chat_models[[1]]$id

cat(
  "Selected model:",
  selected_model,
  "\n"
)
```

Then use it in a question:

```r
answer <- client$simple_completion(
  prompt = "Give me five practical tips for writing faster R code.",
  model = selected_model
)

cat(answer)
```

## Select a model by capability

JSON:

```r
json_models <- client$find_models(
  model_type = "chat",
  json_mode = TRUE
)
```

Vision:

```r
vision_models <- client$find_models(
  model_type = "chat",
  input_modality = "image"
)
```

Tool calling:

```r
tool_models <- client$find_models(
  model_type = "chat",
  tools_calling = TRUE
)
```

Streaming:

```r
stream_models <- client$find_models(
  model_type = "chat",
  stream = TRUE
)
```

Image generation:

```r
image_models <- client$find_models(
  output_modality = "image"
)
```

Video generation:

```r
video_models <- client$find_models(
  model_type = "video",
  output_modality = "video"
)
```

---

# Full chat completion

Use `chat_completion()` when you need system instructions, conversation history, tools, or advanced request fields.

```r
response <- client$chat_completion(
  model = "default",
  messages = list(
    list(
      role = "system",
      content = paste(
        "You are an R programming assistant.",
        "Answer with concise and executable examples."
      )
    ),
    list(
      role = "user",
      content = "Show me how to calculate grouped means with aggregate()."
    )
  ),
  temperature = 0.2
)

cat(
  response$choices[[1]]$message$content
)

cat(
  "\n\nModel used:",
  response$model,
  "\n"
)
```

---

# Data-frame analysis

The v2 client includes `analyze_dataframe()`, which builds a compact prompt from a data frame, its columns, summary statistics, and a configurable sample of rows.

## Example: analyze `mtcars`

This example is fully reproducible because `mtcars` ships with R.

```r
Sys.setenv(LLM7_API_KEY = "your-token")

source("llm7.R")
client <- create_llm7_client()

data(mtcars)

answer <- client$analyze_dataframe(
  df = mtcars,
  question = paste(
    "Analyze this dataset as an automotive data analyst.",
    "Which variables appear most strongly related to fuel efficiency (mpg)?",
    "Compare weight, horsepower, cylinders, and transmission type.",
    "Explain the main patterns and mention any limitations of the sample."
  ),
  model = "default",
  max_rows = 10,
  max_columns = 11
)

cat(answer)
```

A more targeted prompt:

```r
answer <- client$analyze_dataframe(
  df = mtcars,
  question = paste(
    "Compare automatic and manual cars.",
    "Focus on mpg, horsepower, weight, and quarter-mile time.",
    "Give me a concise conclusion."
  ),
  model = "pro",
  max_rows = 12
)

cat(answer)
```

## Example: analyze `iris`

```r
data(iris)

answer <- client$analyze_dataframe(
  df = iris,
  question = paste(
    "Compare setosa, versicolor, and virginica.",
    "Which measurements best distinguish the species?",
    "Explain the answer as if you were preparing",
    "a first exploratory data analysis report."
  ),
  model = "default",
  max_rows = 12,
  max_columns = 5
)

cat(answer)
```

## Example with your own data frame

```r
sales <- data.frame(
  month = c("Jan", "Feb", "Mar", "Apr", "May", "Jun"),
  revenue = c(12000, 13500, 12800, 15100, 16900, 18100),
  customers = c(210, 225, 219, 250, 273, 290),
  ad_spend = c(1200, 1400, 1300, 1600, 1800, 1900)
)

answer <- client$analyze_dataframe(
  df = sales,
  question = paste(
    "Analyze the business trend.",
    "Is revenue growth accompanied by customer growth?",
    "Does higher advertising spend appear to be associated with",
    "higher revenue?",
    "Give three actionable observations."
  ),
  model = "default"
)

cat(answer)
```

---

# Ask questions about a data frame manually

You can also build your own prompt and use the ordinary chat method.

```r
data(mtcars)

sample_data <- paste(
  capture.output(
    write.csv(
      head(mtcars, 8),
      row.names = FALSE
    )
  ),
  collapse = "\n"
)

prompt <- paste0(
  "Here is a sample from the mtcars dataset:\n\n",
  sample_data,
  "\n\n",
  "Question: Which cars appear most fuel efficient ",
  "relative to their weight and horsepower?"
)

answer <- client$simple_completion(
  prompt = prompt,
  model = "default"
)

cat(answer)
```

For most use cases, `analyze_dataframe()` is easier because it constructs this context automatically.

---

# Streaming responses

Streaming is useful for longer answers.

```r
result <- client$simple_completion(
  prompt = paste(
    "Teach me how principal component analysis works.",
    "Use an intuitive explanation followed by an R example."
  ),
  model = "fast",
  stream = TRUE,
  on_delta = function(text, chunk) {
    cat(text)
  },
  return_response = TRUE
)

cat(
  "\n\nModel used:",
  result$model,
  "\n"
)

cat(
  "Finish reason:",
  result$finish_reason,
  "\n"
)
```

If you do not need incremental printing:

```r
text <- client$simple_completion(
  prompt = "Explain Bayesian inference in five paragraphs.",
  model = "fast",
  stream = TRUE
)

cat(text)
```

---

# JSON mode

Choose a model that advertises JSON-mode support:

```r
json_models <- client$find_models(
  model_type = "chat",
  json_mode = TRUE
)

if (length(json_models) == 0) {
  stop("No JSON-mode model is currently available.")
}

json_model <- json_models[[1]]$id
```

Request structured output:

```r
result <- client$json_completion(
  prompt = paste(
    "Return information about Madrid.",
    "Use the fields city, country, language,",
    "currency, and population_estimate."
  ),
  model = json_model
)

str(result)
```

Example request for an R workflow:

```r
result <- client$json_completion(
  prompt = paste(
    "Create a small analysis plan for the mtcars dataset.",
    "Return a JSON object with keys:",
    "objective, variables, methods, and visualizations."
  ),
  model = json_model
)

str(result)
```

---

# Function / tool calling

Find a compatible model:

```r
tool_models <- client$find_models(
  model_type = "chat",
  tools_calling = TRUE
)

if (length(tool_models) == 0) {
  stop("No tool-calling model is currently available.")
}

tool_model <- tool_models[[1]]$id
```

Define a function schema:

```r
tools <- list(
  list(
    type = "function",
    function = list(
      name = "get_weather",
      description = "Get the current weather for a city",
      parameters = list(
        type = "object",
        properties = list(
          city = list(
            type = "string",
            description = "City name"
          )
        ),
        required = list("city")
      )
    )
  )
)
```

Ask the model:

```r
response <- client$chat_completion(
  model = tool_model,
  messages = list(
    list(
      role = "user",
      content = "What is the weather in London?"
    )
  ),
  tools = tools,
  tool_choice = "auto"
)

response$choices[[1]]$message$tool_calls
```

Your application must execute the requested function and return the result with the matching `tool_call_id`.

---

# Vision / image recognition

The current LLM7 vision workflow expects a publicly reachable HTTPS image URL.

Choose a vision-capable model:

```r
vision_models <- client$find_models(
  model_type = "chat",
  input_modality = "image"
)

if (length(vision_models) == 0) {
  stop("No vision-capable model is currently available.")
}

vision_model <- vision_models[[1]]$id
```

Ask about an image:

```r
answer <- client$analyze_image(
  image_url = paste0(
    "https://images.weserv.nl/",
    "?url=wsrv.nl/lichtenstein.jpg",
    "&w=600&output=webp"
  ),
  question = paste(
    "Describe this image.",
    "Identify the main subject, composition, colors,",
    "and overall visual style."
  ),
  model = vision_model
)

cat(answer)
```

## Analyze a local R plot

The recommended workflow is to upload the plot to a publicly reachable HTTPS URL.

For backward-compatible local testing, v2 also provides an explicit data-URI mode:

```r
data(iris)

png(
  "iris_plot.png",
  width = 900,
  height = 600
)

plot(
  iris$Sepal.Length,
  iris$Petal.Length,
  col = as.integer(iris$Species),
  pch = 19,
  xlab = "Sepal length",
  ylab = "Petal length",
  main = "Iris: sepal length vs petal length"
)

legend(
  "topleft",
  legend = levels(iris$Species),
  col = seq_along(levels(iris$Species)),
  pch = 19
)

dev.off()

answer <- client$analyze_plot(
  image_path = "iris_plot.png",
  question = paste(
    "Analyze this scatter plot.",
    "Describe the clusters and explain",
    "which species appear easiest to separate."
  ),
  model = vision_model,
  allow_data_uri = TRUE
)

cat(answer)
```

The data-URI path is a compatibility option; public HTTPS URLs are the documented LLM7 workflow.

---

# Image generation

Image generation requires a concrete model from the live model catalog.

```r
image_models <- client$find_models(
  output_modality = "image"
)

if (length(image_models) == 0) {
  stop("No image-generation model is currently available.")
}

image_model <- image_models[[1]]$id

cat(
  "Using image model:",
  image_model,
  "\n"
)
```

Generate an image:

```r
result <- client$generate_image(
  prompt = paste(
    "A clean editorial photograph of a data scientist's desk,",
    "laptop displaying an R visualization,",
    "soft natural light, minimal composition"
  ),
  model = image_model,
  size = "1024x1024",
  output_file = "generated.png"
)

result$saved_to
```

Edit an existing image:

```r
edited <- client$edit_image(
  image_paths = c("room.png"),
  prompt = paste(
    "Add a framed abstract data visualization",
    "to the empty wall while preserving the room."
  ),
  model = image_model,
  size = "1024x1024",
  output_file = "edited.png"
)

edited$saved_to
```

---

# Video generation

Video generation is asynchronous.

Find a compatible model:

```r
video_models <- client$find_models(
  model_type = "video",
  output_modality = "video"
)

if (length(video_models) == 0) {
  stop("No video-generation model is currently available.")
}

video_model <- video_models[[1]]

str(video_model$capabilities)
```

Use values advertised by the selected model:

```r
request_id <- paste0(
  "llm7r-video-",
  as.integer(Sys.time())
)

task <- client$create_video(
  prompt = paste(
    "Ocean waves crashing against dark rocks,",
    "cinematic slow motion, natural light."
  ),
  model = video_model$id,
  duration = video_model$capabilities$supported_seconds[[1]],
  resolution = video_model$capabilities$supported_sizes[[1]],
  idempotency_key = request_id,
  client_request_id = request_id
)

cat(
  "Video task:",
  task$id,
  "\n"
)
```

Wait for completion:

```r
finished <- client$wait_for_video(
  video_id = task$id,
  poll_interval = 5,
  timeout = 600
)

print(finished$status)
```

Download the video:

```r
if (identical(
  finished$status,
  "completed"
)) {
  client$download_video(
    video_id = task$id,
    output_file = "output.mp4"
  )
}
```

For image-to-video:

```r
task <- client$create_video(
  prompt = "Slow camera movement with subtle natural motion.",
  model = video_model$id,
  duration = video_model$capabilities$supported_seconds[[1]],
  resolution = video_model$capabilities$supported_sizes[[1]],
  input_references = c("reference.png")
)
```

---

# Configuration

Inspect the active configuration:

```r
print_config()
```

Change the default chat selector:

```r
set_config(
  "models.text",
  "fast"
)
```

Change the default temperature:

```r
set_config(
  "generation.temperature",
  0.2
)
```

Increase the request timeout:

```r
set_config(
  "request.timeout",
  120
)
```

New clients use those defaults:

```r
client <- create_llm7_client()

answer <- client$simple_completion(
  "Give me three ways to inspect missing values in an R data frame."
)

cat(answer)
```

---

# Passing newer API fields

For chat fields that LLM7 may introduce after a client release, `chat_completion()` includes an `extra_body` escape hatch.

```r
response <- client$chat_completion(
  model = "default",
  messages = list(
    list(
      role = "user",
      content = "Hello"
    )
  ),
  extra_body = list(
    your_new_parameter = "value"
  )
)
```

Explicit `chat_completion()` arguments take precedence over duplicate fields in `extra_body`.

---

# Migrating from llm7R v1

Important changes in v2.0.0:

- `api_key = "unused"` is no longer the default authentication approach.
- Set `LLM7_API_KEY`, `LLM7_API_TOKEN`, or pass `api_key` explicitly.
- Text defaults now use `default`, `fast`, and `pro` selectors.
- Use `client$list_models()` and `client$find_models()` when you need a concrete model ID.
- Streaming now correctly parses SSE responses.
- Vision now follows the documented HTTPS-image workflow.
- Local data-URI vision is available only as an explicit compatibility mode.
- Streaming requires the R `curl` package.
- Image and video generation are supported in v2.

---

# LLM7 documentation

- <https://docs.llm7.io/quickstart>
- <https://docs.llm7.io/guides/models>
- <https://docs.llm7.io/guides/models-api>
- <https://docs.llm7.io/guides/streaming>
- <https://docs.llm7.io/guides/function-calling>
- <https://docs.llm7.io/guides/json-mode>
- <https://docs.llm7.io/guides/image-recognition>
- <https://docs.llm7.io/guides/image-generation>
- <https://docs.llm7.io/guides/video-generation>

---

## Author

Eduardo J. Barrios  
<https://edujbarrios.com>
