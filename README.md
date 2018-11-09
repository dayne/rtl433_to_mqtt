# rtl433_to_mqtt

Simple ruby script to be used with a Software Defined Radio (SDR) with the [rtl-sdr](https://www.rtl-sdr.com/) libraries and the [rtl_433](https://github.com/merbanan/rtl_433) tool that scans 433.9 MHz and decodes traffic from things like temperature sensors.

This script parses the JSON output from rtl_433, if the string parses as JSON it is considered a valid sensor message that is then passed on to MQTT.  This allows downstream MQTT clients to filter, log, and analyse messages.


## software setup

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

Configure and launch the collection script
```
cp config.yml.example config.yml
./launch.sh
```
