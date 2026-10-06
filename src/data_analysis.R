# Data Analysis Module
# ====================
# Functions for analyzing data frames with LLM assistance.

.safe_numeric_summary <- function(x) {
  values <- x[!is.na(x)]
  if (length(values) == 0) return("all values are missing")

  sprintf(
    "min=%.2f, max=%.2f, mean=%.2f, median=%.2f",
    min(values), max(values), mean(values), median(values)
  )
}

analyze_dataframe_method <- function() {
  LLM7Client$methods(
    analyze_dataframe = function(df, question, model = NULL,
                                 include_summary = NULL, max_rows = NULL,
                                 max_columns = NULL) {
      "Analyze a data frame and answer a question about it"

      if (!is.data.frame(df)) stop("df must be a data.frame")
      if (is.null(model)) model <- .self$config$models$text
      if (is.null(include_summary)) include_summary <- .self$config$data_analysis$include_summary
      if (is.null(max_rows)) max_rows <- .self$config$data_analysis$max_rows
      if (is.null(max_columns)) max_columns <- .self$config$data_analysis$max_columns

      if (max_columns < 1) stop("max_columns must be at least 1")
      selected_names <- head(names(df), max_columns)
      df_context <- df[selected_names]

      context_parts <- character()
      if (isTRUE(include_summary)) {
        context_parts <- c(
          context_parts,
          sprintf("Dataset with %d rows and %d columns.", nrow(df), ncol(df))
        )

        if (length(selected_names) < ncol(df)) {
          context_parts <- c(
            context_parts,
            sprintf(
              "Showing the first %d columns for context; %d columns were omitted.",
              length(selected_names), ncol(df) - length(selected_names)
            )
          )
        }

        col_info <- vapply(selected_names, function(col) {
          sprintf("%s (%s)", col, class(df_context[[col]])[1])
        }, character(1))
        context_parts <- c(context_parts, sprintf("Columns: %s", paste(col_info, collapse = ", ")))

        numeric_cols <- selected_names[vapply(df_context, is.numeric, logical(1))]
        if (length(numeric_cols) > 0) {
          stats <- vapply(numeric_cols, function(col) {
            sprintf("%s: %s", col, .safe_numeric_summary(df_context[[col]]))
          }, character(1))
          context_parts <- c(context_parts, "Numeric column statistics:", stats)
        }
      }

      if (max_rows > 0) {
        sample_rows <- head(df_context, max_rows)
        csv_text <- paste(
          capture.output(write.csv(sample_rows, row.names = FALSE, na = "NA")),
          collapse = "\n"
        )
        context_parts <- c(
          context_parts,
          sprintf(
            "First %d rows (CSV format):\n%s",
            min(max_rows, nrow(df_context)), csv_text
          )
        )
      }

      full_prompt <- sprintf(
        "I have the following dataset context:\n\n%s\n\nQuestion: %s",
        paste(context_parts, collapse = "\n\n"),
        question
      )

      .self$simple_completion(prompt = full_prompt, model = model)
    }
  )
}

analyze_dataframe_method()
