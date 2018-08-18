FROM jrei/crystal-alpine

RUN mkdir /app
COPY . /app
RUN cd /app && shards build

ENTRYPOINT /app/bin/hornet
