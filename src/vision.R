# Vision/Image Analysis Module
# =============================
# Functions for analyzing images and plots with vision models

library(base64enc)

#' Analyze plot method for LLM7Client
#' 
#' @description
#' Adds image analysis methods to LLM7Client
vision_methods <- function() {
  LLM7Client$methods(
    analyze_plot = function(image_path, question, model = NULL, detail = NULL) {
      "Analyze a plot image and answer questions about it"
      
      # Use config defaults if not specified
      if (is.null(model)) model <- .self$config$models$vision
      if (is.null(detail)) detail <- .self$config$vision$detail
      
      # Read and encode image
      if (!file.exists(image_path)) {
        stop(sprintf("Image file not found: %s", image_path))
      }
      
      image_data <- readBin(image_path, "raw", file.info(image_path)$size)
      image_base64 <- base64enc::base64encode(image_data)
      
      # Detect image type
      ext <- tolower(tools::file_ext(image_path))
      
      # Check if format is supported
      supported_formats <- .self$config$vision$supported_formats
      if (!ext %in% supported_formats) {
        warning(sprintf(
          "Image format '%s' may not be supported. Supported formats: %s",
          ext, paste(supported_formats, collapse = ", ")
        ))
      }
      
      mime_type <- switch(ext,
        "png" = "image/png",
        "jpg" = "image/jpeg",
        "jpeg" = "image/jpeg",
        "gif" = "image/gif",
        "webp" = "image/webp",
        "image/png"  # default
      )
      
      # Create message with image
      messages <- list(
        list(
          role = "user",
          content = list(
            list(
              type = "text",
              text = question
            ),
            list(
              type = "image_url",
              image_url = list(
                url = sprintf("data:%s;base64,%s", mime_type, image_base64),
                detail = detail
              )
            )
          )
        )
      )
      
      # Log if debug enabled
      if (!is.null(.self$config$debug$verbose) && .self$config$debug$verbose) {
        cat("Analyzing image:", image_path, "\n")
        cat("Image size:", file.info(image_path)$size, "bytes\n")
      }
      
      # Get response
      response <- .self$chat_completion(
        model = model,
        messages = messages
      )
      
      # Extract content
      if (!is.null(response$choices) && length(response$choices) > 0) {
        return(response$choices[[1]]$message$content)
      } else {
        return(NULL)
      }
    },
    
    analyze_multiple_plots = function(image_paths, question, model = NULL, 
                                     detail = NULL) {
      "Analyze multiple plot images and answer questions about them"
      
      # Use config defaults if not specified
      if (is.null(model)) model <- .self$config$models$vision
      if (is.null(detail)) detail <- .self$config$vision$detail
      
      # Build content array
      content <- list(
        list(type = "text", text = question)
      )
      
      # Add each image
      for (path in image_paths) {
        if (!file.exists(path)) {
          warning(sprintf("Image file not found: %s (skipping)", path))
          next
        }
        
        image_data <- readBin(path, "raw", file.info(path)$size)
        image_base64 <- base64enc::base64encode(image_data)
        
        ext <- tolower(tools::file_ext(path))
        mime_type <- switch(ext,
          "png" = "image/png",
          "jpg" = "image/jpeg",
          "jpeg" = "image/jpeg",
          "gif" = "image/gif",
          "webp" = "image/webp",
          "image/png"
        )
        
        content <- c(content, list(
          list(
            type = "image_url",
            image_url = list(
              url = sprintf("data:%s;base64,%s", mime_type, image_base64),
              detail = detail
            )
          )
        ))
      }
      
      # Log if debug enabled
      if (!is.null(.self$config$debug$verbose) && .self$config$debug$verbose) {
        cat("Analyzing", length(image_paths), "images\n")
      }
      
      # Create message
      messages <- list(
        list(role = "user", content = content)
      )
      
      # Get response
      response <- .self$chat_completion(
        model = model,
        messages = messages
      )
      
      # Extract content
      if (!is.null(response$choices) && length(response$choices) > 0) {
        return(response$choices[[1]]$message$content)
      } else {
        return(NULL)
      }
    }
  )
}

# Apply the methods when this file is sourced
vision_methods()
