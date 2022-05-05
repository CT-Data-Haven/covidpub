<!-- badges: start -->
![Latest data badge](https://img.shields.io/endpoint?url=https://gist.githubusercontent.com/ct-data-haven/418c1b0228bd7ac4f5b835fd54249a73/raw/latest_covid_data.json)
![GitHub Workflow Status: update-data-pr](https://img.shields.io/github/workflow/status/ct-data-haven/covidpub/update-data-pr?label=update-data-pr&style=flat-square)
![GitHub Workflow Status: site-build](https://img.shields.io/github/workflow/status/ct-data-haven/covidpub/site-build?label=site-build&style=flat-square)
![GitHub pull requests by-label: update-data](https://img.shields.io/github/issues-pr-raw/ct-data-haven/covidpub/update-data?color=yellow)
<!-- badges: end -->

# covidpub

Code for DataHaven's site on COVID-19 data, embedded at https://ctdatahaven.org/reports/covid-19-connecticut-data-analysis.

This is built as a simple RMarkdown site, with the { `billboarder` } package for charts and Bootstrap for styling. This repo itself is a very small, undocumented R package.

New data (CSV files) go in the [./input_data](./input_data) folder and are automatically updated once a week. Updates and site builds are done with GitHub actions.

## Development & data checking

### { `covidbuild` }

Six CSV files for the site are created in the repo { `covidbuild` } (private, ask Camille if you need access). Those files are calculations of data from the state's data portal and are ready to use on the site. The update action is set to run under one of three conditions:

* Every Tuesday, using a cron job
* A manual workflow trigger
* A push to the repo's `main` branch

The action `update-data` runs scripts with `make`; if there are any changes to the CSV files written, they're pushed to back to the { `covidbuild` } repo, and then copied to the `input_data` folder of the { `covidpub` } repo's `update` branch.

### { `covidpub` }

Whenever there's a push to this repo's `update` branch (or manual trigger), the action `update-data-pr` runs, copying the CSV files to a temporary branch `tmp`. If any have changed, a commit is pushed to `tmp`, marked with the date of the latest statewide data (not necessarily the date on which the action was last run), and a pull request is filed to merge that data back onto `main`; once there, that data will be used to populate the site. (As of right now, the action throws an error and is marked as failing if there are no changes; I'm working on it.) The pull request should (hopefully) list the most recent date of statewide data and the files that were changed, so you have some sense of what charts & tables to take a look at.

**This is where we need human intervention**—I don't want to set up any automatic merging, because we should still have a set of eyes to check that nothing weird has happened with the data before it goes live. The state's data portal is pretty stable now, but this project predates the state having anything public-facing beyond daily PDF tables.

The site can be built easily from source: clone this repo and run 

```r
rmarkdown::render_site(input = "site")
```

That builds the HTML. Because it relies on Javascript to render charts, you'll need a local http server running. Either start a server from within a folder than can access the built site files (`/covidpub/dist`; I usually use `http-server` on the command line, but the { `pkgdown` } package also has a function to serve a site locally), or use the Docker image I built for this purpose (the bonus here is not having to worry about dependencies on your computer). With Docker running and in this directory, run:

```bash
# build the image
docker build -t covidsite .

# run the container
docker run --rm -it -p 8000:8000 covidsite
```

This will: 

* Clone the repo
* Restore all the necessary R packages in their correct versions (uses { `renv` })
* Install the package from source
* Build the site
* Run a Python http server on the port 8000 (on the container) mapped to the port 8000 (on your computer)

All you have to do is go to `localhost:8000` in a browser (or depending on your terminal, click the link that the server prints), check that everything looks good, stop the container, and merge the pull request on GitHub. That will trigger the site to rebuild with the new data. 