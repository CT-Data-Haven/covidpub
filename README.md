<!-- badges: start -->
[![site-build](https://github.com/CT-Data-Haven/covidpub/workflows/site-build/badge.svg)](https://github.com/CT-Data-Haven/covidpub/actions)
<!-- badges: end -->

# covidpub

Code for DataHaven's site on COVID-19 data, embedded at https://ctdatahaven.org/reports/covid-19-connecticut-data-analysis.

This is built as a simple RMarkdown site, with the billboarder and leaflet packages for visuals.

New data goes in the [./input_data](./input_data) folder and is updated as close to ~~daily~~ weekly as possible. Build is done with github actions and rmarkdown.

To build:

``` r
remotes::install_github("ct-data-haven/covidpub")
rmarkdown::render_site(input = "site")
```