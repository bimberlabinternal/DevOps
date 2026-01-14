FROM quay.io/comparative-genomics-toolkit/cactus:v3.1.2

# See: https://github.com/vgteam/vg/issues/4645
RUN apt-get update -y && \
    apt-get install -y --fix-missing build-essential && \
    apt-get install -y build-essential git cmake pkg-config libncurses-dev libbz2-dev  \
                         protobuf-compiler libprotoc-dev libprotobuf-dev libjansson-dev \
                         automake gettext autopoint libtool jq bsdmainutils bc rs parallel \
                         npm curl unzip redland-utils librdf-dev bison flex gawk lzma-dev \
                         liblzma-dev liblz4-dev libffi-dev libcairo-dev libboost-all-dev \
                         libzstd-dev pybind11-dev python3-pybind11 libssl-dev && \
    apt-get clean -y && \
    rm -Rf /var/lib/apt/lists/*

RUN cd / && \
    git clone --recursive https://github.com/vgteam/vg.git && \
    cd vg && \
    make mimalloc=on && \
    chmod +x /vg/bin/vg && \
    cp /vg/bin/vg /home/cactus/bin/vg && \
    echo "vm.overcommit_memory = 1" >> /etc/sysctl.conf