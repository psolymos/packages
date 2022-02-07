#!/usr/bin/env Rscript

library(jsonlite)
library(ggplot2)
library(magick)

baseurl <- "https://peter.solymos.org/packages"
today <- Sys.Date()

dl <- fromJSON(paste0(baseurl, "/stats_latest.json"))

d0 <- "2020-02"
d1 <- substr(as.character(today), 1, 7)
dd <- d0
done <- FALSE
while (!done) {
  dlast <- dd[length(dd)]
  ylast <- as.integer(substr(dlast, 1, 4))
  mlast <- as.integer(substr(dlast, 6, 7))
  mnext <- if (mlast == 12) 1 else mlast+1L
  ynext <- if (mlast == 12) ylast+1L else ylast
  mnext <- as.character(mnext)
  if (nchar(mnext) < 2)
    mnext <- paste0("0", mnext)
  dnext <- paste0(as.character(ynext), "-", mnext)
  #cat(dnext, "\n")
  dd <- c(dd, dnext)
  if (dnext == d1)
    done <- TRUE
}

fl <- paste0(baseurl, "/revdeps_", dd, ".json")
rdlist <- lapply(fl, fromJSON)
names(rdlist) <- dd

nam <- unlist(dl$name)
m <- matrix(0, length(dd), length(nam))
dimnames(m) <- list(dd, nam)
for (i in dd) {
  for (j in nam) {
    m[i,j] <- length(rdlist[[i]][[j]])
  }
}
dd <- paste0(dd, "-01")

RD <- list()
DL <- list()
for (i in nam) {
  DL[[i]] <- data.frame(
    x=as.Date(dl$date[[which(nam == i)]]),
    y=dl$dowloads[[which(nam == i)]])
  RD[[i]] <- if (i == "pbapply") {
    data.frame(
      x=as.Date(c("2016-09-01", "2017-10-01", "2019-07-01",
        "2019-08-01", "2019-09-01", "2019-10-01", "2019-11-01",
        "2019-12-01", "2020-01-01", dd)),
      y=c(20, 47, 96, 98, 102, 105, 106, 109, 112, m[,i]))
  } else {
    data.frame(x=as.Date(dd), y=m[,i])
  }
}

if (!dir.exists("images"))
  dir.create("images")
for (i in nam) {
  p <- ggplot(DL[[i]], aes(x, y)) +
    geom_line() + geom_smooth() +
    labs(title=i) + ylab("Monthly downloads") + xlab("")
  q <- ggplot(RD[[i]], aes(x, y)) +
    geom_line() + geom_point() +
    labs(title="") + ylab("Reverse dependencies") + xlab("")
  ggsave(paste0("images/", i, "-downloads.png"), p)
  ggsave(paste0("images/", i, "-revdeps.png"), q)
  img <- c(image_read(paste0("images/", i, "-downloads.png")),
    image_read(paste0("images/", i, "-revdeps.png")))
  out <- image_append(img)
  image_write(out, path = paste0("images/", i, ".png"), format = "png")
  unlink(paste0("images/", i, "-downloads.png"))
  unlink(paste0("images/", i, "-revdeps.png"))
}



x <- jsonlite::fromJSON("https://raw.githubusercontent.com/psolymos/packages/gh-pages/stats_latest.json")
sum(unlist(lapply(x$downloads$count, sum)))/10^6
