#!/bin/bash

ROUTER_ADDR=`upnpc -s | grep ExternalIPAddress | sed s/.*\ \=\ //`
MY_ADDR=`ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1'`

function get_external_port {
  EXTERNAL_PORT=`upnpc -l | grep "TCP" | grep ${MY_ADDR} | grep -Eo "TCP [0-9]*" | grep -Eo "[0-9]*"`
}

get_external_port

echo "Router: ${ROUTER_ADDR}"
echo "My address: ${MY_ADDR}"

if [ -z "${EXTERNAL_PORT}" ]; then
  echo "Adding port mapping"
  upnpc -a ${MY_ADDR} 80 10000 TCP
  get_external_port
fi

echo "Your public url is: ${ROUTER_ADDR}:${EXTERNAL_PORT}"
