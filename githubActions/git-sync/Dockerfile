FROM alpine

LABEL \
  "name"="GitHub Repo Sync" \
  "repository"="https://github.com/BimberLabInternal/githubActions/git-sync" \
  "maintainer"="Ben Bimber"

RUN apk add --no-cache git openssh-client && \
  echo "StrictHostKeyChecking no" >> /etc/ssh/ssh_config

ADD *.sh /

ENTRYPOINT ["/entrypoint.sh"]