library(jsonlite)
library(ggplot2)

get_stats <- function (packages, drop_last_month=TRUE) {
    pkgs <- paste(packages, sep = ",", collapse = ",")
    start <- as.Date("2012-01-01")
    end <- Sys.Date()
    all_months <- seq(start, end, by = "month")
    N <- length(all_months)
    urls <- sapply(seq_along(all_months), function(i) {
        mstart <- all_months[i]
        if (i == N) {
            mend <- end
        }
        else {
            mend <- all_months[i + 1] - 1
        }
        paste0("https://cranlogs.r-pkg.org/downloads/total/",
            mstart, ":", mend, "/", pkgs)
    })
    stats <- lapply(urls, function(url) {
        fromJSON(suppressWarnings(readLines(url)))
    })
    stats <- do.call("rbind", stats)
    res <- stats[stats$downloads != 0, ]
    res$package <- factor(res$package, levels = packages)
    res$start <- as.Date(res$start)
    res$end <- as.Date(res$end)
    res <- res[order(res$package, res$start), ]
    if (drop_last_month)
        res <- res[res$start < max(res$start),]
    res
}

pkgs <- c("shiny",
  "shinydashboard",
  "shinydashboardPlus",
  "shinyMobile",
  "flexdashboard",
  "argonDash",
  "shinymaterial",
  "dashboardthemes",
  "semantic.dashboard")
dl <- get_stats(pkgs)

p <- pkgs[1]

u <- do.call(rbind, lapply(pkgs, function(p) {
    d <- dl[dl$package==p,]
    data.frame(package=p,
               start=d$start[1],
               total=sum(d$downloads),
               lastyear=sum(tail(d$downloads, 12)))
}))
u <- u[order(u$lastyear, decreasing = TRUE),]
u$relative <- u$lastyear/u$lastyear[1]
u

ggplot(dl, aes(x=start, y=downloads)) +
    geom_line() + geom_smooth() +
    labs(title=p) + ylab("Monthly downloads") + xlab("") +
    theme_minimal() +
    facet_wrap(vars(package), scales="free_y")

