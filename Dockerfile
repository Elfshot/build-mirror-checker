# syntax=docker/dockerfile:1

FROM alpine:latest
WORKDIR /app
RUN mkdir -p ./data

RUN touch crontab.tmp \
  && echo '0 10 * * * /app/one-shot.sh' > crontab.tmp \
  && crontab crontab.tmp \
  && rm -rf crontab.tmp

COPY ./data/mirrors.json ./data
COPY ./one-shot.sh ./one-shot.sh

RUN apk add --no-cache curl jq

COPY ./mirror-checker2 ./mirror-checker2
RUN chmod +x ./mirror-checker2

CMD ["/usr/sbin/crond", "-f", "-d", "0"]