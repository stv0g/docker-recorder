FROM alpine:3.13 as builder
LABEL version="1.0" description="OwnTracks Recorder"
LABEL authors="Jan-Piet Mens <jpmens@gmail.com>, Giovanni Angoli <juzam76@gmail.com>, Amy Nagle <kabili@zyrenth.com>, Malte Deiseroth <mdeiseroth88@gmail.com>"
MAINTAINER Malte Deiseroth <mdeiseroth88@gmail.com>

# build with `docker build --build-arg recorder_version=x.y.z '
ARG recorder_version=0.8.8

COPY entrypoint.sh /entrypoint.sh
COPY config.mk /config.mk
COPY recorder.conf /etc/default/recorder.conf
COPY recorder-health.sh /usr/local/sbin/recorder-health.sh

ENV VERSION=$recorder_version
ENV EUID=9999

RUN apk add --no-cache --virtual .build-deps \
        curl-dev libconfig-dev make \
        gcc musl-dev mosquitto-dev shadow wget \
    && apk add --no-cache \
        libcurl libconfig-dev mosquitto-dev lmdb-dev libsodium-dev lua5.2-dev \
    && groupadd -g $EUID appuser \
    && useradd -r -u $EUID -s "/bin/sh" -g appuser appuser \
    && mkdir -p /usr/local/source \
    && cd /usr/local/source \
    && wget https://github.com/owntracks/recorder/archive/$VERSION.tar.gz \
    && tar xzf $VERSION.tar.gz \
    && cd recorder-$VERSION \
    && mv /config.mk ./ \
    && make \
    && make install \
    && cd / \
    && chmod 755 /entrypoint.sh \
    && rm -rf /usr/local/source \
    && chmod 755 /usr/local/sbin/recorder-health.sh \
    && apk del .build-deps
RUN apk add --no-cache \
	curl jq

VOLUME ["/store", "/config"]

COPY recorder.conf /config/recorder.conf
COPY JSON.lua /config/JSON.lua

# If you absolutely need health-checking, enable the option below.  Keep in
# mind that until https://github.com/systemd/systemd/issues/6432 is resolved,
# using the HEALTHCHECK feature will cause systemd to generate a significant
# amount of spam in the system logs.
# HEALTHCHECK CMD /usr/local/sbin/recorder-health.sh

EXPOSE 8083

ENTRYPOINT ["/entrypoint.sh"]
