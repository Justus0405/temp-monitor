#!/bin/bash

while : 
do
	mkdir -p ~/.config/temp-monitor
	touch ~/.config/temp-monitor/TEMP_LOG.txt
	touch ~/.config/temp-monitor/TEMP_WARNING.txt

	clear
	echo -e "\e[0m-------------------------"
	echo -e "Temp Monitor V1.0"
	echo -e "-------------------------"
	echo -e ""

	TEMP_MILLI=$(cat /sys/class/thermal/thermal_zone1/temp)
	TEMP=$(($TEMP_MILLI/1000))
	echo "["`date`"]:" $TEMP"°C" >> ~/.config/temp-monitor/TEMP_LOG.txt
	
	echo -e "Temperature  :\e[1:36m" $TEMP"°C\e[0m"
	echo -e "Last checked :" `date`
	echo -e ""

	if [ $TEMP -ge 60 ];
	then
		echo -e "["`date`"]:" "\e[1:31mWARNING! CPU IS" $TEMP"°C\e[0m" >> ~/.config/temp-monitor/TEMP_WARNING.txt
	fi

	echo -e "Warnings:"
	cat ~/.config/temp-monitor/TEMP_WARNING.txt
	sleep 1m
done
