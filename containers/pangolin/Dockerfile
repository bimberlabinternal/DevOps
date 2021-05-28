from conda/miniconda3-centos7

# Make RUN commands use `bash --login`:
SHELL ["/bin/bash", "--login", "-c"]

RUN yum install -y git which \
	&& conda update -n base -c defaults conda

RUN git clone https://github.com/cov-lineages/pangolin.git \
	&& cd pangolin \
	&& conda env create -f environment.yml

RUN conda init bash
RUN echo "conda activate pangolin" >> ~/.bashrc

RUN cd /pangolin && pip install . 

RUN pangolin --update