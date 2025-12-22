# Example: Data Analysis with LLM7.IO R Wrapper
# ===============================================
# This script demonstrates how to analyze data and plots using the LLM7 wrapper

# Load the wrapper (works when sourced from project root)
if (file.exists("llm7.R")) {
  source("llm7.R")
} else if (file.exists("../llm7.R")) {
  source("../llm7.R")
} else {
  stop("Cannot find llm7.R. Please run from project root directory.")
}

# Required packages (install if needed)
# install.packages(c("httr", "jsonlite", "base64enc", "ggplot2"))

library(ggplot2)

# Create a client
client <- create_llm7_client()

# ===========================
# Example 1: Analyze a Dataframe
# ===========================
cat("Example 1: Analyzing a Dataframe\n")
cat("=================================\n\n")

# Load the famous iris dataset
data(iris)

cat("Dataset: Iris (first 10 rows)\n")
print(head(iris, 10))
cat("\n")

# Ask questions about the data
tryCatch({
  # Question 1: Species differences
  cat("Question: What are the key differences between the three iris species?\n")
  response1 <- client$analyze_dataframe(
    df = iris,
    question = "What are the key differences between the three iris species (setosa, versicolor, virginica) in terms of their measurements?"
  )
  cat("Answer:", response1, "\n\n")
  
  # Question 2: Correlations
  cat("Question: Which features are most correlated?\n")
  response2 <- client$analyze_dataframe(
    df = iris,
    question = "Which features (Sepal.Length, Sepal.Width, Petal.Length, Petal.Width) are most strongly correlated?"
  )
  cat("Answer:", response2, "\n\n")
  
}, error = function(e) {
  cat("Error:", conditionMessage(e), "\n\n")
})

# ===========================
# Example 2: Create and Analyze a Single Plot
# ===========================
cat("\nExample 2: Analyzing a Single Plot\n")
cat("===================================\n\n")

# Create a scatter plot of iris data
plot_file <- "iris_scatter.png"
png(plot_file, width = 800, height = 600)
ggplot(iris, aes(x = Sepal.Length, y = Petal.Length, color = Species)) +
  geom_point(size = 3, alpha = 0.7) +
  scale_color_manual(values = c("setosa" = "#2E86AB", "versicolor" = "#A23B72", "virginica" = "#F18F01")) +
  labs(
    title = "Iris Dataset: Sepal vs Petal Length",
    x = "Sepal Length (cm)",
    y = "Petal Length (cm)",
    color = "Species"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(hjust = 0.5, size = 16, face = "bold"),
    legend.position = "bottom"
  )
dev.off()

cat("Plot saved to:", plot_file, "\n\n")

# Analyze the plot
tryCatch({
  cat("Question: What patterns do you observe in this chart?\n")
  response <- client$analyze_plot(
    image_path = plot_file,
    question = "Analyze this scatter plot of iris flowers. What patterns do you see? Can you identify which species are most easily distinguishable?"
  )
  cat("Answer:", response, "\n\n")
}, error = function(e) {
  cat("Error:", conditionMessage(e), "\n\n")
})

# ===========================
# Example 3: Create and Analyze Multiple Plots
# ===========================
cat("\nExample 3: Analyzing Multiple Plots\n")
cat("====================================\n\n")

# Create first plot - Sepal dimensions
plot1_file <- "iris_sepal.png"
png(plot1_file, width = 600, height = 400)
ggplot(iris, aes(x = Sepal.Length, y = Sepal.Width, color = Species)) +
  geom_point(size = 3, alpha = 0.7) +
  scale_color_manual(values = c("setosa" = "#2E86AB", "versicolor" = "#A23B72", "virginica" = "#F18F01")) +
  labs(title = "Sepal Dimensions", x = "Sepal Length (cm)", y = "Sepal Width (cm)") +
  theme_minimal() +
  theme(plot.title = element_text(hjust = 0.5, face = "bold"))
dev.off()

# Create second plot - Petal dimensions
plot2_file <- "iris_petal.png"
png(plot2_file, width = 600, height = 400)
ggplot(iris, aes(x = Petal.Length, y = Petal.Width, color = Species)) +
  geom_point(size = 3, alpha = 0.7) +
  scale_color_manual(values = c("setosa" = "#2E86AB", "versicolor" = "#A23B72", "virginica" = "#F18F01")) +
  labs(title = "Petal Dimensions", x = "Petal Length (cm)", y = "Petal Width (cm)") +
  theme_minimal() +
  theme(plot.title = element_text(hjust = 0.5, face = "bold"))
dev.off()

# Create third plot - Distribution comparison
plot3_file <- "iris_distribution.png"
png(plot3_file, width = 600, height = 400)
ggplot(iris, aes(x = Species, y = Petal.Length, fill = Species)) +
  geom_boxplot(alpha = 0.7) +
  scale_fill_manual(values = c("setosa" = "#2E86AB", "versicolor" = "#A23B72", "virginica" = "#F18F01")) +
  labs(title = "Petal Length Distribution by Species", x = "Species", y = "Petal Length (cm)") +
  theme_minimal() +
  theme(plot.title = element_text(hjust = 0.5, face = "bold"))
dev.off()

cat("Plots saved:\n")
cat("  -", plot1_file, "\n")
cat("  -", plot2_file, "\n")
cat("  -", plot3_file, "\n\n")

# Analyze all plots together
tryCatch({
  cat("Question: Compare these three charts and give me a complete analysis\n")
  response <- client$analyze_multiple_plots(
    image_paths = c(plot1_file, plot2_file, plot3_file),
    question = "These are three charts of the iris dataset showing: sepal dimensions, petal dimensions, and petal length distribution. Compare them and tell me which features best distinguish the species and why."
  )
  cat("Answer:", response, "\n\n")
}, error = function(e) {
  cat("Error:", conditionMessage(e), "\n\n")
})

# ===========================
# Example 4: Interactive Data Analysis with Built-in Dataset
# ===========================
cat("\nExample 4: Interactive Analysis - mtcars Dataset\n")
cat("=================================================\n\n")

# Load a built-in dataset
data(mtcars)
cat("Using mtcars dataset (", nrow(mtcars), "vehicles)\n\n")

# Function for interactive analysis
ask_about_data <- function(question) {
  cat(">> Question:", question, "\n")
  tryCatch({
    response <- client$analyze_dataframe(
      df = mtcars,
      question = question,
      max_rows = 5  # Only show 5 rows to avoid overloading
    )
    cat(">> Answer:", response, "\n\n")
  }, error = function(e) {
    cat(">> Error:", conditionMessage(e), "\n\n")
  })
}

# Ask multiple questions
ask_about_data("Which car has the best miles per gallon (mpg)?")
ask_about_data("Is there a correlation between weight (wt) and fuel consumption (mpg)?")
ask_about_data("What are the differences between cars with 4, 6, and 8 cylinders?")

# Create a plot of the data
mtcars_plot <- "mtcars_analysis.png"
png(mtcars_plot, width = 800, height = 600)
ggplot(mtcars, aes(x = wt, y = mpg, color = factor(cyl), size = hp)) +
  geom_point(alpha = 0.7) +
  geom_smooth(method = "lm", se = FALSE, linetype = "dashed") +
  scale_color_manual(
    values = c("4" = "#2E86AB", "6" = "#A23B72", "8" = "#F18F01"),
    name = "Cylinders"
  ) +
  labs(
    title = "Relationship between Weight and Fuel Consumption",
    x = "Weight (1000 lbs)",
    y = "Miles per Gallon (mpg)",
    size = "Horsepower (hp)"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(hjust = 0.5, size = 14, face = "bold"),
    legend.position = "right"
  )
dev.off()

cat("Plot saved to:", mtcars_plot, "\n\n")

# Analyze the visualization
tryCatch({
  cat(">> Question: What insights can you get from this chart?\n")
  response <- client$analyze_plot(
    image_path = mtcars_plot,
    question = "Analyze this chart showing the relationship between weight and fuel consumption. What conclusions can you draw about the efficiency of different engine types?"
  )
  cat(">> Answer:", response, "\n\n")
}, error = function(e) {
  cat(">> Error:", conditionMessage(e), "\n\n")
})

cat("\n=================================\n")
cat("Analysis complete!\n")
cat("=================================\n")
