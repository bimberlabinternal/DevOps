FROM continuumio/miniconda3

ARG AUGUSTUS_COMMIT=36ae43d

#RUN add-apt-repository -y ppa:deadsnakes/ppa
RUN apt-get update \
  && apt-get install --fix-missing -y build-essential libssl-dev libncurses5-dev libcurl4-openssl-dev liblzma-dev libbz2-dev \
    libboost-all-dev sqlite3 libsqlite3-0 libsqlite3-dev libgsl0-dev lp-solve liblpsolve55-dev libbamtools-dev wget git \
    wget bedtools bamtools samtools sqlite3 libgsl0-dev libcolamd2 libcurl4-openssl-dev exonerate augustus augustus-data augustus-doc \
    samtools bcftools libhdf5-dev libbigwig-dev \
  && apt-get install -y libhts-dev

## htslib
RUN git clone --recursive https://github.com/samtools/htslib.git \
  && cd htslib \
  && make install

## bcftools
RUN git clone https://github.com/samtools/bcftools.git \
  && cd bcftools \
  && make

## samtools
RUN git clone https://github.com/samtools/samtools \
  && cd samtools \
  && make \
  && make install

## MOVE Directories INTO $HOME/tool
RUN mkdir /root/tools \
    && mv samtools /root/tools \
    && mv htslib /root/tools \
    && mv bcftools /root/tools

# Kent
RUN for i in wigToBigWig faToTwoBit gff3ToGenePred genePredToBed genePredToFakePsl bamToPsl transMapPslToGenePred \
    pslPosTarget axtChain chainMergeSort pslMap pslRecalcMatch pslMapPostChain gtfToGenePred genePredToGtf bedtools \
    pslCheck pslCDnaFilter clusterGenes pslToBigPsl bedSort bedToBigBed hgLoadChain; do \
    wget -q http://hgdownload.soe.ucsc.edu/admin/exe/linux.x86_64/$i -O /bin/$i ; chmod +x /bin/$i ; done

## sonLib
RUN git clone https://github.com/ComparativeGenomicsToolkit/sonLib.git \
    && cd sonLib \
    && make

# HAL
RUN git clone https://github.com/ComparativeGenomicsToolkit/hal.git \
    && cd hal \
    && make \
    && cp /hal/bin/* /bin/

# LibBigWig
RUN git clone https://github.com/dpryan79/libBigWig.git \
    && cd libBigWig \
    && make install

# sambamba
RUN wget -q https://github.com/biod/sambamba/releases/download/v0.6.7/sambamba_v0.6.7_linux.tar.bz2 \
    && tar xvjf sambamba_v0.6.7_linux.tar.bz2 \
    && cp /sambamba /bin/

# WiggleTools
RUN git clone https://github.com/dahlo/WiggleTools
#  && cd WiggleTools && make \
#  && cp /WiggleTools/bin/* /bin/

RUN conda create -y -n cat python=3.7 \
    && echo "conda activate cat" >> ~/.bashrc

SHELL ["/bin/bash", "--login", "-c"]

RUN conda install -n cat -c conda-forge -c bioconda -c defaults -y \
      pyfasta luigi seaborn pandas \
      ete3 pysam numpy scipy bx-python bcbio-gff biopython parasail-python configobj sqlalchemy \
      samtools bamtools augustus exonerate wiggletools bedtools \
      ucsc-fatotwobit ucsc-gff3togenepred ucsc-genepredtobed ucsc-genepredtofakepsl ucsc-bamtopsl ucsc-transmappsltogenepred \
      ucsc-pslpostarget ucsc-axtchain ucsc-chainmergesort ucsc-pslmap ucsc-pslrecalcmatch ucsc-pslmappostchain \
      ucsc-gtftogenepred ucsc-genepredtogtf ucsc-pslcdnafilter ucsc-psltobigpsl \
      ucsc-bedsort ucsc-bedtobigbed ucsc-fasize ucsc-wigtobigwig ucsc-hgloadchain

RUN conda activate cat \
    && python3 -m pip install -y https://github.com/ComparativeGenomicsToolkit/Comparative-Annotation-Toolkit.git

RUN python3 --version

RUN conda activate cat \
    && python3 --version

RUN mkdir -p /augustus \
    && git clone https://github.com/Gaius-Augustus/Augustus.git \
    && cp -r /Augustus/config/ /augustus/config/ \
    && mv Augustus /root/Augustus

ENV AUGUSTUS_CONFIG_PATH=/augustus/config/

#COPY --from=builder /augustus/bin/* /bin/
#COPY --from=builder /augustus/scripts/* /bin/

RUN cd WiggleTools && make \
  && cp /WiggleTools/bin/* /bin/

SHELL ["conda", "run", "--no-capture-output", "-n", "cat", "/bin/bash", "-c"]