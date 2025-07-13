# Use R-universe for package checks
library(jsonlite)
pkgnews <- function(x) {
    x <- x[x != ""]
    h <- which(startsWith(x, "#"))
    i <- (h[1]+1):(h[2]-1)
    paste0(x[i], collapse="\n")
}

pkg <- "mefa4"

api_url <- paste0("https://psolymos.r-universe.dev/api/packages/", pkg)
j <- fromJSON(api_url)
checks <- j[["_jobs"]]
platforms <- checks$config[!startsWith(checks$config, "wasm")]
news_text <- readLines(gsub("README", "NEWS", j[["_readme"]]))

cat(sprintf('Dear CRAN Maintainers,

I am submitting the %s version of the %s R extension package to CRAN.

The package passed R CMD check --as-cran without errors/warnings/notes on the following platforms: %s.

I made the following changes since the last release:

%s

Yours,

Peter Solymos
maintainer',
j$Version,
pkg,
paste0(platforms, collapse=", "),
pkgnews(news_text)))

checks
