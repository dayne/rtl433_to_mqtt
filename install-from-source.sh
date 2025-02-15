#!/bin/bash

source 'lib/apt-lib.sh'

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

install_rtl_433
