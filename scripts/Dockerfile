FROM alpine

LABEL \
  "name"="Automatic Merge/Pull Request to LabKey" \
  "repository"="https://github.com/BimberLabInternal/DevOps.git" \
  "maintainer"="Ben Bimber"

RUN echo "http://nl.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories && \
  apk --no-check-certificate update && \
  apk add --no-cache --no-check-certificate git openssh-client ca-certificates hub && \
  update-ca-certificates -f && \
  echo "Host *" >> /etc/ssh/ssh_config

ADD *.sh /
RUN chmod +x *.sh 

ENTRYPOINT ["/entrypoint.sh"]