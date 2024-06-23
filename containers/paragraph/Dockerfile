FROM ubuntu:20.04

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get -qq update && apt-get install -yq \
	autoconf \
	automake \
	build-essential \
	cmake \
	git \
	libboost-all-dev \
	libfreetype6-dev \
	liblzma-dev \
	libpng-dev \
	libtool
	
RUN apt-get -qq update && apt-get install -yq \
	m4 \
	python3-pip \
	#software-properties-common \
	zlib1g-dev \
	libbz2-dev &&  \
	apt-get clean -y && \
	rm -rf /var/lib/apt/lists/*

RUN mkdir -p /opt/ \
	&& cd /opt \
	&& git clone https://github.com/Illumina/paragraph.git \
	&& mv paragraph paragraph-source \
	&& pip3 install -r /opt/paragraph-source/requirements.txt \
	&& mkdir /opt/paragraph-build

WORKDIR /opt/paragraph-build
RUN cmake /opt/paragraph-source -DCMAKE_INSTALL_PREFIX=/opt/paragraph && make && make install
RUN rm -rf /opt/paragraph-source

ENTRYPOINT ["/usr/bin/python3"]
CMD ["/opt/paragraph/bin/multigrmpy.py", "-h"]