#!/bin/bash

VERSION=1.1

# Make config and log files
mkdir -p ~/.config/temp-monitor
touch ~/.config/temp-monitor/TEMP_LOG.txt
touch ~/.config/temp-monitor/TEMP_WARNING.txt

## General functions

TOP_BAR() {

	clear
	echo -e "╭───┤ \e[1;32mTemp Monitor\e[0m ├───┤ \e[1;33mVersion $VERSION\e[0m ├───────────╮"
	echo -e "│                                                │"
}

MAIN() {

	# Get the current CPU temperature (usually thermal_zone1) and divide it by 1000 because it is given back as millicelsius
	CPU_TEMP=$(( $(cat /sys/class/thermal/thermal_zone1/temp) / 1000 ))

	# Write the current date and time along with the CPU temperature to the log file
	echo "["`date +"%a %d.%m.%Y %H:%M:%S"`"]:" $CPU_TEMP"°C" >> ~/.config/temp-monitor/TEMP_LOG.txt

	# Asign the display temperature a color based on the temperature
	if (( CPU_TEMP <= 39 )); then
		TEMP_COLOR="\e[1;36m"
	elif (( CPU_TEMP >= 40 && CPU_TEMP <= 79 )); then
		TEMP_COLOR="\e[1;32m"
	else
		TEMP_COLOR="\e[1;31m"
	fi

	# Display the last checked temperature and the last time it was checked
	echo -e "│ \e[1;34mTemperature\e[0m  : $TEMP_COLOR$CPU_TEMP°C\e[0m                            │"
	echo -e "│ \e[1;34mLast checked\e[0m :" `date +"%H:%M:%S"` "                       │"
	echo -e "│                                                │"

	# Check if the current temperature is above the warning threshold
	if [ $CPU_TEMP -ge 80 ];
	then
		echo -e "│ ["`date +"%a %d.%m.%Y %H:%M:%S"`"]:" "\e[1;31mWARNING! CPU IS" $CPU_TEMP"°C\e[0m │" >> ~/.config/temp-monitor/TEMP_WARNING.txt
	fi
}

WARNINGS() {

	echo -e "├────────────────────────────────────────────────┤"
	echo -e "│                                                │"
	echo -e "│ \e[1;34mWarnings\e[0m:                                      │"
	echo -e "│                                                │"
	cat ~/.config/temp-monitor/TEMP_WARNING.txt
	echo -e "│                                                │"
}

BOTTOM_BAR() {
	echo -e "╰───┤ \e[1;31mPress CTRL+C to quit\e[0m ├─────────────────────╯"
}

## Main part

while :
do
	TOP_BAR
	MAIN
	# Just comment the parts out which you dont want, for example: #WARNINGS
	WARNINGS
	BOTTOM_BAR

	sleep 1m
done
