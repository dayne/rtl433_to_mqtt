#!/bin/bash

cd  "$(dirname "$0")"
pwd

log() {
  echo "#>  ${1}"
  echo "`date +%Y.%m.%d-%H:%M:%S`: ${1}" >> launch.log
}

if [ ! -d logs ]; then
  echo "creating logs dir"
  mkdir logs
fi

delay=10 

while(true); do
  log "starting rtl433_to_mqtt"
  ./rtl433_to_mqtt.rb -l
  if [ $? -eq 0 ]; then
    log "rtl433_to_mqtt exited gracefully"
    exit 0
  else
    log "rtl433_to_mqtt crashed / killed ungracefully"
  fi
  echo 
  echo 
  echo "  Debug hint: double check USB receiver is fully plugged in"
  echo "  relaunching in $delay seconds"
  sleep $delay
  delay=$((delay * 2))  # Double the delay after each failure
  if [ $delay -gt 600 ]; then
    delay=600  # Cap the delay at 10 minutes
  fi
done
