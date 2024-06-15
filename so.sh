#!/bin/bash

get_os_version() {
	if [ -f /etc/os-release ]; then
		. /etc/os-release
		echo "$ID-$VERSION_ID"
	elif type lsb_release >/dev/null 2>&1; then
		echo "$(lsb_release -is | tr '[:upper:]' '[:lower:]')-$(lsb_release -rs)"
	elif [ -f /etc/lsb-release ]; then
		. /etc/lsb-release
		echo "$DISTRIB_ID-$DISTRIB_RELEASE"
	elif [ "$(uname)" == "Darwin" ]; then
		echo "macos-$(sw_vers -productVersion)"
	else
		echo "unknown"
	fi
}

get_wsl_version() {
	if grep -qi microsoft /proc/version; then
		if [ -f /etc/os-release ]; then
			. /etc/os-release
			echo "wsl-$ID_$VERSION_ID"
		elif type lsb_release >/dev/null 2>&1; then
			echo "wsl-$(lsb_release -is | tr '[:upper:]' '[:lower:]')_$(lsb_release -rs)"
		else
			echo "wsl-unknown"
		fi
	fi
}

if grep -qi microsoft /proc/version; then
	get_wsl_version
elif [ "$(uname)" == "Darwin" ]; then
	echo "macos-$(sw_vers -productVersion | sed 's/\./_/g')"
elif [ "$(uname)" == "Linux" ]; then
	get_os_version | sed 's/\./_/g'
elif [ "$(uname)" == "CYGWIN" ] || [ "$(uname)" == "MINGW" ] || [ "$(uname)" == "MSYS" ]; then
	echo "windows-$(cmd.exe /C ver 2>/dev/null | grep -o '[0-9]\+.[0-9]\+.[0-9]\+')"
else
	echo "unknown"
fi
