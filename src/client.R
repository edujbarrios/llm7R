# LLM7 Client Core
# ================
# OpenAI-compatible client for the current LLM7.io API.

library(httr)
library(jsonlite)

.llm7_has_text <- function(x) {
  is.character(x) && length(x) == 1 && !is.na(x) && nzchar(x)
}

.llm7_extract_text <- function(content) {
  if (is.null(content)) {
    return("")
  }

  if (is.character(content)) {
    return(paste0(content, collapse = ""))
  }

  if (is.list(content)) {
    parts <- vapply(content, function(part) {
      if (is.character(part)) {
        return(paste0(part, collapse = ""))
      }
      if (is.list(part) && !is.null(part$text)) {
        return(paste0(part$text, collapse = ""))
      }
      ""
    }, character(1))
    return(paste0(parts, collapse = ""))
  }

  as.character(content)
}

.llm7_error_message <- function(text) {
  parsed <- tryCatch(
    jsonlite::fromJSON(text, simplifyVector = FALSE),
    error = function(e) NULL
  )

  if (is.list(parsed) && !is.null(parsed$error$message)) {
    return(parsed$error$message)
  }
  if (is.list(parsed) && !is.null(parsed$message) && is.character(parsed$message)) {
    return(parsed$message)
  }

  trimmed <- trimws(text)
  if (nzchar(trimmed)) trimmed else "Unknown API error"
}

.llm7_build_chat_body <- function(model, messages, temperature = NULL,
                                  max_tokens = NULL, stream = FALSE,
                                  response_format = NULL, tools = NULL,
                                  tool_choice = NULL, extra_body = list()) {
  if (!is.list(messages) || length(messages) == 0) {
    stop("messages must be a non-empty list of chat messages")
  }
  if (!is.list(extra_body)) {
    stop("extra_body must be a named list")
  }

  body <- list(
    model = model,
    messages = messages
  )

  if (!is.null(temperature)) body$temperature <- temperature
  if (!is.null(max_tokens)) body$max_tokens <- max_tokens
  if (isTRUE(stream)) body$stream <- TRUE
  if (!is.null(response_format)) body$response_format <- response_format
  if (!is.null(tools)) body$tools <- tools
  if (!is.null(tool_choice)) body$tool_choice <- tool_choice

  if (length(extra_body) > 0) {
    if (is.null(names(extra_body)) || any(!nzchar(names(extra_body)))) {
      stop("extra_body must be a named list")
    }
    # Explicit method arguments take precedence over duplicate extra fields.
    body <- utils::modifyList(extra_body, body)
  }

  body
}

#' LLM7 Client Class
#'
#' @description
#' A lightweight R client for LLM7.io's OpenAI-compatible API.
#'
#' @field api_key Bearer token used for authenticated endpoints
#' @field base_url API base URL
#' @field config Configuration list
#'
#' @export
LLM7Client <- setRefClass(
  "LLM7Client",
  fields = list(
    api_key = "character",
    base_url = "character",
    config = "list"
  ),
  methods = list(
    initialize = function(api_key = NULL, base_url = NULL, config = NULL) {
      "Initialize the LLM7 client"

      if (is.null(config)) {
        if (exists("LLM7_CONFIG", envir = .GlobalEnv)) {
          .self$config <- get("LLM7_CONFIG", envir = .GlobalEnv)
        } else {
          .self$config <- list(
            base_url = "https://api.llm7.io/v1",
            api_key = "",
            models = list(text = "default", vision = "default"),
            generation = list(temperature = 0.7, stream = FALSE),
            request = list(timeout = 60, retry_attempts = 3, retry_delay = 1),
            debug = list(verbose = FALSE)
          )
        }
      } else {
        .self$config <- config
      }

      configured_key <- if (!is.null(.self$config$api_key)) .self$config$api_key else ""
      env_key <- Sys.getenv(
        "LLM7_API_KEY",
        unset = Sys.getenv("LLM7_API_TOKEN", unset = "")
      )

      .self$api_key <- if (.llm7_has_text(api_key)) {
        api_key
      } else if (.llm7_has_text(configured_key)) {
        configured_key
      } else {
        env_key
      }

      configured_base <- if (!is.null(.self$config$base_url)) {
        .self$config$base_url
      } else {
        "https://api.llm7.io/v1"
      }
      .self$base_url <- sub("/+$", "", if (!is.null(base_url)) base_url else configured_base)
    },

    require_api_key = function() {
      "Fail with a clear message when an authenticated call has no API token"
      if (!.llm7_has_text(.self$api_key)) {
        stop(
          "An LLM7 API token is required. Set LLM7_API_KEY (recommended), ",
          "LLM7_API_TOKEN, or pass api_key to create_llm7_client(). ",
          "Create/manage tokens at https://dash.llm7.io/."
        )
      }
      invisible(TRUE)
    },

    chat_completion = function(model = NULL, messages, temperature = NULL,
                               max_tokens = NULL, stream = NULL,
                               response_format = NULL, tools = NULL,
                               tool_choice = NULL, extra_body = list(),
                               on_delta = NULL) {
      "Send a chat completion request"

      .self$require_api_key()

      if (is.null(model)) model <- .self$config$models$text
      if (is.null(temperature)) temperature <- .self$config$generation$temperature
      if (is.null(stream)) stream <- isTRUE(.self$config$generation$stream)
      if (is.null(max_tokens) && !is.null(.self$config$generation$max_tokens)) {
        max_tokens <- .self$config$generation$max_tokens
      }

      if (isTRUE(stream)) {
        return(.self$stream_chat_completion(
          model = model,
          messages = messages,
          temperature = temperature,
          max_tokens = max_tokens,
          response_format = response_format,
          tools = tools,
          tool_choice = tool_choice,
          extra_body = extra_body,
          on_delta = on_delta
        ))
      }

      endpoint <- paste0(.self$base_url, "/chat/completions")
      body <- .llm7_build_chat_body(
        model = model,
        messages = messages,
        temperature = temperature,
        max_tokens = max_tokens,
        stream = FALSE,
        response_format = response_format,
        tools = tools,
        tool_choice = tool_choice,
        extra_body = extra_body
      )

      if (isTRUE(.self$config$debug$verbose)) {
        cat("POST", endpoint, "\n")
        cat("Model:", model, "\n")
      }

      timeout_seconds <- if (!is.null(.self$config$request$timeout)) {
        .self$config$request$timeout
      } else 60
      retry_attempts <- if (!is.null(.self$config$request$retry_attempts)) {
        .self$config$request$retry_attempts
      } else 3
      retry_delay <- if (!is.null(.self$config$request$retry_delay)) {
        .self$config$request$retry_delay
      } else 1

      response <- httr::RETRY(
        "POST",
        endpoint,
        httr::add_headers(
          Authorization = paste("Bearer", .self$api_key),
          `Content-Type` = "application/json",
          Accept = "application/json"
        ),
        httr::timeout(timeout_seconds),
        body = jsonlite::toJSON(body, auto_unbox = TRUE, null = "null"),
        encode = "raw",
        times = retry_attempts,
        pause_base = retry_delay,
        terminate_on = c(400, 401, 403, 404, 422),
        quiet = !isTRUE(.self$config$debug$verbose)
      )

      response_text <- httr::content(response, as = "text", encoding = "UTF-8")
      if (httr::http_error(response)) {
        stop(sprintf(
          "LLM7 API request failed with status %s: %s",
          httr::status_code(response),
          .llm7_error_message(response_text)
        ))
      }

      result <- jsonlite::fromJSON(response_text, simplifyVector = FALSE)

      if (isTRUE(.self$config$debug$verbose)) {
        cat("Response received successfully\n")
        if (!is.null(result$model)) cat("Model selected:", result$model, "\n")
      }

      result
    },

    stream_chat_completion = function(model = NULL, messages, temperature = NULL,
                                      max_tokens = NULL, response_format = NULL,
                                      tools = NULL, tool_choice = NULL,
                                      extra_body = list(), on_delta = NULL) {
      "Stream a chat completion using server-sent events"

      .self$require_api_key()
      if (!requireNamespace("curl", quietly = TRUE)) {
        stop("The 'curl' package is required for streaming. Install it with install.packages('curl').")
      }

      if (is.null(model)) model <- .self$config$models$text
      if (is.null(temperature)) temperature <- .self$config$generation$temperature
      if (is.null(max_tokens) && !is.null(.self$config$generation$max_tokens)) {
        max_tokens <- .self$config$generation$max_tokens
      }
      if (!is.null(on_delta) && !is.function(on_delta)) {
        stop("on_delta must be a function accepting (text, chunk)")
      }

      endpoint <- paste0(.self$base_url, "/chat/completions")
      body <- .llm7_build_chat_body(
        model = model,
        messages = messages,
        temperature = temperature,
        max_tokens = max_tokens,
        stream = TRUE,
        response_format = response_format,
        tools = tools,
        tool_choice = tool_choice,
        extra_body = extra_body
      )
      json_body <- jsonlite::toJSON(body, auto_unbox = TRUE, null = "null")

      timeout_seconds <- if (!is.null(.self$config$request$timeout)) {
        .self$config$request$timeout
      } else 60

      handle <- curl::new_handle()
      curl::handle_setheaders(
        handle,
        .list = c(
          Authorization = paste("Bearer", .self$api_key),
          `Content-Type` = "application/json",
          Accept = "text/event-stream"
        )
      )
      curl::handle_setopt(
        handle,
        post = TRUE,
        postfields = json_body,
        timeout = timeout_seconds
      )

      raw_buffer <- raw()
      raw_response <- raw()
      chunks <- list()
      text_parts <- character()
      model_used <- NULL
      finish_reason <- NULL

      process_event <- function(event) {
        event <- trimws(event)
        if (!nzchar(event)) return(invisible(NULL))

        lines <- strsplit(event, "\n", fixed = TRUE)[[1]]
        data_lines <- lines[grepl("^data:", lines)]
        if (length(data_lines) == 0) return(invisible(NULL))

        payload <- paste(sub("^data:[[:space:]]?", "", data_lines), collapse = "\n")
        if (identical(trimws(payload), "[DONE]")) return(invisible(NULL))

        chunk <- tryCatch(
          jsonlite::fromJSON(payload, simplifyVector = FALSE),
          error = function(e) NULL
        )
        if (is.null(chunk)) return(invisible(NULL))

        chunks <<- c(chunks, list(chunk))
        if (!is.null(chunk$model)) model_used <<- chunk$model

        if (!is.null(chunk$choices) && length(chunk$choices) > 0) {
          choice <- chunk$choices[[1]]
          if (!is.null(choice$finish_reason)) finish_reason <<- choice$finish_reason

          delta_text <- ""
          if (!is.null(choice$delta)) {
            delta_text <- .llm7_extract_text(choice$delta$content)
          }

          if (nzchar(delta_text)) {
            text_parts <<- c(text_parts, delta_text)
            if (is.function(on_delta)) on_delta(delta_text, chunk)
          }
        }

        invisible(NULL)
      }

      stream_callback <- function(data) {
        # Normalize CRLF to LF at the byte level. This also avoids converting a
        # partial multi-byte UTF-8 character before a complete SSE event arrives.
        data <- data[data != as.raw(13)]
        raw_response <<- c(raw_response, data)
        raw_buffer <<- c(raw_buffer, data)

        repeat {
          if (length(raw_buffer) < 2) break

          left <- raw_buffer[-length(raw_buffer)]
          right <- raw_buffer[-1]
          separators <- which(left == as.raw(10) & right == as.raw(10))
          if (length(separators) == 0) break

          separator <- separators[[1]]
          event_raw <- if (separator > 1) raw_buffer[seq_len(separator - 1)] else raw()
          raw_buffer <<- if (separator + 2 <= length(raw_buffer)) {
            raw_buffer[(separator + 2):length(raw_buffer)]
          } else {
            raw()
          }

          process_event(rawToChar(event_raw))
        }

        TRUE
      }

      if (isTRUE(.self$config$debug$verbose)) {
        cat("POST", endpoint, "(stream)\n")
        cat("Model:", model, "\n")
      }

      response <- curl::curl_fetch_stream(endpoint, stream_callback, handle = handle)

      if (response$status_code >= 400) {
        stop(sprintf(
          "LLM7 API request failed with status %s: %s",
          response$status_code,
          .llm7_error_message(rawToChar(raw_response))
        ))
      }

      if (length(raw_buffer) > 0) {
        process_event(rawToChar(raw_buffer))
      }

      list(
        text = paste0(text_parts, collapse = ""),
        model = model_used,
        finish_reason = finish_reason,
        chunks = chunks,
        status_code = response$status_code
      )
    },

    simple_completion = function(prompt, model = NULL, temperature = NULL,
                                 max_tokens = NULL, stream = FALSE,
                                 on_delta = NULL, return_response = FALSE,
                                 extra_body = list()) {
      "Send a simple user prompt"

      messages <- list(list(role = "user", content = prompt))

      if (isTRUE(stream)) {
        streamed <- .self$stream_chat_completion(
          model = model,
          messages = messages,
          temperature = temperature,
          max_tokens = max_tokens,
          extra_body = extra_body,
          on_delta = on_delta
        )
        return(if (isTRUE(return_response)) streamed else streamed$text)
      }

      response <- .self$chat_completion(
        model = model,
        messages = messages,
        temperature = temperature,
        max_tokens = max_tokens,
        extra_body = extra_body
      )

      if (isTRUE(return_response)) return(response)
      if (is.null(response$choices) || length(response$choices) == 0) return(NULL)

      .llm7_extract_text(response$choices[[1]]$message$content)
    },

    json_completion = function(prompt, model = NULL, temperature = 0.2,
                               parse = TRUE, extra_body = list()) {
      "Request a JSON object using LLM7 JSON mode"

      if (is.null(model)) {
        candidates <- .self$find_models(model_type = "chat", json_mode = TRUE)
        if (length(candidates) == 0) {
          stop("No JSON-mode chat model is currently available in /v1/models")
        }
        model <- candidates[[1]]$id
      }

      response <- .self$chat_completion(
        model = model,
        messages = list(
          list(role = "system", content = "Answer with valid JSON only."),
          list(role = "user", content = prompt)
        ),
        temperature = temperature,
        response_format = list(type = "json_object"),
        extra_body = extra_body
      )

      text <- if (!is.null(response$choices) && length(response$choices) > 0) {
        .llm7_extract_text(response$choices[[1]]$message$content)
      } else {
        ""
      }

      if (!isTRUE(parse)) return(text)
      jsonlite::fromJSON(text, simplifyVector = FALSE)
    },

    list_models = function() {
      "List the live LLM7 model catalog"

      endpoint <- paste0(.self$base_url, "/models")
      timeout_seconds <- if (!is.null(.self$config$request$timeout)) {
        .self$config$request$timeout
      } else 60
      retry_attempts <- if (!is.null(.self$config$request$retry_attempts)) {
        .self$config$request$retry_attempts
      } else 3
      retry_delay <- if (!is.null(.self$config$request$retry_delay)) {
        .self$config$request$retry_delay
      } else 1

      headers <- list(Accept = "application/json")
      if (.llm7_has_text(.self$api_key)) {
        headers$Authorization <- paste("Bearer", .self$api_key)
      }

      response <- httr::RETRY(
        "GET",
        endpoint,
        do.call(httr::add_headers, headers),
        httr::timeout(timeout_seconds),
        times = retry_attempts,
        pause_base = retry_delay,
        terminate_on = c(400, 401, 403, 404, 422),
        quiet = !isTRUE(.self$config$debug$verbose)
      )

      response_text <- httr::content(response, as = "text", encoding = "UTF-8")
      if (httr::http_error(response)) {
        stop(sprintf(
          "LLM7 API request failed with status %s: %s",
          httr::status_code(response),
          .llm7_error_message(response_text)
        ))
      }

      jsonlite::fromJSON(response_text, simplifyVector = FALSE)
    },

    find_models = function(model_type = NULL, tier = NULL,
                           input_modality = NULL, output_modality = NULL,
                           stream = NULL, json_mode = NULL,
                           tools_calling = NULL, reasoning = NULL) {
      "Filter the live model catalog by capabilities"

      catalog <- .self$list_models()
      models <- catalog$data
      if (is.null(models)) return(list())

      Filter(function(model) {
        if (!is.null(model_type) && !identical(model$model_type, model_type)) return(FALSE)
        if (!is.null(tier) && !identical(model$tier, tier)) return(FALSE)
        if (!is.null(input_modality) &&
            !(input_modality %in% (model$modalities$input %||% character()))) return(FALSE)
        if (!is.null(output_modality) &&
            !(output_modality %in% (model$modalities$output %||% character()))) return(FALSE)
        if (!is.null(stream) && !identical(isTRUE(model$stream), isTRUE(stream))) return(FALSE)
        if (!is.null(json_mode) && !identical(isTRUE(model$json_mode), isTRUE(json_mode))) return(FALSE)
        if (!is.null(tools_calling) &&
            !identical(isTRUE(model$tools_calling), isTRUE(tools_calling))) return(FALSE)
        if (!is.null(reasoning) && !identical(isTRUE(model$reasoning), isTRUE(reasoning))) return(FALSE)
        TRUE
      }, models)
    }
  )
)

# Small null-coalescing helper used by find_models().
`%||%` <- function(x, y) if (is.null(x)) y else x

#' Create a new LLM7 client
#'
#' @param api_key API token. Defaults to LLM7_API_KEY or LLM7_API_TOKEN.
#' @param base_url API base URL.
#' @param config Configuration list. Defaults to global LLM7_CONFIG.
#' @return A new LLM7Client object
#' @export
create_llm7_client <- function(api_key = NULL, base_url = NULL, config = NULL) {
  LLM7Client$new(api_key = api_key, base_url = base_url, config = config)
}
