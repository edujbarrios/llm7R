# Vision/Image Analysis Module
# ============================
# LLM7 vision uses the chat-completions endpoint with image_url content parts.

library(base64enc)

.llm7_validate_https_url <- function(url) {
  if (!is.character(url) || length(url) != 1 || !grepl("^https://", url, ignore.case = TRUE)) {
    stop("LLM7 image recognition requires a publicly reachable HTTPS image URL.")
  }
  url
}

.llm7_local_image_data_uri <- function(image_path, supported_formats) {
  if (!file.exists(image_path)) {
    stop(sprintf("Image file not found: %s", image_path))
  }

  ext <- tolower(tools::file_ext(image_path))
  if (!ext %in% supported_formats) {
    stop(sprintf(
      "Unsupported image format '%s'. Supported local formats: %s",
      ext, paste(supported_formats, collapse = ", ")
    ))
  }

  mime_type <- switch(
    ext,
    png = "image/png",
    jpg = "image/jpeg",
    jpeg = "image/jpeg",
    gif = "image/gif",
    webp = "image/webp"
  )

  image_data <- readBin(image_path, "raw", file.info(image_path)$size)
  image_base64 <- base64enc::base64encode(image_data)
  sprintf("data:%s;base64,%s", mime_type, image_base64)
}

vision_methods <- function() {
  LLM7Client$methods(
    analyze_image = function(image_url, question, model = NULL, detail = NULL) {
      "Analyze a publicly reachable HTTPS image"

      if (is.null(model)) model <- .self$config$models$vision
      if (is.null(detail)) detail <- .self$config$vision$detail
      image_url <- .llm7_validate_https_url(image_url)

      image_part <- list(url = image_url)
      # detail is accepted by OpenAI-compatible clients but not required by the
      # current LLM7 vision guide, so only include it when explicitly configured.
      if (!is.null(detail) && nzchar(detail)) image_part$detail <- detail

      response <- .self$chat_completion(
        model = model,
        messages = list(
          list(
            role = "user",
            content = list(
              list(type = "text", text = question),
              list(type = "image_url", image_url = image_part)
            )
          )
        )
      )

      if (is.null(response$choices) || length(response$choices) == 0) return(NULL)
      .llm7_extract_text(response$choices[[1]]$message$content)
    },

    analyze_images = function(image_urls, question, model = NULL, detail = NULL) {
      "Analyze multiple publicly reachable HTTPS images"

      if (is.null(model)) model <- .self$config$models$vision
      if (is.null(detail)) detail <- .self$config$vision$detail
      if (length(image_urls) == 0) stop("image_urls must contain at least one URL")

      content <- list(list(type = "text", text = question))
      for (url in image_urls) {
        url <- .llm7_validate_https_url(url)
        image_part <- list(url = url)
        if (!is.null(detail) && nzchar(detail)) image_part$detail <- detail
        content <- c(content, list(list(type = "image_url", image_url = image_part)))
      }

      response <- .self$chat_completion(
        model = model,
        messages = list(list(role = "user", content = content))
      )

      if (is.null(response$choices) || length(response$choices) == 0) return(NULL)
      .llm7_extract_text(response$choices[[1]]$message$content)
    },

    analyze_plot = function(image_path, question, model = NULL, detail = NULL,
                            allow_data_uri = FALSE) {
      "Analyze a plot URL; local data-URI fallback is opt-in for compatibility"

      if (grepl("^https://", image_path, ignore.case = TRUE)) {
        return(.self$analyze_image(
          image_url = image_path,
          question = question,
          model = model,
          detail = detail
        ))
      }

      if (!isTRUE(allow_data_uri)) {
        stop(
          "The current LLM7 vision documentation requires a publicly reachable HTTPS image URL. ",
          "Upload the plot and pass its HTTPS URL to analyze_image() or analyze_plot(). ",
          "For legacy best-effort behavior, set allow_data_uri = TRUE."
        )
      }

      warning(
        "Using a data URI is a legacy compatibility path and is not documented by the current LLM7 vision guide."
      )

      if (is.null(model)) model <- .self$config$models$vision
      if (is.null(detail)) detail <- .self$config$vision$detail
      data_uri <- .llm7_local_image_data_uri(
        image_path,
        .self$config$vision$supported_formats
      )

      response <- .self$chat_completion(
        model = model,
        messages = list(
          list(
            role = "user",
            content = list(
              list(type = "text", text = question),
              list(
                type = "image_url",
                image_url = if (is.null(detail)) list(url = data_uri) else list(url = data_uri, detail = detail)
              )
            )
          )
        )
      )

      if (is.null(response$choices) || length(response$choices) == 0) return(NULL)
      .llm7_extract_text(response$choices[[1]]$message$content)
    },

    analyze_multiple_plots = function(image_paths, question, model = NULL,
                                      detail = NULL, allow_data_uri = FALSE) {
      "Analyze multiple image URLs; local data URIs are opt-in"

      if (length(image_paths) == 0) stop("image_paths must contain at least one item")

      if (all(grepl("^https://", image_paths, ignore.case = TRUE))) {
        return(.self$analyze_images(
          image_urls = image_paths,
          question = question,
          model = model,
          detail = detail
        ))
      }

      if (!isTRUE(allow_data_uri)) {
        stop(
          "The current LLM7 vision documentation requires publicly reachable HTTPS image URLs. ",
          "Use analyze_images() with HTTPS URLs, or set allow_data_uri = TRUE for legacy best-effort behavior."
        )
      }

      if (is.null(model)) model <- .self$config$models$vision
      if (is.null(detail)) detail <- .self$config$vision$detail
      warning(
        "Using data URIs is a legacy compatibility path and is not documented by the current LLM7 vision guide."
      )

      content <- list(list(type = "text", text = question))
      for (path in image_paths) {
        image_url <- if (grepl("^https://", path, ignore.case = TRUE)) {
          path
        } else {
          .llm7_local_image_data_uri(path, .self$config$vision$supported_formats)
        }

        content <- c(content, list(
          list(
            type = "image_url",
            image_url = if (is.null(detail)) list(url = image_url) else list(url = image_url, detail = detail)
          )
        ))
      }

      response <- .self$chat_completion(
        model = model,
        messages = list(list(role = "user", content = content))
      )

      if (is.null(response$choices) || length(response$choices) == 0) return(NULL)
      .llm7_extract_text(response$choices[[1]]$message$content)
    }
  )
}

vision_methods()
