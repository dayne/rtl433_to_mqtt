#!/bin/bash

# @reboot /home/pi/rtl433_to_mqtt/tmux-launch.sh

tmux list-sessions | grep rtl2mqtt > /dev/null 2>&1
if [ $? -eq 0 ]; then
	echo "session already started"
	exit 1
fi

tmux new-session -d -s rtl2mqtt -n launcher
tmux send-keys -t rtl2mqtt:launcher "$(dirname ${0})/launch.sh" Enter
tmux attach -t rtl2mqtt:launcher
