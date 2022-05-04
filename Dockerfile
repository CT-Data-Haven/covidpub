FROM rocker/r-ver:4.2.0 
LABEL maintainer="camille"
RUN export DEBIAN_FRONTEND=noninteractive; apt-get update -qq \
	&& apt-get -y install git

# ARG RENV_CACHE="/renv/cache"

RUN git clone https://github.com/CT-Data-Haven/covidpub.git \
	&& cd covidpub \
	&& git checkout tmp \
	&& touch .here

# in working on this these weren't on gh yet
COPY check_site.R covidpub/check_site.R
COPY Rprofile.site covidpub/Rprofile.site
COPY entrypoint.sh entrypoint.sh

RUN install2.r remotes renv \
	&& /rocker_scripts/install_pandoc.sh

# RUN R -e 'devtools::install(pkg = ".", build = TRUE, upgrade = FALSE)'
ENTRYPOINT [ "./entrypoint.sh" ]