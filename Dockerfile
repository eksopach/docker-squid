FROM ubuntu:bionic
LABEL maintainer="shk.rajat@gmail.com"

ENV SQUID_VERSION=3.5.27 \
    SQUID_CACHE_DIR=/var/spool/squid \
    SQUID_CACHE_ROCK_DIR=/var/spool/squid/rock \
    SQUID_CACHE_AUFS_DIR=/var/spool/squid/aufs \
    SQUID_LOG_DIR=/var/log/squid \
    SQUID_USER=proxy

RUN apt-get update \
      && DEBIAN_FRONTEND=noninteractive apt-get install -y squid=${SQUID_VERSION}* \
      && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY entrypoint.sh /sbin/entrypoint.sh
RUN chmod 755 /sbin/entrypoint.sh

ENTRYPOINT ["/sbin/entrypoint.sh"]
