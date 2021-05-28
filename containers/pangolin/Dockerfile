from continuumio/miniconda3

# Make RUN commands use `bash --login`:
SHELL ["/bin/bash", "-c"]

RUN apt-get update -q \
    && apt-get install -q -y --no-install-recommends git python3-pip \
	&& conda update -n base -c defaults conda \
	&& apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN git clone https://github.com/cov-lineages/pangolin.git \
	&& cd pangolin \
	&& conda env create -f environment.yml

RUN conda init bash
RUN cp ~/.bashrc /etc/.bashrc
RUN echo "conda activate pangolin" >> /etc/.bashrc
RUN echo "echo 'called!'" >> /etc/.bashrc

RUN source /etc/.bashrc && cd /pangolin && pip install . 

ENV PATH /opt/conda/envs/pangolin/bin:$PATH

RUN pangolin --update