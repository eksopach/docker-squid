#!/bin/bash
set -e

create_log_dir() {
  mkdir -p ${SQUID_LOG_DIR}
  chmod -R 755 ${SQUID_LOG_DIR}

  chown -R ${SQUID_USER}:${SQUID_USER} ${SQUID_LOG_DIR}
}

create_cache_dir() {
  mkdir -p ${SQUID_CACHE_DIR}
  mkdir -p ${SQUID_CACHE_ROCK_DIR}
  mkdir -p ${SQUID_CACHE_AUFS_DIR}

  chown -R ${SQUID_USER}:${SQUID_USER} ${SQUID_CACHE_DIR}
}

create_tls_dir() {
  mkdir -p ${SQUID_TLS_DIR}

  chown -R ${SQUID_USER}:${SQUID_USER} ${SQUID_TLS_DIR}
}

create_tls_db() {
  test -d ${SQUID_CACHE_DIR}/ssl_db || /usr/libexec/security_file_certgen -c -s ${SQUID_CACHE_DIR}/ssl_db -M 4MB

  chown -R ${SQUID_USER}:${SQUID_USER} ${SQUID_CACHE_DIR}/ssl_db
}

#create_log_dir
create_cache_dir
create_tls_dir
create_tls_db

chown ${SQUID_USER}:${SQUID_USER} /dev/stdout
chown ${SQUID_USER}:${SQUID_USER} /dev/stderr

# allow arguments to be passed to squid
if [[ ${1:0:1} = '-' ]]; then
  EXTRA_ARGS="$@"
  set --
elif [[ ${1} == squid || ${1} == $(which squid) ]]; then
  EXTRA_ARGS="${@:2}"
  set --
fi

# default behaviour is to launch squid
if [[ -z ${1} ]]; then
  if [[ ! -d ${SQUID_CACHE_DIR}/00 ]]; then
    echo "Initializing cache..."
    $(which squid) -N -f /etc/squid4/squid.conf -z
  fi
  echo "Starting squid..."
  exec $(which squid) -f /etc/squid4/squid.conf -NYCd 1 ${EXTRA_ARGS}
else
  exec "$@"
fi
