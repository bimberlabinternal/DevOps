FROM adoptopenjdk/openjdk14:jdk-14.0.2_12-alpine

# See: https://github.com/node-gfx/node-canvas-prebuilt/issues/77
RUN apk --update add git less curl subversion bash openssh python3-dev && \
	apk add --no-cache nodejs npm build-base g++ cairo-dev jpeg-dev pango-devbash imagemagick \
	npm i -g node-gyp \
	rm -rf /var/lib/apt/lists/* && \
	rm /var/cache/apk/*
	
ADD *.sh /
RUN chmod +x *.sh 

ENTRYPOINT ["/entrypoint.sh"]