#!/usr/bin/env bash
set -e

cd /covidpub
git checkout tmp
Rscript check_site.R
python3 -m http.server --directory dist 8000