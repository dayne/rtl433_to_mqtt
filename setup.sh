#!/bin/bash

source 'lib/apt-lib.sh'

require_root

runAptGetUpdate
installAptPackages libtool libusb-1.0-0-dev librtlsdr-dev rtl-sdr build-essential cmake pkg-config git ruby mosquitto

function install_rtl_433() {
if [ ! -d rtl_433 ]; then
	git clone https://github.com/merbanan/rtl_433.git
fi

cd rtl_433

if [ ! -d build ]; then
	mkdir build
fi
pushd .
cd build
cmake ../
if [ $? -eq 1 ]; then
	echo "cmake failed - debug that"
	exit 1
fi

make
if [ $? -eq 1 ]; then
	echo "make failed - debug that"
	exit 1
fi

sudo make install
if [ $? -eq 1 ]; then
	echo "make install failed - debug that"
	exit 1
else
	echo "rtl_433 tools installed into /usr/local/"
fi
popd
}

if [ ! -f /etc/modprobe.d/blacklist-rtl.conf ]; then
	echo "blacklist dvb_usb_rtl28xxu" | sudo tee -a /etc/modprobe.d/blacklist-rtl.conf
	echo "blacklist file added - you need to reboot later"
fi

if have_command rtl_433; then
	echo "rtl_433 detected - skipping install"
else
	install_rtl_433
fi

if [ ! -f Gemfile.lock ]; then
	if have_command bundle; then
		bundle
    if [ $? -eq 0 ]; then
      echo "bundle success"
    else
      echo "BUNDLE INSTALL FAILED"
    fi
	else
		if have_command gem; then
			sudo gem install bundler
			bundle
		else
			echo "ERROR: missing gem command needed to install bundler"
			exit 1
		fi
	fi
fi

echo "install completed"

crontab -l | grep tmux-launch > /dev/null 2>&1
if [ $? -eq 0 ]; then
	info "tmux-launch.sh already setup in crontab"
else
	info 'add the following line to crontab to enable system as a tmux service'
	echo "@reboot ${PWD}/tmux-launch.sh"
fi

echo "#### NOTE: If this is the first time setup you will likely need to reboot your computer."
