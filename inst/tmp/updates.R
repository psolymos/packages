## package dependencies for reinstalling
pkglist <- c(
    ## creator, maintainer
    "mefa", "mefa4", "dclone", "dcmle", "detect", "sharx",
    "ResourceSelection", "PVAClone", "pbapply", "opticut", "intrval",
    ## "QPAD",
    ## author
    "vegan", "epiR", "plotrix", "adegenet",
    ## user
    "rgl", "mgcv", "scatterplot3d", "permute", "rjags", "ade4",
    "coda", "snow", "R2WinBUGS", "rlecuyer", "Formula", "maptools", "BRugs",
    "lme4", "R2OpenBUGS", "RODBC", "rgdal", "raster", "sp",
    "reshape", "simba", "labdsv", "Hmisc", "untb", "ggplot2",
    "ineq", "pscl", "rpart", "gbm", "glmnet", "knitr", "ellipse",
    "betareg", "pROC", "unmarked", "forecast", "labdsv", "untb",
    "devtools", "testthat", "akima", "rioja", "data.table", "partykit",
    "mvtnorm", "DEoptim",
    "DBI", "RSQLite", "jsonlite", "opencpu", "shiny", "rgeos")

(toInst <- setdiff(pkglist, rownames(installed.packages())))

if (length(toInst) > 0)
    install.packages(toInst, repos="http://cran.at.r-project.org/")

#if (.Platform$OS.type != "windows")
#    install.packages("Aspell", repos = "http://www.omegahat.org/R")

update.packages(repos="http://cran.at.r-project.org/", ask=FALSE)

## create CRAN submission email template

submit_cran_template <- function(path = ".") {
    news <- readLines(file.path(path, "NEWS.md"))
    i <- which(startsWith(news, "##"))[1L:2L]
    latest <- news[i[1L]:(i[2L]-1)]
    latest <- latest[-1]
    latest <- latest[latest != ""]
#    latest <- latest[startsWith(latest, "*")]
    descr <- read.dcf(file.path(path, "DESCRIPTION"))
    ver <- unname(descr[1L,"Version"])
    pkg <- unname(descr[1L,"Package"])
    maint <- unname(descr[1L,"Maintainer"])
    out <- c(
        "Dear CRAN Maintainers,\n\n",
        "This is an update (version ", ver, ") of the ",
        pkg, " R extension package.\n\n",
        "The package includes the following changes:\n\n",
        paste(latest, collapse="\n"),
        "\n\nThe package tarball passed R CMD check --as-cran ",
        "without error/warning/note on Mac (current R), ",
        "Linux (old, current, devel), and Windows (current, devel R).\n\n",
        "Best wishes,\n\n",
        maint, "\npackage maintainer")
    out
}

cat(submit_cran_template("~/repos/mefa4"), sep="")
cat(submit_cran_template("~/repos/dclone"), sep="")
cat(submit_cran_template("~/repos/ResourceSelection"), sep="")

## spelling
library(spelling)
library(hunspell)
check_spelling <- function(x)
    sort(unique(unlist(hunspell(readLines(x), format = "html"))))

spell_check_package("~/repos/dcmle")

check_spelling("~/repos/dcmle/README.md")
check_spelling("~/repos/dcmle/NEWS.md")

library("ggplot2")
library("dlstats")
pkg <- c("mefa", "mefa4", "dclone", "dcmle", "detect", "sharx",
    "ResourceSelection", "PVAClone", "pbapply", "opticut", "intrval",
    "vegan", "epiR", "plotrix", "adegenet")
x <- cran_stats(pkg)

ggplot(x[x$start < max(x$start),], aes(end, downloads)) +
    geom_line() + facet_wrap(~package, scales="free_y")

pkg <- "pbapply"
x <- cran_stats(pkg)
rd <- devtools::revdep(pkg)
ggplot(x[x$start < max(x$start),], aes(end, downloads)) +
    geom_line() + geom_smooth() +
    labs(title=paste0(pkg, " (", length(rd), " revdeps)"))

# from https://drdoane.com/clean-consistent-column-names/
clean_names <- function(.data, unique = FALSE) {
  n <- if (is.data.frame(.data)) colnames(.data) else .data

  n <- gsub("%+", "_pct_", n)
  n <- gsub("\\$+", "_dollars_", n)
  n <- gsub("\\++", "_plus_", n)
  n <- gsub("-+", "_minus_", n)
  n <- gsub("\\*+", "_star_", n)
  n <- gsub("#+", "_cnt_", n)
  n <- gsub("&+", "_and_", n)
  n <- gsub("@+", "_at_", n)

  n <- gsub("[^a-zA-Z0-9_]+", "_", n)
  n <- gsub("([A-Z][a-z])", "_\\1", n)
  n <- tolower(trimws(n))

  n <- gsub("(^_+|_+$)", "", n)

  n <- gsub("_+", "_", n)

  if (unique) n <- make.unique(n, sep = "_")

  if (is.data.frame(.data)) {
    colnames(.data) <- n
    .data
  } else {
    n
  }
}

## inspact revdep distribution of all CRAN packages

library(pbapply)
library(parallel)

pkgs <- available.packages("https://cran.rstudio.com/src/contrib/")

cl <- makeCluster(4)
nrd <- pbsapply(rownames(pkgs), function(pkg) length(devtools::revdep(pkg)), cl=cl)
stopCluster(cl)


load("~/Dropbox/Public/revdep-2019-08-30.RData")
x <- x[order(x$nrevdep, decreasing = TRUE),]
x$q <- 100 * rank(x$nrevdep) / nrow(x)

z <- c("mefa", "mefa4", "dclone", "dcmle", "detect", "sharx",
    "ResourceSelection", "PVAClone", "pbapply", "opticut", "intrval",
    ## "QPAD",
    ## author
    "vegan", "epiR", "plotrix", "adegenet")
x[rownames(x) %in% z,]

