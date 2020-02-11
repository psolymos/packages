#!/bin/sh

set -ev

#Rscript -e "install.packages(c('dlstats', 'jsonlite', 'devtools'), repos='https://cran.rstudio.com')"
Rscript update.R
