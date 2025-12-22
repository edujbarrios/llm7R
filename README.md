# llm7R

R client for LLM7.io API. ***Use powerful LLMs in your R workflows and data analysis.***

## Install

```r
# From GitHub
devtools::install_github("edujbarrios/llm7r")

# Or clone and run
git clone https://github.com/edujbarrios/llm7r.git
cd llm7r && Rscript -e 'source("llm7.R")'
```

## Usage

> [!TIP]
> Use Jupyter with R kernel for best output experience while woerking with data and plots.

```r
source("llm7.R")
client <- create_llm7_client()

# Text
client$simple_completion("Explain gradient descent")

# Data
data(iris)
client$analyze_dataframe(iris, "Key differences between species?")

# Vision
png("plot.png"); plot(iris$Sepal.Length, iris$Petal.Length); dev.off()
client$analyze_plot("plot.png", "Describe this relationship")
```


## Examples

See `examples/` folder for more usage scenarios.

## Auth

Default: `api_key = "unused"` (limited)  
Get token: [token.llm7.io](https://token.llm7.io/)

```r
client <- create_llm7_client(api_key = "your-token")
```
---

Thanks to [Chigwell](https://github.com/chigwell) for creating such a great API!

---

This wrapper was created by **Eduardo J. Barrios** - [edujbarrios.com](https://edujbarrios.com)



