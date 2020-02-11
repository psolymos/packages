#!/usr/bin/env Rscript

library(dlstats)
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
dl <- cran_stats(pkgs)
dl <- dl[dl$start < max(dl$start),] # drop last month
## reverse dependencies
rd <- lapply(pkgs, revdep)
names(rd) <- pkgs

Format <- function(pkg) {
    list(
        name=pkg,
        date=dl$end[dl$package==pkg],
        dowloads=dl$downloads[dl$package==pkg],
        revdep=rd[[pkg]],
        nrd=length(rd[[pkg]])
    )
}
List <- lapply(pkgs, Format)

dir.create("_stats")
writeLines(toJSON(rd), paste0("_stats/revdeps_", today, ".json"))
writeLines(toJSON(List), paste0("_stats/stats_latest.json"))
