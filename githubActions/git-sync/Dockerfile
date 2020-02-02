FROM alpine

LABEL \
  "name"="GitHub Repo Sync" \
  "repository"="https://github.com/BimberLabInternal/DevOps.git" \
  "maintainer"="Ben Bimber"

RUN apk add --no-cache git openssh-client && \
  echo "StrictHostKeyChecking no" >> /etc/ssh/ssh_config

ADD *.sh /
RUN chmod +x *.sh 

ENTRYPOINT ["/entrypoint.sh"]