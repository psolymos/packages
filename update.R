#!/usr/bin/env Rscript

cat(">>> Updating download and revdep stats <<<\n\n")
cat("* Loading libraries ... ")
suppressPackageStartupMessages(library(jsonlite))
suppressPackageStartupMessages(library(devtools))

unlink("docs", recursive = TRUE)
dir.create("docs")
file.copy("www/index.html", "docs/index.html")
dir.create("docs/assets")
file.copy("www/assets", "docs", recursive = TRUE)

cat("OK\n* Defining functions and variables ... ")
today <- as.POSIXct(Sys.Date(), tz="America/Edmonton")
Today <- substr(as.character(today), 1, 10)
Dates <- sort(unique(
    c(fromJSON("https://peter.solymos.org/packages/dates.json"),
    Today)))
## package list of interest
dat <- list(
    "rconfig"=list(org="analythium", date1="2021-02-21"),
    "mefa"=list(org="psolymos", date1="2007-12-07"),
    "dclone"=list(org="datacloning", date1="2009-11-05"),
    "pbapply"=list(org="psolymos", date1="2010-09-03"),
    "sharx"=list(org="psolymos", date1="2010-12-09"),
    "mefa4"=list(org="psolymos", date1="2011-02-10"),
    "ResourceSelection"=list(org="psolymos", date1="2011-06-04"),
    "detect"=list(org="psolymos", date1="2011-09-29"),
    "dcmle"=list(org="datacloning", date1="2011-09-29"),
    "PVAClone"=list(org="datacloning", date1="2012-07-27"),
    "intrval"=list(org="psolymos", date1="2016-12-06"),
    "opticut"=list(org="psolymos", date1="2016-12-17"),
    "bSims"=list(org="psolymos", date1="2019-12-20"),
    "vegan"=list(org="vegandevs", date1="2001-09-06"))
pkgs <- names(dat)
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

cat("OK\n* Getting stats ... ")
dl <- get_stats(pkgs)
## reverse dependencies
rd <- lapply(pkgs, revdep)
names(rd) <- pkgs

Rds <- list()
for (i in Dates[Dates != Today]) {
    download.file(
        paste0("https://peter.solymos.org/packages/revdeps_", i, ".json"),
        paste0("docs/revdeps_", i, ".json"))
    Rds[[i]] <- fromJSON(
        paste0("https://peter.solymos.org/packages/revdeps_", i, ".json"))
}
Rds[[Today]] <- rd

Format <- function(pkg) {
    revs <- list(
        date=Dates,
        count=unname(sapply(Rds, function(z) length(z[[pkg]]))))
    if (pkg == "pbapply") {
        revs$date <- c("2016-09-01", "2017-10-01", "2019-07-01",
            "2019-08-01", "2019-09-01", "2019-10-01", "2019-11-01",
            "2019-12-01", "2020-01-01", revs$date)
        revs$count <- c(20, 47, 96, 98, 102, 105, 106, 109, 112, revs$count)
    }
    revs$date <- c(dat[[pkg]]$date1, revs$date)
    revs$count <- c(0, revs$count)
    list(
        name=pkg,
        organization=dat[[pkg]]$org,
        firstpublish=dat[[pkg]]$date1,
        downloads=list(
            date=dl$start[dl$package==pkg],
            count=dl$downloads[dl$package==pkg]),
        revdeps=revs,
        revdeplist=rd[[pkg]],
        nrevdep=length(rd[[pkg]])
    )
}
List <- lapply(pkgs, Format)

cat("OK\n* Summaries:")
summary(as.Date(Dates))
tmp <- t(sapply(List, function(z)
    as.character(range(z$downloads$date))))
dimnames(tmp) <- list(pkgs, c("Min", "Max"))
data.frame(tmp, n=sapply(List, function(z) length(z$downloads$date)))

cat("\n* Writing results ... ")
writeLines(toJSON(Dates), paste0("docs/dates.json"))
writeLines(toJSON(rd), paste0("docs/revdeps_", Today, ".json"))
writeLines(toJSON(List, auto_unbox=TRUE), paste0("docs/stats_latest.json"))
cat("OK\n\nDONE\n\n")

