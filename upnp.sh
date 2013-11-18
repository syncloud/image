#!/bin/bash

BASE_PORT=10000
MAX_PORT=100000

ROUTER_ADDR=`upnpc -s | grep ExternalIPAddress | sed s/.*\ \=\ //`
MY_ADDR=`ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1'`
MY_PORT=80

function get_external_port {
  EXTERNAL_PORT=`upnpc -l | grep "TCP" | grep ${MY_ADDR}:${MY_PORT} | grep -Eo "TCP [0-9]*" | grep -Eo "[0-9]*"`
}

function find_available_port {
  for i in {0..10000}
  do
    PORT=$((${BASE_PORT} + ${i}))
    echo "probing ${PORT} ..."
    if upnpc -l | grep "TCP" | grep -Eo "TCP ${PORT}->"
    then
      echo "taken"
    else
      echo "available"
      BASE_PORT=${PORT}
      break
    fi
  done
}

function add_mapping {
 upnpc -a ${MY_ADDR} ${MY_PORT} ${BASE_PORT} TCP
}

if [ -n "$1" ]; then
  MY_PORT=$1 
fi

get_external_port

echo "Router: ${ROUTER_ADDR}"
echo "My address: ${MY_ADDR}"

if [ -z "${EXTERNAL_PORT}" ]; then
  echo "Adding port mapping"
  find_available_port
  add_mapping
  get_external_port
fi

echo "Your public url is: ${ROUTER_ADDR}:${EXTERNAL_PORT}"
