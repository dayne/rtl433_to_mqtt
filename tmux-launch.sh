#!/bin/bash

# crontab entry you can use (fix the path)
# @reboot /home/pi/rtl433_to_mqtt/tmux-launch.sh

if ! command -v tmux > /dev/null; then
  echo "Error: Missing tmux ... unable to continue"
  echo "       Try fixing with: sudo apt install tmux" 
fi

tmux list-sessions | grep rtl2mqtt > /dev/null 2>&1
if [ $? -eq 0 ]; then
	echo "session already started"
	echo "use: tmux attach -t rtl2mqtt:launcher"
	exit 1
fi

tmux new-session -d -s rtl2mqtt -n launcher
tmux send-keys -t rtl2mqtt:launcher "$(dirname ${0})/launch.sh" Enter
echo "attach to tmux with:  tmux attach -t rtl2mqtt:launcher"
