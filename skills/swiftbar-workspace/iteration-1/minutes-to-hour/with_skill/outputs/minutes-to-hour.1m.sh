#!/bin/bash

# <xbar.title>Minutes to Hour</xbar.title>
# <xbar.version>v1.0</xbar.version>
# <xbar.author>ak-skills</xbar.author>
# <xbar.desc>Shows minutes remaining until the next full hour</xbar.desc>
# <swiftbar.hideAbout>true</swiftbar.hideAbout>
# <swiftbar.hideRunInTerminal>true</swiftbar.hideRunInTerminal>
# <swiftbar.hideLastUpdated>true</swiftbar.hideLastUpdated>

current_minute=$(date +%-M)
minutes_left=$(( 60 - current_minute ))

# At exactly :00, minutes_left=60, meaning 60 min to next full hour

current_time=$(date +%H:%M)

# Header (menu bar)
echo ":${minutes_left}min | sfimage=clock"

# Dropdown
echo "---"
echo "Kellonaika: ${current_time} | size=14"
echo "---"
echo "Refresh | refresh=true"
