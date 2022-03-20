FROM openjdk:17-alpine

RUN apk upgrade && \
	apk add --no-cache git less curl subversion bash openssh-server python3-dev build-base npm nodejs && \
	rm -rf /var/cache/apk/*
	
ADD *.sh /
RUN chmod +x *.sh 

ENTRYPOINT ["/entrypoint.sh"]