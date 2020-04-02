#!/usr/bin/env Rscript

library(jsonlite)
library(devtools)

today <- Sys.Date()

## package list of interest
pkgs <- c(
    ## creator, maintainer
    "mefa", "mefa4", "dclone", "dcmle", "detect",
    "sharx", "ResourceSelection", "PVAClone", "pbapply", "opticut",
    "intrval", "bSims",
    ## author
    "vegan", "epiR", "plotrix", "adegenet")
## download stats
# after dlstats::cran_stats BUT without caching
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
dl <- get_stats(pkgs)
## reverse dependencies
rd <- lapply(pkgs, revdep)
names(rd) <- pkgs

Format <- function(pkg) {
    list(
        name=pkg,
        date=dl$start[dl$package==pkg],
        dowloads=dl$downloads[dl$package==pkg],
        revdep=rd[[pkg]],
        nrd=length(rd[[pkg]])
    )
}
List <- lapply(pkgs, Format)

dir.create("_stats")
writeLines(toJSON(rd), paste0("_stats/revdeps_",
    substr(as.character(today), 1, 7), ".json"))
writeLines(toJSON(List), paste0("_stats/stats_latest.json"))

