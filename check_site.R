#!/usr/bin/env r

renv::restore()
install.packages("devtools")
devtools::install(pkg = ".", build = TRUE, upgrade = FALSE)
rmarkdown::render_site(input = "site")