FROM adoptopenjdk/openjdk14:jdk-14.0.2_12-alpine

RUN apk --update add git less curl subversion bash openssh python3-dev && \
    rm -rf /var/lib/apt/lists/* && \
    rm /var/cache/apk/*
	
ADD *.sh /
RUN chmod +x *.sh 

ENTRYPOINT ["/entrypoint.sh"]