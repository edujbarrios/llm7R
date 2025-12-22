# Data Analysis Module
# =====================
# Functions for analyzing dataframes with LLM assistance

#' Analyze dataframe method for LLM7Client
#' 
#' @description
#' Adds the analyze_dataframe method to LLM7Client
analyze_dataframe_method <- function() {
  LLM7Client$methods(
    analyze_dataframe = function(df, question, model = NULL, 
                                 include_summary = NULL, max_rows = NULL) {
      "Analyze a dataframe and answer questions about it"
      
      # Use config defaults if not specified
      if (is.null(model)) model <- .self$config$models$text
      if (is.null(include_summary)) {
        include_summary <- .self$config$data_analysis$include_summary
      }
      if (is.null(max_rows)) {
        max_rows <- .self$config$data_analysis$max_rows
      }
      
      # Create a context about the dataframe
      context_parts <- c()
      
      if (include_summary) {
        # Basic info
        context_parts <- c(context_parts, 
          sprintf("Dataset with %d rows and %d columns.", nrow(df), ncol(df)))
        
        # Column info
        col_info <- sapply(names(df), function(col) {
          sprintf("%s (%s)", col, class(df[[col]])[1])
        })
        context_parts <- c(context_parts,
          sprintf("\nColumns: %s", paste(col_info, collapse = ", ")))
        
        # Summary statistics for numeric columns
        numeric_cols <- names(df)[sapply(df, is.numeric)]
        if (length(numeric_cols) > 0) {
          context_parts <- c(context_parts, "\n\nNumeric column statistics:")
          for (col in numeric_cols) {
            stats <- sprintf("%s: min=%.2f, max=%.2f, mean=%.2f, median=%.2f",
                           col, min(df[[col]], na.rm = TRUE), 
                           max(df[[col]], na.rm = TRUE),
                           mean(df[[col]], na.rm = TRUE),
                           median(df[[col]], na.rm = TRUE))
            context_parts <- c(context_parts, stats)
          }
        }
      }
      
      # Include sample rows
      if (max_rows > 0) {
        sample_rows <- head(df, max_rows)
        csv_text <- paste(capture.output(write.csv(sample_rows, row.names = FALSE)), 
                         collapse = "\n")
        context_parts <- c(context_parts, 
          sprintf("\n\nFirst %d rows (CSV format):\n%s", 
                  min(max_rows, nrow(df)), csv_text))
      }
      
      # Combine context
      full_context <- paste(context_parts, collapse = "\n")
      
      # Create prompt
      full_prompt <- sprintf(
        "I have the following dataset:\n\n%s\n\nQuestion: %s",
        full_context, question
      )
      
      # Get response
      return(.self$simple_completion(
        prompt = full_prompt,
        model = model
      ))
    }
  )
}

# Apply the method when this file is sourced
analyze_dataframe_method()
