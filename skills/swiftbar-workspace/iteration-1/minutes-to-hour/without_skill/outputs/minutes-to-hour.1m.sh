#!/bin/bash

# <swiftbar.hideAbout>true</swiftbar.hideAbout>
# <swiftbar.hideRunInTerminal>true</swiftbar.hideRunInTerminal>
# <swiftbar.hideDisablePlugin>true</swiftbar.hideDisablePlugin>

current_minute=$(date +"%M")
minutes_left=$(( 60 - 10#$current_minute ))

if [ "$minutes_left" -eq 60 ]; then
  minutes_left=0
fi

current_time=$(date +"%H:%M:%S")

# Menu bar line
echo ":clock: ${minutes_left}min"

# Dropdown
echo "---"
echo "Kellonaika: ${current_time} | size=14"
echo "Seuraavaan tasatuntiin: ${minutes_left} min | size=14"
echo "---"
echo "Päivitä | refresh=true"
