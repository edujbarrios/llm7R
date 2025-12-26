# llm7R 

***Use powerful Large Language Models (LLMs) directly in your R workflows for data analysis, visualization, and exploratory research.***

`llm7R` is a lightweight and extensible R wrapper for the **LLM7.io API**, designed to make it easy to work with text generation, dataframe analysis, and vision-based understanding of plots and images — all from within R.

---

## Installation

### Install it directly in R

```r
# Install devtools if not already installed
install.packages("devtools")

# Install llm7r
devtools::install_github("edujbarrios/llm7r")
```

### Cloning it

```r
git clone https://github.com/edujbarrios/llm7R.git
cd llm7R
Rscript -e 'source("llm7.R")'
```

## Quick Start
```r
source("llm7.R")
client <- create_llm7_client()
````
---

## Usage Examples

### Text completion
```r
client$simple_completion(
  "Explain gradient descent in simple terms"
)
```

### Dataframe analysis
```r
data(iris)

client$analyze_dataframe(
  iris,
  "What are the key differences between species?"
)
```

### Plot / vision analysis
```r
png("plot.png")
plot(iris$Sepal.Length, iris$Petal.Length)
dev.off()

client$analyze_plot(
  "plot.png",
  "Describe the relationship shown in this plot"
)
```
---

## Recommended Environment

For the best experience while working with dataframes, plots, and long responses, it is recommended to use **Jupyter Notebook with the R kernel (IRkernel)**. This setup provides improved output rendering and interactive workflows.

---

## Authentication

By default, the client uses a limited-access API key:
```txt
api_key = "unused"
````
To unlock full functionality, generate an API token at:
```txt
https://token.llm7.io/
```
Then initialize the client with your token:
```r
client <- create_llm7_client(
  api_key = "your-token"
)
````

---

## Acknowledgements

Special thanks to **Chigwell** for creating and maintaining the LLM7.io API.

---

## Author

Eduardo J. Barrios  
https://edujbarrios.com
