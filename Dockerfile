FROM rocker/r-ver:4.2.0 
LABEL maintainer="camille"
ENV BRANCH=tmp
ENV PORT=8000
RUN export DEBIAN_FRONTEND=noninteractive; apt-get update -qq \
	&& apt-get -y install git

# ARG RENV_CACHE="/renv/cache"

RUN install2.r remotes renv \
	&& /rocker_scripts/install_pandoc.sh

# not cloning repo in build bc want to expect branches to change

COPY entrypoint.sh entrypoint.sh

# RUN R -e 'devtools::install(pkg = ".", build = TRUE, upgrade = FALSE)'
ENTRYPOINT [ "./entrypoint.sh" ]