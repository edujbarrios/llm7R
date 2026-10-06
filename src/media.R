# Image and Video Generation Module
# =================================
# Current LLM7 image and asynchronous video generation endpoints.

.llm7_media_timeout <- function(config) {
  if (!is.null(config$request$timeout)) config$request$timeout else 60
}

.llm7_parse_api_response <- function(response) {
  text <- httr::content(response, as = "text", encoding = "UTF-8")
  if (httr::http_error(response)) {
    stop(sprintf(
      "LLM7 API request failed with status %s: %s",
      httr::status_code(response),
      .llm7_error_message(text)
    ))
  }

  if (!nzchar(trimws(text))) return(list())
  jsonlite::fromJSON(text, simplifyVector = FALSE)
}

.llm7_save_b64_image <- function(result, output_file) {
  if (is.null(output_file)) return(result)

  if (is.null(result$data) || length(result$data) == 0 ||
      is.null(result$data[[1]]$b64_json)) {
    stop("LLM7 image response did not contain data[0].b64_json")
  }

  bytes <- base64enc::base64decode(result$data[[1]]$b64_json)
  writeBin(bytes, output_file)
  result$saved_to <- normalizePath(output_file, winslash = "/", mustWork = FALSE)
  result
}

media_methods <- function() {
  LLM7Client$methods(
    generate_image = function(prompt, model, size = NULL, n = 1,
                              output_file = NULL) {
      "Generate an image using POST /images/generations"

      .self$require_api_key()
      if (!.llm7_has_text(model)) {
        stop("model is required and must be a concrete image model ID from /v1/models")
      }
      if (!.llm7_has_text(prompt)) stop("prompt must be a non-empty string")
      if (!is.numeric(n) || length(n) != 1 || is.na(n) || n != 1) {
        stop("LLM7 image generation currently supports n = 1 only")
      }

      body <- list(model = model, prompt = prompt, n = 1L)
      if (!is.null(size)) body$size <- size

      response <- httr::POST(
        paste0(.self$base_url, "/images/generations"),
        httr::add_headers(
          Authorization = paste("Bearer", .self$api_key),
          `Content-Type` = "application/json",
          Accept = "application/json"
        ),
        httr::timeout(.llm7_media_timeout(.self$config)),
        body = jsonlite::toJSON(body, auto_unbox = TRUE, null = "null"),
        encode = "raw"
      )

      result <- .llm7_parse_api_response(response)
      .llm7_save_b64_image(result, output_file)
    },

    edit_image = function(image_paths, prompt, model, size = NULL,
                          output_file = NULL) {
      "Edit one or more reference images using POST /images/edits"

      .self$require_api_key()
      if (!.llm7_has_text(model)) {
        stop("model is required and must be a concrete image model ID from /v1/models")
      }
      if (!.llm7_has_text(prompt)) stop("prompt must be a non-empty string")
      if (length(image_paths) == 0) stop("image_paths must contain at least one file")
      missing <- image_paths[!file.exists(image_paths)]
      if (length(missing) > 0) stop("Image file not found: ", missing[[1]])

      fields <- list(model = model, prompt = prompt)
      if (!is.null(size)) fields$size <- size
      uploads <- setNames(
        lapply(image_paths, function(path) httr::upload_file(path)),
        rep("image", length(image_paths))
      )

      response <- httr::POST(
        paste0(.self$base_url, "/images/edits"),
        httr::add_headers(
          Authorization = paste("Bearer", .self$api_key),
          Accept = "application/json"
        ),
        httr::timeout(.llm7_media_timeout(.self$config)),
        body = c(fields, uploads),
        encode = "multipart"
      )

      result <- .llm7_parse_api_response(response)
      .llm7_save_b64_image(result, output_file)
    },

    create_video = function(prompt, model, request_type = NULL,
                            duration = NULL, resolution = NULL,
                            seconds = NULL, size = NULL,
                            client_request_id = NULL,
                            idempotency_key = NULL,
                            input_references = character()) {
      "Create an asynchronous video task using POST /videos"

      .self$require_api_key()
      if (!.llm7_has_text(model)) {
        stop("model is required and must be a concrete video model ID from /v1/models")
      }
      if (!.llm7_has_text(prompt)) stop("prompt must be a non-empty string")

      has_references <- length(input_references) > 0
      if (is.null(request_type)) {
        request_type <- if (has_references) "image-to-video" else "text-to-video"
      }
      if (!request_type %in% c("text-to-video", "image-to-video")) {
        stop("request_type must be 'text-to-video' or 'image-to-video'")
      }
      if (has_references && request_type != "image-to-video") {
        stop("Requests with input_references must use request_type = 'image-to-video'")
      }
      if (!has_references && request_type == "image-to-video") {
        stop("image-to-video requests require at least one input_reference file")
      }
      if (is.null(duration) && is.null(seconds)) {
        stop("Provide duration (preferred) or seconds, using a value supported by the selected model")
      }

      if (has_references) {
        missing <- input_references[!file.exists(input_references)]
        if (length(missing) > 0) stop("Reference image not found: ", missing[[1]])
      }

      fields <- list(
        model = model,
        request_type = request_type,
        prompt = prompt
      )
      if (!is.null(duration)) fields$duration <- duration
      if (!is.null(resolution)) fields$resolution <- resolution
      if (!is.null(seconds)) fields$seconds <- seconds
      if (!is.null(size)) fields$size <- size
      if (!is.null(client_request_id)) fields$client_request_id <- client_request_id

      headers <- list(
        Authorization = paste("Bearer", .self$api_key),
        Accept = "application/json"
      )
      if (.llm7_has_text(idempotency_key)) {
        headers[["Idempotency-Key"]] <- idempotency_key
        if (is.null(fields$client_request_id)) fields$client_request_id <- idempotency_key
      }

      endpoint <- paste0(.self$base_url, "/videos")
      if (has_references) {
        uploads <- setNames(
          lapply(input_references, function(path) httr::upload_file(path)),
          rep("input_reference", length(input_references))
        )
        response <- httr::POST(
          endpoint,
          do.call(httr::add_headers, headers),
          httr::timeout(.llm7_media_timeout(.self$config)),
          body = c(fields, uploads),
          encode = "multipart"
        )
      } else {
        response <- httr::POST(
          endpoint,
          do.call(httr::add_headers, c(headers, list(`Content-Type` = "application/json"))),
          httr::timeout(.llm7_media_timeout(.self$config)),
          body = jsonlite::toJSON(fields, auto_unbox = TRUE, null = "null"),
          encode = "raw"
        )
      }

      .llm7_parse_api_response(response)
    },

    get_video = function(video_id) {
      "Retrieve the status of an asynchronous video task"

      .self$require_api_key()
      if (!.llm7_has_text(video_id)) stop("video_id must be a non-empty string")

      response <- httr::GET(
        paste0(.self$base_url, "/videos/", utils::URLencode(video_id, reserved = TRUE)),
        httr::add_headers(
          Authorization = paste("Bearer", .self$api_key),
          Accept = "application/json"
        ),
        httr::timeout(.llm7_media_timeout(.self$config))
      )
      .llm7_parse_api_response(response)
    },

    wait_for_video = function(video_id, poll_interval = 5, timeout = 600) {
      "Poll a video task until it completes, fails, times out, or the client timeout is reached"

      if (!is.numeric(poll_interval) || length(poll_interval) != 1 || poll_interval <= 0) {
        stop("poll_interval must be a positive number of seconds")
      }
      if (!is.numeric(timeout) || length(timeout) != 1 || timeout <= 0) {
        stop("timeout must be a positive number of seconds")
      }

      started <- Sys.time()
      repeat {
        result <- .self$get_video(video_id)
        status <- result$status %||% ""
        if (status %in% c("completed", "failed", "timeout")) return(result)

        if (as.numeric(difftime(Sys.time(), started, units = "secs")) >= timeout) {
          stop("Timed out waiting for LLM7 video task ", video_id)
        }
        Sys.sleep(poll_interval)
      }
    },

    download_video = function(video_id, output_file) {
      "Download completed video bytes from GET /videos/{id}/content"

      .self$require_api_key()
      if (!.llm7_has_text(video_id)) stop("video_id must be a non-empty string")
      if (!.llm7_has_text(output_file)) stop("output_file must be a non-empty path")

      endpoint <- paste0(
        .self$base_url,
        "/videos/",
        utils::URLencode(video_id, reserved = TRUE),
        "/content"
      )

      # Do not forward the bearer token to a third-party storage host when the
      # API responds with a signed redirect URL.
      response <- httr::GET(
        endpoint,
        httr::add_headers(Authorization = paste("Bearer", .self$api_key)),
        httr::config(followlocation = 0L),
        httr::timeout(max(.llm7_media_timeout(.self$config), 300)),
        httr::write_disk(output_file, overwrite = TRUE)
      )

      status <- httr::status_code(response)
      if (status >= 300 && status < 400) {
        location <- httr::headers(response)$location
        unlink(output_file)
        if (!.llm7_has_text(location)) {
          stop("LLM7 video download redirected without a Location header")
        }
        response <- httr::GET(
          location,
          httr::timeout(max(.llm7_media_timeout(.self$config), 300)),
          httr::write_disk(output_file, overwrite = TRUE)
        )
        status <- httr::status_code(response)
      }

      if (status >= 400) {
        body <- tryCatch(
          paste(readLines(output_file, warn = FALSE, encoding = "UTF-8"), collapse = "\n"),
          error = function(e) ""
        )
        unlink(output_file)
        stop(sprintf(
          "LLM7 API request failed with status %s: %s",
          status,
          .llm7_error_message(body)
        ))
      }

      normalizePath(output_file, winslash = "/", mustWork = FALSE)
    }
  )
}

media_methods()
