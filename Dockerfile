FROM ubuntu:bionic
LABEL maintainer="shk.rajat@gmail.com"

ENV SQUID_VERSION=4.12 \
    SQUID_CACHE_DIR=/var/spool/squid \
    SQUID_CACHE_ROCK_DIR=/var/spool/squid/rock \
    SQUID_CACHE_AUFS_DIR=/var/spool/squid/aufs \
    SQUID_LOG_DIR=/var/log/squid \
    SQUID_USER=proxy

RUN cat /etc/apt/sources.list | grep -v '^#' | sed /^$/d | sort | uniq > sources.tmp.1 && \
      cat /etc/apt/sources.list | sed s/deb\ /deb-src\ /g | grep -v '^#' | sed /^$/d | sort | uniq > sources.tmp.2 && \
      cat sources.tmp.1 sources.tmp.2 > /etc/apt/sources.list && \
      rm -f sources.tmp.1 sources.tmp.2

RUN apt-get update \
      && DEBIAN_FRONTEND=noninteractive apt-get build-dep -y squid \
      && DEBIAN_FRONTEND=noninteractive apt-get install -y openssl wget build-essential libssl-dev

RUN cd /tmp \
      && wget -O - http://www.squid-cache.org/Versions/v4/squid-${SQUID_VERSION}.tar.gz | tar zxfv - \
      && cd squid-${SQUID_VERSION} \
      && ./configure \
        --prefix=/usr \
        --datadir=/usr/share/squid4 \
		--sysconfdir=/etc/squid4 \
		--localstatedir=/var \
		--mandir=/usr/share/man \
		--enable-inline \
		--enable-async-io=8 \
		--enable-storeio="ufs,aufs,diskd,rock" \
		--enable-removal-policies="lru,heap" \
		--enable-delay-pools \
		--enable-cache-digests \
		--enable-underscores \
		--enable-icap-client \
		--enable-follow-x-forwarded-for \
		--enable-auth-basic="DB,fake,getpwnam,LDAP,NCSA,NIS,PAM,POP3,RADIUS,SASL,SMB" \
		--enable-auth-digest="file,LDAP" \
		--enable-auth-negotiate="kerberos,wrapper" \
		--enable-auth-ntlm="fake" \
		--enable-external-acl-helpers="file_userip,kerberos_ldap_group,LDAP_group,session,SQL_session,unix_group,wbinfo_group" \
		--enable-url-rewrite-helpers="fake" \
		--enable-eui \
		--enable-esi \
		--enable-icmp \
		--enable-zph-qos \
		--with-openssl \
		--enable-ssl \
		--enable-ssl-crtd \ 
		--disable-translation \
		--with-swapdir=/var/spool/squid4 \
		--with-logdir=/var/log/squid4 \
		--with-pidfile=/var/run/squid4.pid \
		--with-filedescriptors=65536 \
		--with-large-files \
		--with-default-user=proxy \
        	--disable-arch-native \
      && make && make install \
      && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN apt-get update \
      && DEBIAN_FRONTEND=noninteractive apt-get install netcat sudo -y \
      && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ENV SQUID_CACHE_DIR=/var/spool/squid4 \
    SQUID_CACHE_ROCK_DIR=/var/spool/squid4/rock \
    SQUID_CACHE_AUFS_DIR=/var/spool/squid4/aufs \
    SQUID_LOG_DIR=/var/log/squid4 \
    SQUID_TLS_DIR=/etc/squid4/tls


RUN echo -e "Defaults:squid !requiretty" > /etc/sudoers.d/squid \
    && echo -e "squid ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers.d/squid \
    && ln -sf /dev/stdout ${SQUID_LOG_DIR}/access.log \
    && ln -sf /dev/stderr ${SQUID_LOG_DIR}/store.log \
    && ln -sf /dev/stderr ${SQUID_LOG_DIR}/cache.log

COPY entrypoint.sh /sbin/entrypoint.sh

RUN chmod 755 /sbin/entrypoint.sh

ENV PATH /sbin:${PATH}

ENTRYPOINT ["entrypoint.sh"]

HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
    CMD [ "nc", "-vz", "127.0.0.1", "3128" ]

