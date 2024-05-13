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

# libc6-compat is needed for go binary to run on alpine if it was compiled for general linux
RUN apk add --no-cache curl jq mailx bash ssmtp libc6-compat
RUN echo "mailhub=mail.csclub.uwaterloo.ca" > /etc/ssmtp/ssmtp.conf \
  && echo "FromLineOverride=YES" >> /etc/ssmtp/ssmtp.conf

COPY ./mirror-checker2 ./mirror-checker2
RUN chmod +x ./mirror-checker2 ./one-shot.sh

# -f: foreground (so container doesn't exit)
# -d: log level. 0 = debug
CMD /usr/sbin/crond -d 0 && tail -f /var/log/cron.log