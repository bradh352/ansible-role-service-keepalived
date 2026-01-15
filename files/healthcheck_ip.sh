#!/bin/sh
if [ "$#" != 2 ] ; then
  echo "Usage: $0 host/ip port"
  exit 1
fi

host=$1
port=$2

nc --version 2>&1 | grep nmap > /dev/null
if [ "$?" = "0" ] ; then
  EXTRA_ARGS=""
else
  # Need -q 0 on netcat-openbsd otherwise will hang
  EXTRA_ARGS="-q 0"
fi

nc -w 5 $EXTRA_ARGS $host $port < /dev/null > /dev/null 2>&1
exit $?
