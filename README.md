# rtl433_to_mqtt

<img align="right" width="250" src="../master/temp2rtl_433.JPG">

Simple ruby script to be used with a Software Defined Radio (SDR) with the [rtl-sdr](https://www.rtl-sdr.com/) libraries and the [rtl_433](https://github.com/merbanan/rtl_433) tool that scans 433.9 MHz and decodes traffic from things like temperature sensors.

This script parses the JSON output from rtl_433, if the string parses as JSON it is considered a valid sensor message that is then passed on to MQTT.  This allows downstream MQTT clients to filter, log, and analyse messages.


## software setup

Install on a Raspberry Pi with Raspbian is super simple!

```
git clone https://github.com/dayne/rtl433_to_mqtt
cd rtl433_to_mqtt/setup
./setup.sh
# wait a while and say yes to a few things
sudo reboot
```

Login and you should be ready to configure and launch the collection script
```
cp config.yml.example config.yml
./launch.sh
```

### The details of what that script is going to do:

Install rtl-sdr libraries and drivers: _[more details](https://ranous.files.wordpress.com/2016/03/rtl-sdr4linux_quickstartv10-16.pdf)_

```
apt install rtl-sdr
echo "blacklist dvb_usb_rtl28xxu" | sudo tee -a /etc/modprobe.d/blacklist-rtl.conf
reboot
```

[Install rtl_433 via the build instructions](https://github.com/merbanan/rtl_433/blob/master/BUILDING.md)

Install mosqitto MQTT server and ensure it is launched
```
sudo apt install mosquitto
```

```
