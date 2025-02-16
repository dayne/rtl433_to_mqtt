#!/bin/bash
# https://serverfault.com/a/670812
# github.com/gdbtek

function require_root() {
	if [ $USER != 'root' ]; then
		info "this script requires root - please run with sudo"
		exit 1
	fi
}

function have_command()
{
	info "checking for command: $1"
	which $1 > /dev/null 2>&1
	if [ $? -eq 0 ]; then
		echo "we have command: $1" && return 0
	else
		echo "missing command $1" && return 1
	fi	
}

function info()
{
    local -r message="${1}"

    echo -e "\033[1;36m${message}\033[0m" 2>&1
}

function trimString()
{
    local -r string="${1}"

    sed 's,^[[:blank:]]*,,' <<< "${string}" | sed 's,[[:blank:]]*$,,'
}

function isEmptyString()
{
    local -r string="${1}"

    if [[ "$(trimString "${string}")" = '' ]]
    then
        echo 'true' && return 0
    fi

    echo 'false' && return 1
}

function getLastAptGetUpdate()
{
    local aptDate="$(stat -c %Y '/var/cache/apt')"
    local nowDate="$(date +'%s')"

    echo $((nowDate - aptDate))
}

function runAptGetUpdate()
{
    local updateInterval="${1}"

    local lastAptGetUpdate="$(getLastAptGetUpdate)"

    if [[ "$(isEmptyString "${updateInterval}")" = 'true' ]]
    then
        # Default To 24 hours
        updateInterval="$((24 * 60 * 60))"
    fi

    if [[ "${lastAptGetUpdate}" -gt "${updateInterval}" ]]
    then
        info "apt-get update"
        sudo apt-get update -m
    else
        local lastUpdate="$(date -u -d @"${lastAptGetUpdate}" +'%-Hh %-Mm %-Ss')"

        info "\nSkip apt-get update because its last run was '${lastUpdate}' ago"
    fi
}

function checkAptPackage()
{
  local -r package="${1}"
  dpkg -s ${package} > /dev/null 2>&1
  if [ $? -eq 0 ]; then
    echo "${package} already installed"
    return 0
  else
    echo "${package} not installed"
    return 1
  fi
}

function installAptPackage()
{
  local -r package="${1}"
  checkAptPackage ${package}
  if [ $? -eq 1 ]; then
    sudo apt install ${package}
  fi
}

function installAptPackages()
{
  local -r requested_packages=${@}
  local install_packages=()
  for pkg in $requested_packages; do
    checkAptPackage ${pkg}
    if [ $? -eq 1 ]; then
      install_packages+=($pkg)
    fi
  done
  if [[ ${#install_packages} > 0 ]]; then
    packages=$(IFS=" " eval 'echo "${install_packages[*]}"')
    echo "packages that need installing: ${packages}"
    sudo apt install ${packages}
  fi
}

function setup_and_run_bundle() 
{
  if ! command -v bundle > /dev/null; then 
    echo "Error: bundle is not a command - unable to setup_and_run_bundle()"
    exit 1
  fi

  if bundle config get path | grep "You have not configured a value" > /dev/null; then
    echo "Warning: bundle does not have a local path set.  Fixing that"
     bundle config set --local path "./vendor/bundle"
  else
    echo "Skipping path set -- detected a path set for bundler already"
  fi

  bundle install
}
