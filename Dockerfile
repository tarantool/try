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
    && yum -y install git gcc make cmake unzip tarantool-devel iptables cartridge-cli

ENV GOSU_VERSION=1.11
RUN gpg --keyserver hkps://keys.openpgp.org --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 \
    && curl -o /usr/local/bin/gosu -SL "https://github.com/tianon/gosu/releases/download/${GOSU_VERSION}/gosu-amd64" \
    && curl -o /usr/local/bin/gosu.asc -SL "https://github.com/tianon/gosu/releases/download/${GOSU_VERSION}/gosu-amd64.asc" \
    && gpg --verify /usr/local/bin/gosu.asc \
    && rm /usr/local/bin/gosu.asc \
    && rm -r /root/.gnupg/ \
    && chmod +x /usr/local/bin/gosu

COPY --from=front /build/cartridge-app-1.0.0-0.tar.gz /opt
RUN cd /opt && tar -xf /opt/cartridge-app-1.0.0-0.tar.gz

RUN chown -R tarantool:tarantool /opt/cartridge-app

WORKDIR /opt/cartridge-app

COPY instances.yml run.sh ./

CMD ./run.sh
