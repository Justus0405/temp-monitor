#!/usr/bin/env bash
#
# Simple temperature monitoring in bash
#
# Author: Justus0405
# Date: 31.05.2024
# License: MIT

export scriptVersion="1.2"

## USER CONFIGURATION START

export interval="1m"
export warningThreshold="80"

export configDir="${HOME}/.config/temp-monitor"
export logFile="${configDir}/temps.log"
export warningFile="${configDir}/warnings.log"

## USER CONFIGURATION STOP

### COLOR CODES ###
export black="\e[1;30m"
export red="\e[1;31m"
export green="\e[1;32m"
export yellow="\e[1;33m"
export blue="\e[1;34m"
export purple="\e[1;35m"
export cyan="\e[1;36m"
export white="\e[1;37m"
export bold="\e[1m"
export reset="\e[0m"

### FUNCTIONS ###
createEnviroment() {
	# Create config directory and files
	mkdir -p "${configDir}"
	touch "${logFile}" "${warningFile}"
}

logMessage() {
	local type=$1
	local message=$2
	case "${type}" in
	"info" | "INFO")
		echo -e "[  ${cyan}INFO${reset}  ] ${message}"
		;;
	"done" | "DONE")
		echo -e "[  ${green}DONE${reset}  ] ${message}"
		exit 0
		;;
	"warning" | "WARNING")
		echo -e "[ ${red}FAILED${reset} ] ${message}"
		;;
	"error" | "ERROR")
		echo -e "[  ${red}ERROR${reset} ] ${message}"
		exit 1
		;;
	*)
		echo -e "[UNDEFINED] ${message}"
		;;
	esac
}

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
		if [[ -f "${path}" ]]; then
			# Check if the sensor returns a valid value
			tempValue=$(cat "${path}")
			if [[ ${tempValue} =~ ^[0-9]+$ ]]; then
				tempPath="${path}"
				return 0
			fi
		fi
	done
	logMessage "error" "No valid temperature sensor found."
}

topBar() {
	clear
	echo -e "╭───┤ ${green}Temp Monitor${reset} ├───┤ ${yellow}Version ${scriptVersion}${reset} ├───────────╮"
	echo -e "│                                                │"
}

mainDashboard() {
	# Get the current CPU temperature and divide it by 1000 because it is given back as millicelsius
	cpuTemp=$(($(cat "${tempPath}") / 1000))
	# Get the current time in a specific format
	currentTime=$(date +"%a %d.%m.%Y %H:%M:%S")

	# Write the current date and time along with the CPU temperature to the log file
	echo "[${currentTime}]: ${cpuTemp}°C" >>"${logFile}"

	# Assign the display temperature a color based on the temperature
	if [[ ${cpuTemp} -le 39 ]]; then
		temperatureColor="${cyan}"
	elif [[ ${cpuTemp} -ge 40 && ${cpuTemp} -le 79 ]]; then
		temperatureColor="${green}"
	else
		temperatureColor="${red}"
	fi

	# Display the last checked temperature and the last time it was checked
	echo -e "│ ${blue}Temperature${reset}  : ${temperatureColor}${cpuTemp}°C${reset}                            │"
	echo -e "│ ${blue}Last checked${reset} : $(date +"%H:%M:%S")                        │"
	echo -e "│                                                │"

	# Check if the current temperature is above the warning threshold
	if [[ ${cpuTemp} -ge ${warningThreshold} ]]; then
		echo -e "│[${currentTime}]: ${red}WARNING! CPU IS ${cpuTemp}°C${reset} │" >>"${warningFile}"
	fi
}

warningsDashboard() {
	echo -e "├────────────────────────────────────────────────┤"
	echo -e "│                                                │"
	echo -e "│ ${blue}Warnings${reset}:                                      │"
	echo -e "│                                                │"

	if [[ -s "${warningFile}" ]]; then
		cat "${warningFile}"
	else
		echo -e "│ ${green}No warnings recorded${reset}                           │"
	fi

	echo -e "│                                                │"
}

bottomBar() {
	echo -e "╰───┤ ${red}Press CTRL+C to quit${reset} ├─────────────────────╯"
}

### PROGRAM START ###
createEnviroment
findTempPath

while :; do
	topBar
	mainDashboard
	warningsDashboard
	bottomBar

	sleep ${interval}
done
