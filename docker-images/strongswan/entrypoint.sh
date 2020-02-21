#!/bin/sh -e

sysctl -w net.ipv4.ip_forward=1

_term() {
  echo "Shutting down strongSwan/ipsec..."
  ipsec stop
}

# SIGTERM
trap _term SIGTERM

echo "Starting up strongSwan/ipsec..."
ipsec start --nofork "$@" &
child=$!
# wait for child to exit
wait "$child"
