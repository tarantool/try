FROM node:14 AS front


RUN curl -L https://tarantool.io/live/2.7/installer.sh | bash
RUN apt install -y tarantool cartridge-cli

RUN mkdir /build
WORKDIR /build

COPY analytics ./analytics
COPY front ./front
COPY \
    init.lua \
    cartridge.pre-build \
    cartridge.post-build \
    cartridge-app-scm-1.rockspec \
    Makefile \
    stateboard.init.lua \
    ./

RUN cartridge pack tgz --version 1.0.0 --debug


FROM centos:8
LABEL maintainer="artembo@me.com"

RUN groupadd tarantool && adduser -g tarantool tarantool

RUN curl -L https://tarantool.io/live/2.7/installer.sh | bash && yum install -y tarantool

RUN set -x \
    && yum -y install git gcc make cmake unzip tarantool-devel iptables cartridge-cli \
    && : "---------- basic git setup ----------" \
    && git config --global user.email "you@example.com" \
    && git config --global user.name "Example User" \
    && rm -rf /var/cache/yum

RUN set -x \
    && : "---------- gosu ----------" \
    && gpg --keyserver pool.sks-keyservers.net --recv-keys \
       B42F6819007F00F88E364FD4036A9C25BF357DD4 \
    && curl -o /usr/local/bin/gosu -SL \
       "https://github.com/tianon/gosu/releases/download/1.2/gosu-amd64" \
    && curl -o /usr/local/bin/gosu.asc -SL \
       "https://github.com/tianon/gosu/releases/download/1.2/gosu-amd64.asc" \
    && gpg --verify /usr/local/bin/gosu.asc \
    && rm /usr/local/bin/gosu.asc \
    && rm -rf /root/.gnupg/ \
    && chmod +x /usr/local/bin/gosu

COPY iptables.rules /tmp/iptables.rules
RUN rm /sbin/ping /usr/bin/ping

COPY --from=front /build/cartridge-app-1.0.0-0.tar.gz /opt
RUN cd /opt && tar -xf /opt/cartridge-app-1.0.0-0.tar.gz

RUN chown -R tarantool:tarantool /opt/cartridge-app

WORKDIR /opt/cartridge-app

COPY instances.yml run.sh ./

CMD ./run.sh
