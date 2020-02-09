FROM alpine

LABEL \
  "name"="Automatic Merge/Pull Request to LabKey" \
  "repository"="https://github.com/BimberLabInternal/DevOps.git" \
  "maintainer"="Ben Bimber"

RUN echo "http://nl.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories && \
  apk update && apk add --no-cache git openssh-client hub && \
  echo "StrictHostKeyChecking no" >> /etc/ssh/ssh_config

ADD *.sh /
RUN chmod +x *.sh 

ENTRYPOINT ["/entrypoint.sh"]