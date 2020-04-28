FROM bimberlab/oosap

ENV SCRATCH_DIR /scratch
ENV APP_DIR /srv/shiny-server

RUN apt-get update -y \
	&& apt-get install -y \
	  sudo gdebi-core pandoc pandoc-citeproc \
	  libcurl4-gnutls-dev libcairo2-dev libxt-dev \
	  xtail

RUN VERSION=$(curl https://download3.rstudio.org/ubuntu-14.04/x86_64/VERSION) \
	&& curl -O "https://download3.rstudio.org/ubuntu-14.04/x86_64/shiny-server-$VERSION-amd64.deb" \
	&& gdebi -n shiny-server-$VERSION-amd64.deb \
	&& rm -f shiny-server-$VERSION-amd64.deb \
	&& . /etc/environment \
	&& cp -R /usr/local/lib/R/site-library/shiny/examples/* $APP_DIR 

RUN rm -rf /etc/services.d/rstudio \
	&& mkdir -p /etc/services.d/shiny-server \
	&& echo '#!/usr/bin/with-contenv bash \
	  \n mkdir -p /var/log/shiny-server \
	  \n chown -R shiny:shiny /var/log/shiny-server /var/lib/shiny-server \
	  \n exec s6-setuidgid shiny /opt/shiny-server/bin/shiny-server 2>&1' \
	  > /etc/services.d/shiny-server/run

RUN sed 's,^DAEMON.*$,DAEMON=/opt/shiny-server/bin/shiny-server,' \
	/opt/shiny-server/config/init.d/debian/shiny-server \
	  > /etc/init.d/shiny-server \
	&& update-rc.d shiny-server defaults \
	&& update-rc.d rstudio-server disable

# Install dependencies & packages. Also create stub app.R in the expected location
RUN Rscript -e "devtools::install_github(repo = 'kolabx/geneSetVis@pkg', dependencies = T, upgrade = 'always')" \
	&& rm -rf /tmp/downloaded_packages/ /tmp/*.rds
RUN mkdir -p ${APP_DIR}/geneSetVis && echo 'shinyAppDir(appDir = system.file("app", package = "geneSetVis"))' > ${APP_DIR}/geneSetVis/app.R

#RUN Rscript -e "devtools::install_github(repo = 'bimberlabinternal/ShinySDA', dependencies = T, upgrade = 'always')"
#RUN mkdir -p ${APP_DIR}/ShinySDA && echo 'shinyAppDir(appDir = system.file("app", package = "ShinySDA"))' > ${APP_DIR}/ShinySDA/app.R

RUN sed -i '/run_as shiny;/a preserve_logs true;' /etc/shiny-server/shiny-server.conf \
	&& sed -i '/run_as shiny;/a app_init_timeout 3600;' /etc/shiny-server/shiny-server.conf \
	&& sed -i '/listen 3838;/a sanitize_errors false;' /etc/shiny-server/shiny-server.conf 

RUN rm ${APP_DIR}/index.html \
	&& rm -rf ${APP_DIR}/sample-apps

# select port
EXPOSE 3838
