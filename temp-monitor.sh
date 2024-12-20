#!/bin/bash

# Variables
VERSION=1.2
INTERVAL=1m
WARNING_THRESHOLD=80
CONFIG_DIR="$HOME/.config/temp-monitor"
LOG_FILE="$CONFIG_DIR/TEMP_LOG.txt"
WARNING_FILE="$CONFIG_DIR/TEMP_WARNING.txt"

# Create config directory and files
mkdir -p "$CONFIG_DIR"
touch "$LOG_FILE" "$WARNING_FILE"

## General functions

# Function to find the temperature file path
FIND_TEMP_PATH() {
	local potential_paths=(
		"/sys/class/thermal/thermal_zone1/temp"
		"/sys/class/thermal/thermal_zone0/temp"
		"/sys/class/hwmon/hwmon1/temp1_input"
		"/sys/class/hwmon/hwmon0/temp1_input"
		"/sys/class/hwmon/hwmon1/temp2_input"
		"/sys/class/hwmon/hwmon0/temp2_input"
	)
	for path in "${potential_paths[@]}"; do
		if [ -f "$path" ]; then
			# Check if the sensor returns a valid value
			temp_value=$(cat "$path")
			if [[ $temp_value =~ ^[0-9]+$ ]]; then
				TEMP_PATH="$path"
				return 0
			fi
		fi
	done
	echo -e "\e[1;31mError:\e[0m No valid temperature sensor found"
	exit 1
}

TOP_BAR() {

	clear
	echo -e "╭───┤ \e[1;32mTemp Monitor\e[0m ├───┤ \e[1;33mVersion $VERSION\e[0m ├───────────╮"
	echo -e "│                                                │"
}

MAIN() {

	# Get the current CPU temperature and divide it by 1000 because it is given back as millicelsius
	CPU_TEMP=$(($(cat "$TEMP_PATH") / 1000))
	# Get the curremt time in a specific format
	CURRENT_TIME=$(date +"%a %d.%m.%Y %H:%M:%S")

	# Write the current date and time along with the CPU temperature to the log file
	echo "[$CURRENT_TIME]:" $CPU_TEMP"°C" >>"$LOG_FILE"

	# Asign the display temperature a color based on the temperature
	if ((CPU_TEMP <= 39)); then
		TEMP_COLOR="\e[1;36m"
	elif ((CPU_TEMP >= 40 && CPU_TEMP <= 79)); then
		TEMP_COLOR="\e[1;32m"
	else
		TEMP_COLOR="\e[1;31m"
	fi

	# Display the last checked temperature and the last time it was checked
	echo -e "│ \e[1;34mTemperature\e[0m  : $TEMP_COLOR$CPU_TEMP°C\e[0m                            │"
	echo -e "│ \e[1;34mLast checked\e[0m : $(date +"%H:%M:%S")                        │"
	echo -e "│                                                │"

	# Check if the current temperature is above the warning threshold
	if ((CPU_TEMP >= WARNING_THRESHOLD)); then
		echo -e "│ [$CURRENT_TIME]:" "\e[1;31mWARNING! CPU IS" $CPU_TEMP"°C\e[0m │" >>"$WARNING_FILE"
	fi
}

WARNINGS() {
	echo -e "├────────────────────────────────────────────────┤"
	echo -e "│                                                │"
	echo -e "│ \e[1;34mWarnings\e[0m:                                      │"
	echo -e "│                                                │"

	if [ -s "$WARNING_FILE" ]; then
		cat "$WARNING_FILE"
	else
		echo -e "│ \e[1;32mNo warnings recorded\e[0m                           │"
	fi

	echo -e "│                                                │"
}

BOTTOM_BAR() {
	echo -e "╰───┤ \e[1;31mPress CTRL+C to quit\e[0m ├─────────────────────╯"
}

## Main part

FIND_TEMP_PATH

while :; do
	TOP_BAR
	MAIN
	WARNINGS
	BOTTOM_BAR

	sleep $INTERVAL
done
