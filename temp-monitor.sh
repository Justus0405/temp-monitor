#!/bin/bash

# Variables
version="1.2"
interval="1m"
warningThreshold="80"
configDir="$HOME/.config/temp-monitor"
logFile="$configDir/temps.log"
warningFile="$configDir/warnings.log"

# Create config directory and files
mkdir -p "$configDir"
touch "$logFile" "$warningFile"

## General functions

# Function to find the temperature file path
findTempPath() {
	local potentialPaths=(
		"/sys/class/thermal/thermal_zone0/temp"
		"/sys/class/thermal/thermal_zone1/temp"
		"/sys/class/hwmon/hwmon0/temp1_input"
		"/sys/class/hwmon/hwmon1/temp1_input"
		"/sys/class/hwmon/hwmon0/temp2_input"
		"/sys/class/hwmon/hwmon1/temp2_input"
	)
	for path in "${potentialPaths[@]}"; do
		if [[ -f "$path" ]]; then
			# Check if the sensor returns a valid value
			tempValue=$(cat "$path")
			if [[ $tempValue =~ ^[0-9]+$ ]]; then
				tempPath="$path"
				return 0
			fi
		fi
	done
	echo -e "\e[1;31mError:\e[0m No valid temperature sensor found"
	exit 1
}

topBar() {
	clear
	echo -e "╭───┤ \e[1;32mTemp Monitor\e[0m ├───┤ \e[1;33mVersion $version\e[0m ├───────────╮"
	echo -e "│                                                │"
}

mainDashboard() {

	# Get the current CPU temperature and divide it by 1000 because it is given back as millicelsius
	cpuTemp=$(($(cat "$tempPath") / 1000))
	# Get the current time in a specific format
	currentTime=$(date +"%a %d.%m.%Y %H:%M:%S")

	# Write the current date and time along with the CPU temperature to the log file
	echo "[$currentTime]: $cpuTemp°C" >>"$logFile"

	# Assign the display temperature a color based on the temperature
	if ((cpuTemp <= 39)); then
		tempColor="\e[1;36m"
	elif ((cpuTemp >= 40 && cpuTemp <= 79)); then
		tempColor="\e[1;32m"
	else
		tempColor="\e[1;31m"
	fi

	# Display the last checked temperature and the last time it was checked
	echo -e "│ \e[1;34mTemperature\e[0m  : $tempColor$cpuTemp°C\e[0m                            │"
	echo -e "│ \e[1;34mLast checked\e[0m : $(date +"%H:%M:%S")                        │"
	echo -e "│                                                │"

	# Check if the current temperature is above the warning threshold
	if ((cpuTemp >= warningThreshold)); then
		echo -e "│[$currentTime]: \e[1;31mWARNING! CPU IS $cpuTemp°C\e[0m │" >>"$warningFile"
	fi
}

warningsDashboard() {
	echo -e "├────────────────────────────────────────────────┤"
	echo -e "│                                                │"
	echo -e "│ \e[1;34mWarnings\e[0m:                                      │"
	echo -e "│                                                │"

	if [[ -s "$warningFile" ]]; then
		cat "$warningFile"
	else
		echo -e "│ \e[1;32mNo warnings recorded\e[0m                           │"
	fi

	echo -e "│                                                │"
}

bottomBar() {
	echo -e "╰───┤ \e[1;31mPress CTRL+C to quit\e[0m ├─────────────────────╯"
}

# PROGRAM START

findTempPath

while :; do
	topBar
	mainDashboard
	warningsDashboard
	bottomBar

	sleep $interval
done
