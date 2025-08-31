#!/bin/bash


URL=
VALIDATE_CERT=1
HTTP_CODES=200
IP=
CONNECT_TIMEOUT=5
MAX_TIME=10

print_help() {
    echo "Usage: $0 [options]"
    echo ""
    echo "  -u, --url               Required. URL to test."
    echo "                          Example: https://www.google.com/?search=foo"
    echo "  -n, --no-validate-cert  Disable certificate validation on https"
    echo "  -i, --ip                Use the given IP address to connect to server"
    echo "                          rather than what is returned via DNS.  Useful"
    echo "                          for checking local server certificates with SNI."
    echo "  -c, --http-codes        Comma delimited list of HTTP codes to treat as"
    echo "                          success. Defaults to 200."
    echo "  -x, --connect-timeout   Timeout in seconds for connection operation."
    echo "                          Default: 5"
    echo "  -m, --max-time          Maximum time for query before failure"
    echo "                          Default: 10"
    echo "  -h, --help              This help."
    echo ""
    echo "Examples:"
    echo "  $0 -u http://localhost"
    echo "  $0 -u https://bradhouse.dev -i 127.0.0.1"
    echo ""
}

while [[ "$#" -gt 0 ]]; do
    case "$1" in
        -u|--url)
            URL=$2
            shift 2
            ;;
        -n|--no-validate-cert)
            VALIDATE_CERT=0
            shift 1
            ;;
        -i|--ip)
            IP=$2
            shift 2
            ;;
        -c|--http-codes)
            HTTP_CODES=$2
            shift 2
            ;;
        -x|--connect-timeout)
            CONNECT_TIMEOUT=$2
            shift 2
            ;;
        -m|--max-time)
            MAX_TIME=$2
            shift 2
            ;;
        -h|--help)
            print_help
            exit 0
            ;;
        --)
            shift
            break
            ;;
        *)
            echo "Invalid option $1" >&2
            print_help
            exit 1
            ;;
    esac
done


if [ -z "$URL" ] ; then
    echo "Missing --url"
    print_help
    exit 1
fi

PORT=
DOMAINPORT=`echo $URL | sed -E 's|^[^/]+//([^@/]+@)?([^/?]+).*|\2|'`
DOMAIN=`echo $DOMAINPORT | cut -d : -f 1`
if echo $DOMAINPORT | grep ":" > /dev/null 2>&1 ; then
    PORT=`echo $DOMAINPORT | cut -d : -f 2`
fi
SCHEME=`echo $URL | sed -E "s|^([^:]+).*|\1|"`
if [ -z "$DOMAIN" -o -z "$SCHEME" ] ; then
    echo "Invalid URL: ${URL}"
    print_help
    exit 1
fi

if [ -z "$PORT" ] ; then
    if [ "${SCHEME}" = "http" ] ; then
        PORT=80
    elif [ "${SCHEME}" = "https" ] ; then
        PORT=443
    else
        echo "Unsupported URL scheme"
        exit 1
    fi
fi

CURL_OPTS=
if [ ! -z "$IP" ] ; then
    CURL_OPTS="${CURL_OPTS} --resolve ${DOMAIN}:${PORT}:${IP}"
fi
if [ "$VALIDATE_CERT" = "0" ] ; then
    CURL_OPTS="${CURL_OPTS} --insecure"
fi

HTTP_CODE=`curl \
  --silent \
  --connect-timeout ${CONNECT_TIMEOUT} \
  --max-time ${MAX_TIME} \
  --write-out "%{http_code}" \
  --output /dev/null \
  ${CURL_OPTS} \
  ${URL} 2>/dev/null`

retcode=$?

if [ "${retcode}" != "0" ] ; then
    exit 2
fi

for code in $(echo $HTTP_CODES | sed "s/,/ /g") ; do
    if [ "$code" == "$HTTP_CODE" ] ; then
        exit 0
    fi
done

exit 3
