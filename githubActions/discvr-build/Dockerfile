FROM eclipse-temurin:17

RUN apt-get update -y && \
	apt-get install -y git less curl subversion bash openssh-server python3-dev build-essential unzip && \
	apt-get clean

ADD *.sh /
RUN chmod +x *.sh 

ENTRYPOINT ["/entrypoint.sh"]