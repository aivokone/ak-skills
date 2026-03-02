#!/usr/bin/env python3

# <xbar.title>Hacker News Top 5</xbar.title>
# <xbar.version>v1.0</xbar.version>
# <xbar.author>ak-skills</xbar.author>
# <xbar.desc>Shows the top 5 Hacker News stories in the menu bar dropdown</xbar.desc>
# <xbar.dependencies>python3</xbar.dependencies>
# <swiftbar.hideAbout>true</swiftbar.hideAbout>
# <swiftbar.hideRunInTerminal>true</swiftbar.hideRunInTerminal>
# <swiftbar.hideLastUpdated>true</swiftbar.hideLastUpdated>

import json
import urllib.request

HN_TOP_URL = "https://hacker-news.firebaseio.com/v0/topstories.json"
HN_ITEM_URL = "https://hacker-news.firebaseio.com/v0/item/{}.json"
NUM_STORIES = 5


def fetch_json(url):
    with urllib.request.urlopen(url, timeout=10) as resp:
        return json.loads(resp.read())


def fetch_top_stories():
    top_ids = fetch_json(HN_TOP_URL)[:NUM_STORIES]
    stories = []
    for story_id in top_ids:
        item = fetch_json(HN_ITEM_URL.format(story_id))
        if item:
            stories.append(item)
    return stories


def main():
    try:
        stories = fetch_top_stories()
    except Exception:
        print("HN ? | sfimage=newspaper color=red,#ff6666")
        print("---")
        print("Could not load Hacker News | color=gray")
        print("Refresh | refresh=true")
        return

    count = len(stories)
    print(f"HN {count} | sfimage=newspaper sfcolor=#ff6600")
    print("---")
    print("Hacker News — Top 5 | size=14 color=#ff6600")
    print("---")

    for i, story in enumerate(stories, 1):
        title = story.get("title", "Untitled")
        url = story.get("url", f"https://news.ycombinator.com/item?id={story['id']}")
        points = story.get("score", 0)
        comments = story.get("descendants", 0)
        hn_link = f"https://news.ycombinator.com/item?id={story['id']}"

        # Escape pipe characters in the title so SwiftBar doesn't misparse
        title = title.replace("|", "-")

        print(f"{i}. {title} | href={url} tooltip={points} pts / {comments} comments length=60")
        print(f"--{points} pts / {comments} comments | color=gray size=12 href={hn_link}")

    print("---")
    print("Open Hacker News | href=https://news.ycombinator.com sfimage=safari color=#ff6600")
    print("Refresh | refresh=true sfimage=arrow.clockwise")


if __name__ == "__main__":
    main()
