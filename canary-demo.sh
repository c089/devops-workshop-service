#!/bin/sh
while true
do
  clear
  echo -n "Live:   "
  curl https://hello.k3d.localhost/ ; echo
  echo -n "Canary: "
  curl https://hello-canary.k3d.localhost/ ; echo
  echo -n "Stable: "
  curl https://hello-stable.k3d.localhost/ ; echo
  echo "-----------"
  sleep 1
done
