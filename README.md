# rtl433_to_mqtt

<img align="right" width="250" src="../master/docs/temp2rtl_433.JPG">

Simple ruby script to be used with a Software Defined Radio (SDR) with the [rtl-sdr](https://www.rtl-sdr.com/) libraries and the [rtl_433](https://github.com/merbanan/rtl_433) tool that scans 433.9 MHz and decodes traffic from things like temperature sensors.

This tool is focused on:
* Run the `rtl_433` command and parses the JSON formatted messages.
* Captures messages into a log file with automatic daily log-rotation.
* De-duplicates messages.
  * Some sensors send triplicate messages to ensure delivery. Script drops dups.
* Adds a current unix timestamp `ts` value to the payload.
* Publish de-duplicated messages onto an MQTT topic.

This allows downstream MQTT clients to subscribe to the de-duplicated feed for
filtering, logging, and analysis.

Included tools:
* `setup.sh` - debian/ubuntu/raspbian setup script to install needed
  dependancies to use this.
* `rtl433_to_mqtt.rb` - core tool that does the work
* `launch.sh` - simple launcher for the `rtl433_to_mqtt.rb` that will
  automatically, after 5 seconds, relaunches the tool incase it dies.
* `tmux-launch.sh` - create a new tmux session and runs `launch.sh`

## software setup

Install on a Raspberry Pi with Raspbian is super simple!

```
git clone https://github.com/dayne/rtl433_to_mqtt
cd rtl433_to_mqtt
./setup.sh
# wait a while and say yes to a few things
sudo reboot
```

Login and you should be ready to configure and launch the collection script
```
cd rtl433_to_mqtt # location of code
./launch.sh
```

Default configuration in the `config.yml.example` will have all the messages 
pushed to a localhost MQTT server and the `/rtl_433/raw` topic. The SDR listens on 433.92Mhz by default.
* `server: localhost`
* `topic: /rtl_433/raw`
* `rtl_freq: 433920000`

You can watch that default flow by opening up a terminal and using `mosquitto_sub`
to watch that local topic: 
```
mosquitto_sub -h localhost -t /rtl_433/raw
```

To customize the MQTT broker or topic published, or to change the frequency 
that the SDR listens on, copy the `config.yml.example` to `config.yml` and 
change appropriately.

#### The details of `setup.sh`:

Install rtl-sdr libraries and drivers: _[more details](https://ranous.files.wordpress.com/2016/03/rtl-sdr4linux_quickstartv10-16.pdf)_

```
apt install rtl-sdr # and other build dependancies
echo "blacklist dvb_usb_rtl28xxu" | sudo tee -a /etc/modprobe.d/blacklist-rtl.conf
reboot
```

[Install rtl_433 via the build instructions](https://github.com/merbanan/rtl_433/blob/master/BUILDING.md)

Install mosqitto MQTT server and ensure it is launched
```
sudo apt install mosquitto
```

Runs ruby bundler to get the script dependancies.

## usage

Setup your `config.yml`

```
cp config.yml.example config.yml
# edit to point at your mqtt server (or leave alone for localhost)
./launch.sh
```

If you want to launch in tmux: use `./tmux-launch.sh`

Autolaunch on reboot?  Add the following line to your crontab: (_fix the path of course_)
```
@reboot /home/pi/projects/rtl433_to_mqtt/tmux-launch.sh
```

## hardware requirements

* Raspbery Pi  _$50_
* A USB Software Defined Radio (SDR) like the [NooElec NESDR Mini USB RTL-SDR](https://www.amazon.com/NooElec-NESDR-Mini-Compatible-Packages/dp/B009U7WZCA) _$20_
* External/Internal temp sensor that broadcasts on 433 Mhz like the [AcuRite-06002M](https://www.amazon.com/AcuRite-06002M-Wireless-Temperature-Humidity/dp/B00T0K8NXC/) _$12_
