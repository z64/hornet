FROM crystallang/crystal:0.25.0

RUN apt-get update \
 && apt-get install --yes fortune-mod

RUN mkdir /opt/hornet
WORKDIR /opt/hornet

ADD . /opt/hornet
RUN shards build --release

CMD bin/hornet
