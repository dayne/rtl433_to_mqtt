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

while(true); do
  log "starting rtl433_to_mqtt"
  ./rtl433_to_mqtt.rb -l
  log "rtl433_to_mqtt crashed / killed"
  echo 
  echo "relaunching in 30 seconds"
  echo 
  echo "  Debug hint: double check USB receiver is fully plugged in"
  sleep 30;
done
