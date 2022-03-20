FROM mcr.microsoft.com/openjdk/jdk:17-ubuntu

RUN apt-get update -y && \
	apt-get install -y git less curl subversion bash openssh-server python3-dev build-essential && \
	apt-get clean

ADD *.sh /
RUN chmod +x *.sh 

ENTRYPOINT ["/entrypoint.sh"]