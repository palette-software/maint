#!/bin/bash -e

set -x

SCRIPT=`basename $0`
TOPDIR=$(cd `dirname $0` && pwd)
WINDIR=$(cd `dirname $0` && pwd -W)

CONF="${TOPDIR}/conf/httpd.conf"

usage () {
    cat <<EOF >&2

usage $SCRIPT [options]
  --listen-port <port>
  --ssl-listen-port <port>
  --server-name <name>         : Default='localhost'
  --ssl-cert-key-file <path>
EOF
}

if [[ $# == 0 ]]; then
    usage
    exit 1
fi

SERVER_NAME="localhost"
LISTEN_PORT=0
SSL_LISTEN_PORT=0
SSL_CERT_KEY_FILE=""
SSL_CERT_FILE=""
SSL_CERT_CHAIN_FILE=""

while test -n "$1"; do
    case "$1" in
	--server-name) SERVER_NAME="$2"; shift 2 ;;
	--port|--listen-port ) LISTEN_PORT="$2"; shift 2 ;;
	--ssl-port|--ssl-listen-port) SSL_LISTEN_PORT="$2"; shift 2 ;;
	--ssl-cert-key-file) SSL_CERT_KEY_FILE="$2"; shift 2 ;;
	--ssl-cert-file) SSL_CERT_FILE="$2"; shift 2 ;;
	--ssl-cert-chain-file) SSL_CERT_CHAIN_FILE="$2"; shift 2 ;;
	*) usage; exit 1 ;;
    esac
done

if [[ "${LISTEN_PORT}" -eq 0 && "${SSL_LISTEN_PORT}" -eq 0 ]] ; then
    echo "--listen-port or --ssl-listen-port is required." >&2
    usage
    exit 1
fi

if [ ! -f "${TOPDIR}/apache2/conf/env.conf" ]; then
    # simulate install time configuration
    cat <<EOF > "${TOPDIR}/apache2/conf/env.conf"
Define INSTALLDIR "${WINDIR}"
Define DATADIR "${WINDIR}"
EOF
fi

mkdir -p "${TOPDIR}/logs/maint"
if [ ! -d "${TOPDIR}/maint/www" ]; then
    mkdir -p "${TOPDIR}/maint"
    cp -a "${TOPDIR}/www" "${TOPDIR}/maint/"
fi

# runtime configuration which is done by 'maint start'
>"${TOPDIR}/maint/vars.conf"
echo Define SERVER_NAME ${SERVER_NAME} >>"${TOPDIR}/maint/vars.conf"

if [[ "${LISTEN_PORT}" -ne 0 ]] ; then
    echo Define LISTEN_PORT ${LISTEN_PORT} >>"${TOPDIR}/maint/vars.conf"
fi

if [[ "${SSL_LISTEN_PORT}" -ne 0 ]] ; then
    echo Define SSL_LISTEN_PORT ${SSL_LISTEN_PORT} >>"${TOPDIR}/maint/vars.conf"
fi

if [[ "${SSL_CERT_KEY_FILE}" ]] ; then
    echo Define SSL_CERT_KEY_FILE "\"${SSL_CERT_KEY_FILE}\"" >>"${TOPDIR}/maint/vars.conf"
fi

if [[ "${SSL_CERT_FILE}" ]] ; then
    echo Define SSL_CERT_FILE "\"${SSL_CERT_FILE}\"" >>"${TOPDIR}/maint/vars.conf"
fi

if [[ "${SSL_CERT_CHAIN_FILE}" ]] ; then
    echo Define SSL_CERT_CHAIN_FILE "\"${SSL_CERT_CHAIN_FILE}\"" >>"${TOPDIR}/maint/vars.conf"
fi

"${TOPDIR}/apache2/bin/httpd.exe" -f "${CONF}"
