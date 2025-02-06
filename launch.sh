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
  if [ $? -eq 0 ]; then
	log "rtl433_to_mqtt existed gracefully"
	exit 1
  else
        log "rtl433_to_mqtt crashed / killed"
  	echo "relaunching in 5 seconds - double check USB receiver is fully plugged in"
  	sleep 5;
  fi
done
