FROM adoptopenjdk/openjdk14:jdk-14.0.2_12-debian

RUN apt update -y && \
	apt-get upgrade -y && \
	apt-get install -y git less curl subversion bash openssh-server python3-dev && \
	rm -Rf /var/lib/apt/lists/* && \
	rm -Rf /var/cache/apt/*
	
ADD *.sh /
RUN chmod +x *.sh 

ENTRYPOINT ["/entrypoint.sh"]