# SwiftBar Plugin Patterns

Practical examples for common plugin patterns. Read the relevant section when building a specific type of plugin.

## Dark/Light Mode

Use `OS_APPEARANCE` or the dual-color syntax:

```bash
#!/bin/bash
# Dual-color (light,dark)
echo "Status | color=black,white sfimage=circle.fill sfcolor=#333333,#cccccc"
```

```bash
#!/bin/bash
if [ "$OS_APPEARANCE" = "Dark" ]; then
    ICON_COLOR="#cccccc"
else
    ICON_COLOR="#333333"
fi
echo "Status | color=$ICON_COLOR"
```

## Self-Refreshing Actions

The `terminal=false refresh=true` combo runs an action silently and then re-executes the plugin to update the display:

```bash
echo "---"
echo "Mark as Done | bash=$0 param0=complete terminal=false refresh=true"

# Handle the action
if [ "$1" = "complete" ]; then
    echo "done" > "$SWIFTBAR_PLUGIN_DATA_PATH/status.txt"
    exit 0
fi
```

## Error Handling

Show errors gracefully in the menu bar instead of crashing:

```bash
#!/bin/bash
result=$(curl -sf "https://api.example.com/data" 2>/dev/null) || {
    echo "⚠ API Error | color=red sfimage=exclamationmark.triangle"
    echo "---"
    echo "Could not reach API | color=gray"
    echo "Retry | refresh=true"
    exit 0
}

echo "OK: $result"
```

Always exit 0 and show the error in the menu — exit 1 gives a generic SwiftBar warning that isn't helpful to the user.

## Persistent State

Use `SWIFTBAR_PLUGIN_DATA_PATH` for state that survives restarts, and `SWIFTBAR_PLUGIN_CACHE_PATH` for temporary data:

```bash
#!/bin/bash
DATA_DIR="${SWIFTBAR_PLUGIN_DATA_PATH:-/tmp}"

# Read state
count=$(cat "$DATA_DIR/count.txt" 2>/dev/null || echo "0")
echo "Count: $count | sfimage=number.circle"
echo "---"
echo "Increment | bash=$0 param0=inc terminal=false refresh=true"
echo "Reset | bash=$0 param0=reset terminal=false refresh=true"

# Handle actions
case "$1" in
    inc)   echo $(( count + 1 )) > "$DATA_DIR/count.txt" ;;
    reset) echo "0" > "$DATA_DIR/count.txt" ;;
esac
```

## Python Plugin with API Call

```python
#!/usr/bin/env python3

# <xbar.title>Weather</xbar.title>
# <xbar.desc>Shows current weather</xbar.desc>
# <xbar.author>Author</xbar.author>
# <swiftbar.environment>[CITY=Helsinki, API_KEY=]</swiftbar.environment>

import json
import os
import urllib.request

CITY = os.environ.get("CITY", "Helsinki")
API_KEY = os.environ.get("API_KEY", "")
CACHE = os.environ.get("SWIFTBAR_PLUGIN_CACHE_PATH", "/tmp")

def fetch_weather():
    if not API_KEY:
        return None
    url = f"https://api.openweathermap.org/data/2.5/weather?q={CITY}&appid={API_KEY}&units=metric"
    try:
        with urllib.request.urlopen(url, timeout=10) as resp:
            return json.loads(resp.read())
    except Exception:
        return None

data = fetch_weather()
if data is None:
    print("🌡 -- | sfimage=thermometer.medium")
    print("---")
    if not API_KEY:
        print("Set API_KEY in plugin settings | color=orange")
    else:
        print("Could not fetch weather | color=red")
        print("Retry | refresh=true")
else:
    temp = round(data["main"]["temp"])
    desc = data["weather"][0]["description"].title()
    print(f"🌡 {temp}°C | sfimage=thermometer.medium")
    print("---")
    print(f"{desc} in {CITY} | size=14")
    print(f"Feels like: {data['main']['feels_like']:.0f}°C")
    print(f"Humidity: {data['main']['humidity']}%")
    print("---")
    print("Refresh | refresh=true")
```

## Streamable Plugin (Live Updates)

For real-time data like clocks, monitoring, or websocket feeds:

```bash
#!/bin/bash

# <xbar.title>Live Clock</xbar.title>
# <swiftbar.type>streamable</swiftbar.type>

while true; do
    echo "$(date +%H:%M:%S) | font=Menlo size=13"
    echo "---"
    echo "$(date '+%A, %B %d %Y')"
    echo "~~~"
    sleep 1
done
```

The `~~~` separator tells SwiftBar to redraw the menu with the new output.

## Option-Key Alternates

Show different items when the user holds the Option key:

```bash
echo "Open Dashboard | href=https://app.example.com"
echo "Open Admin Panel | alternate=true href=https://admin.example.com"
echo "---"
echo "View Logs | bash=/usr/bin/open param0=~/logs/"
echo "Clear Logs | alternate=true bash=$0 param0=clear-logs terminal=false refresh=true"
```

## Triggering Refresh from Outside

Other scripts or cron jobs can trigger a plugin refresh:

```bash
# Refresh a specific plugin (by name, without extension/interval)
open -g "swiftbar://refreshplugin?name=my-plugin"

# Refresh all plugins
open -g "swiftbar://refreshallplugins"
```

The `-g` flag prevents SwiftBar from coming to the foreground.

## Notifications

Send macOS notifications from a plugin or external script:

```bash
open -g "swiftbar://notify?plugin=my-plugin&title=Build%20Complete&subtitle=Project%20X&body=All%20tests%20passed"
```

## Badges

Add a count badge to a menu item:

```bash
echo "Inbox | badge=5"
echo "--Message 1 | href=https://mail.example.com/1"
echo "--Message 2 | href=https://mail.example.com/2"
```

## Full Bash Template

A complete starting point for a new bash plugin:

```bash
#!/bin/bash

# <xbar.title>My Plugin</xbar.title>
# <xbar.version>v1.0</xbar.version>
# <xbar.author>Your Name</xbar.author>
# <xbar.author.github>username</xbar.author.github>
# <xbar.desc>Short description</xbar.desc>
# <swiftbar.hideAbout>true</swiftbar.hideAbout>
# <swiftbar.hideRunInTerminal>true</swiftbar.hideRunInTerminal>
# <swiftbar.hideLastUpdated>true</swiftbar.hideLastUpdated>

DATA_DIR="${SWIFTBAR_PLUGIN_DATA_PATH:-/tmp}"

# Handle click actions
case "$1" in
    action1)
        # do something
        exit 0
        ;;
    action2)
        # do something else
        exit 0
        ;;
esac

# Header (menu bar)
echo "Status OK | sfimage=checkmark.circle color=green"

# Dropdown
echo "---"
echo "Details | size=14 font=Menlo"
echo "--Sub-item 1 | href=https://example.com"
echo "--Sub-item 2 | bash=$0 param0=action1 terminal=false refresh=true"
echo "---"
echo "Refresh | refresh=true"
```

## Full Python Template

```python
#!/usr/bin/env python3

# <xbar.title>My Plugin</xbar.title>
# <xbar.version>v1.0</xbar.version>
# <xbar.author>Your Name</xbar.author>
# <xbar.desc>Short description</xbar.desc>
# <swiftbar.hideAbout>true</swiftbar.hideAbout>
# <swiftbar.hideRunInTerminal>true</swiftbar.hideRunInTerminal>
# <swiftbar.hideLastUpdated>true</swiftbar.hideLastUpdated>

import os
import sys

DATA_DIR = os.environ.get("SWIFTBAR_PLUGIN_DATA_PATH", "/tmp")
PLUGIN_PATH = os.environ.get("SWIFTBAR_PLUGIN_PATH", sys.argv[0])

def main():
    # Handle click actions
    if len(sys.argv) > 1:
        action = sys.argv[1]
        if action == "action1":
            # do something
            return
        elif action == "action2":
            # do something else
            return

    # Header (menu bar)
    print("Status OK | sfimage=checkmark.circle color=green")

    # Dropdown
    print("---")
    print("Details | size=14")
    print(f"--Action 1 | bash={PLUGIN_PATH} param0=action1 terminal=false refresh=true")
    print(f"--Action 2 | bash={PLUGIN_PATH} param0=action2 terminal=false refresh=true")
    print("---")
    print("Refresh | refresh=true")

if __name__ == "__main__":
    main()
```
