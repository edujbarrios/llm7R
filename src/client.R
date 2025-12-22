# LLM7 Client Core
# ==================
# Core client functionality for LLM7.IO API

library(httr)
library(jsonlite)

#' LLM7 Client Class
#' 
#' @description
#' A client for interacting with the LLM7.IO API
#' 
#' @field api_key The API key for authentication
#' @field base_url The base URL for the API
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
      
      # Load config if provided, otherwise use global config
      if (is.null(config)) {
        if (exists("LLM7_CONFIG", envir = .GlobalEnv)) {
          .self$config <- get("LLM7_CONFIG", envir = .GlobalEnv)
        } else {
          .self$config <- list(
            base_url = "https://api.llm7.io/v1",
            api_key = "unused",
            generation = list(temperature = 0.7)
          )
        }
      } else {
        .self$config <- config
      }
      
      # Set API key and base URL
      .self$api_key <- if (!is.null(api_key)) api_key else .self$config$api_key
      .self$base_url <- if (!is.null(base_url)) base_url else .self$config$base_url
    },
    
    chat_completion = function(model = NULL, messages, temperature = NULL, 
                              max_tokens = NULL, stream = NULL) {
      "Send a chat completion request"
      
      # Use config defaults if not specified
      if (is.null(model)) model <- .self$config$models$text
      if (is.null(temperature)) temperature <- .self$config$generation$temperature
      if (is.null(stream)) stream <- .self$config$generation$stream
      
      # Construct the endpoint
      endpoint <- paste0(.self$base_url, "/chat/completions")
      
      # Prepare the request body
      body <- list(
        model = model,
        messages = messages,
        temperature = temperature
      )
      
      if (!is.null(max_tokens)) {
        body$max_tokens <- max_tokens
      }
      
      if (stream) {
        body$stream <- TRUE
      }
      
      # Log request if debug enabled
      if (!is.null(.self$config$debug$verbose) && .self$config$debug$verbose) {
        cat("Request to:", endpoint, "\n")
        cat("Model:", model, "\n")
      }
      
      # Make the request
      response <- POST(
        endpoint,
        add_headers(
          "Authorization" = paste("Bearer", .self$api_key),
          "Content-Type" = "application/json"
        ),
        body = toJSON(body, auto_unbox = TRUE),
        encode = "raw"
      )
      
      # Check for errors
      if (http_error(response)) {
        stop(sprintf(
          "API request failed with status %s: %s",
          status_code(response),
          content(response, "text", encoding = "UTF-8")
        ))
      }
      
      # Parse and return the response
      result <- content(response, "parsed", encoding = "UTF-8")
      
      # Log response if debug enabled
      if (!is.null(.self$config$debug$verbose) && .self$config$debug$verbose) {
        cat("Response received successfully\n")
      }
      
      return(result)
    },
    
    simple_completion = function(prompt, model = NULL, temperature = NULL, 
                                max_tokens = NULL) {
      "Send a simple text completion request"
      
      messages <- list(
        list(role = "user", content = prompt)
      )
      
      response <- .self$chat_completion(
        model = model,
        messages = messages,
        temperature = temperature,
        max_tokens = max_tokens
      )
      
      # Extract the message content
      if (!is.null(response$choices) && length(response$choices) > 0) {
        return(response$choices[[1]]$message$content)
      } else {
        return(NULL)
      }
    },
    
    list_models = function() {
      "List available models"
      
      endpoint <- paste0(.self$base_url, "/models")
      
      response <- GET(
        endpoint,
        add_headers(
          "Authorization" = paste("Bearer", .self$api_key)
        )
      )
      
      if (http_error(response)) {
        stop(sprintf(
          "API request failed with status %s: %s",
          status_code(response),
          content(response, "text", encoding = "UTF-8")
        ))
      }
      
      result <- content(response, "parsed", encoding = "UTF-8")
      return(result)
    }
  )
)

#' Create a new LLM7 client
#' 
#' @param api_key API key for authentication (default: from config)
#' @param base_url Base URL for the API (default: from config)
#' @param config Configuration list (default: global LLM7_CONFIG)
#' 
#' @return A new LLM7Client object
#' @export
#' 
#' @examples
#' client <- create_llm7_client()
#' response <- client$simple_completion("Hello, how are you?")
create_llm7_client <- function(api_key = NULL, base_url = NULL, config = NULL) {
  return(LLM7Client$new(api_key = api_key, base_url = base_url, config = config))
}
