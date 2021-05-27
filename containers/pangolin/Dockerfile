from conda/miniconda3-centos7

RUN yum install -y git

RUN git clone https://github.com/cov-lineages/pangolin.git \
	&& cd pangolin \
	&& conda env create -f environment.yml \
	&& conda activate pangolin \
	&& pip install . \
	&& pangolin --update
