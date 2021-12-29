FROM adoptopenjdk/openjdk16

RUN apt update -y && \
	apt-get upgrade -y && \
	apt-get install -y git less curl subversion bash openssh-server python3-dev build-essential && \
	rm -Rf /var/lib/apt/lists/* && \
	rm -Rf /var/cache/apt/*
	
ADD *.sh /
RUN chmod +x *.sh 

ENTRYPOINT ["/entrypoint.sh"]