#!/usr/bin/env bash
set -e

git clone https://github.com/CT-Data-Haven/covidpub.git
cd ./covidpub 
git checkout "$BRANCH"
touch .here 

Rscript check_site.R
python3 -m http.server --directory dist $PORT