FROM durosoft/crystal-alpine:latest

RUN mkdir /app
WORKDIR /app

ADD . /app
RUN shards build --release

CMD bin/hornet
