#!/usr/bin/env python3

# <bitbar.title>Hacker News Top 5</bitbar.title>
# <bitbar.version>v1.0</bitbar.version>
# <bitbar.author>ak-skills</bitbar.author>
# <bitbar.author.github>aivokone</bitbar.author.github>
# <bitbar.desc>Shows top 5 Hacker News stories in the menu bar</bitbar.desc>
# <bitbar.dependencies>python3</bitbar.dependencies>
# <swiftbar.hideAbout>true</swiftbar.hideAbout>
# <swiftbar.hideRunInTerminal>true</swiftbar.hideRunInTerminal>
# <swiftbar.hideDisablePlugin>true</swiftbar.hideDisablePlugin>

import json
import urllib.request

HN_API_BASE = "https://hacker-news.firebaseio.com/v0"
NUM_STORIES = 5


def fetch_json(url):
    """Fetch JSON from a URL using only the standard library."""
    try:
        req = urllib.request.Request(url, headers={"User-Agent": "SwiftBar-HN-Plugin/1.0"})
        with urllib.request.urlopen(req, timeout=10) as resp:
            return json.loads(resp.read().decode("utf-8"))
    except Exception:
        return None


def fetch_top_stories():
    """Fetch the top N story details from Hacker News."""
    story_ids = fetch_json(f"{HN_API_BASE}/topstories.json")
    if not story_ids:
        return []

    stories = []
    for story_id in story_ids[:NUM_STORIES]:
        item = fetch_json(f"{HN_API_BASE}/item/{story_id}.json")
        if item:
            stories.append(item)
    return stories


def truncate(text, max_length=60):
    """Truncate text to max_length, adding ellipsis if needed."""
    if len(text) <= max_length:
        return text
    return text[: max_length - 1].rstrip() + "\u2026"


def main():
    stories = fetch_top_stories()
    count = len(stories)

    # Menu bar line: HN icon + story count
    # Using the Y Combinator logo-style "Y" as the HN icon
    print(f":newspaper: {count} | symbolize=true")
    print("---")

    if not stories:
        print("Failed to load stories | color=red")
        print("---")
        print("Refresh | refresh=true")
        return

    for i, story in enumerate(stories, 1):
        title = story.get("title", "Untitled")
        url = story.get("url", f"https://news.ycombinator.com/item?id={story.get('id', '')}")
        score = story.get("score", 0)
        author = story.get("by", "unknown")
        comments = story.get("descendants", 0)

        display_title = truncate(title)
        # Main story line — clicking opens the article URL
        print(f"{display_title} | href={url} tooltip={title}")
        # Sub-line with metadata
        hn_link = f"https://news.ycombinator.com/item?id={story.get('id', '')}"
        print(f"--\u2b06 {score}  \U0001f4ac {comments}  by {author} | href={hn_link} color=#888888 size=12")

    print("---")
    print("Open Hacker News | href=https://news.ycombinator.com")
    print("Refresh | refresh=true")


if __name__ == "__main__":
    main()
