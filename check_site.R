#!/usr/bin/env r

renv::restore(repos = "https://packagemanager.rstudio.com/all/__linux__/focal/latest")
# install.packages("devtools")
install.packages(".", repos = NULL, type = "source")
rmarkdown::render_site(input = "site")