FROM ubuntu:18.04

ENV DEBIAN_FRONTEND=noninteractive

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
	libtool \
	libboost-all-dev \
	m4 \
    python3-full \
    python3-pip \
	zlib1g-dev \
	libbz2-dev &&  \
	apt-get clean -y && \
    # This avoids the 'error: externally-managed-environment' issue
    rm -Rf /usr/lib/python3.12/EXTERNALLY-MANAGED \
	rm -Rf /var/lib/apt/lists/*

RUN mkdir -p /opt/ \
	&& cd /opt \
	&& git clone https://github.com/Illumina/paragraph.git \
	&& mv paragraph paragraph-source \
	&& pip3 install --user -r /opt/paragraph-source/requirements.txt \
	&& mkdir /opt/paragraph-build

WORKDIR /opt/paragraph-build
RUN cmake /opt/paragraph-source -DCMAKE_INSTALL_PREFIX=/opt/paragraph -DBoost_NO_BOOST_CMAKE=ON \
    && make \
	&& make install
RUN rm -rf /opt/paragraph-source

ENTRYPOINT ["/usr/bin/python3"]
CMD ["/opt/paragraph/bin/multigrmpy.py", "-h"]
