# https://github.com/lindbrook/packageRank#crandownloads
# http://cran-logs.rstudio.com/2026/2026-10-27.csv.gz

library(packageRank)
library(ggplot2)

pl <- c(
    "bSims",
    "dclone",
    "dcmle",
    "deps",
    "detect",
    "intrval",
    "mefa",
    "mefa4",
    "opticut",
    "pbapply",
    "PVAClone",
    "rconfig",
    "ResourceSelection",
    "sharx",
    "tryr",
    "vegan"
)

# RStudio CRAN logs begin on 2012-10-01
dfun <- function(date) {
    d <- try(cranDistribution(date = date), silent = TRUE)
    if (inherits(d, "try-error")) {
        date <- as.Date(date) - 1
        d <- try(cranDistribution(date = date), silent = TRUE)
        if (inherits(d, "try-error")) {
            date <- as.Date(date) + 2
            d <- try(cranDistribution(date = date), silent = TRUE)
            if (inherits(d, "try-error")) {
                stop(
                    "Failed to fetch CRAN distribution for date: ",
                    date,
                    call. = FALSE
                )
            }
        }
    }
    ds <- d$data[d$data$package %in% pl, ]
    ds$date <- d$date
    ds$n_unique_packages <- d$unique.packages
    return(ds)
}

dt <- seq(
    from = as.Date("2013-01-01"),
    to = as.Date("2026-10-01"),
    by = "month"
)
o <- NULL
for (i in as.character(dt2)) {
    message("Processing date: ", i)
    z <- try(dfun(date = i))
    if (!inherits(z, "try-error")) {
        o <- rbind(o, z)
    }
}

saveRDS(o, file = "cran_distribution_data.rds")

pkg <- "dclone"

o[o$package == pkg, ] |>
    ggplot(aes(x = date, y = percentile)) +
    geom_line() +
    geom_smooth() +
    theme_light()

o |>
    dplyr::filter(!duplicated(date)) |>
    ggplot(aes(x = date, y = n_unique_packages)) +
    geom_line() +
    geom_smooth(col = 1, se = FALSE) +
    geom_line(
        data = o[o$package == pkg, ],
        aes(y = n_unique_packages - rank, x = date),
        col = 2
    ) +
    geom_smooth(
        data = o[o$package == pkg, ],
        aes(y = n_unique_packages - rank, x = date),
        col = 2,
        se = FALSE
    ) +
    theme_light()
