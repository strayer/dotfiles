#!/usr/bin/env python3
"""Search Hacker News through the free Algolia API and list matching items.

Read a thread with the scrape skill: scrape.py renders news.ycombinator.com
item URLs as a full comment tree.
"""

import argparse
import html
import json
import re
import sys
import urllib.error
import urllib.parse
import urllib.request
from datetime import datetime, timezone

API_URL = "https://hn.algolia.com/api/v1/{}"
TIMEOUT = 30


def main():
    parser = argparse.ArgumentParser(description="Hacker News search (Algolia)")
    parser.add_argument("query", help="Keyword query (Algolia full-text, not prose)")
    parser.add_argument(
        "--type",
        choices=["story", "comment", "all"],
        default="story",
        help="Item type to search (default: story)",
    )
    parser.add_argument(
        "--sort",
        choices=["relevance", "date"],
        default="relevance",
        help="Rank by relevance (points weigh in) or newest first",
    )
    parser.add_argument("--min-points", type=int, help="Only items with >= N points")
    parser.add_argument(
        "--min-comments", type=int, help="Only stories with >= N comments"
    )
    parser.add_argument("--from-date", metavar="YYYY-MM-DD")
    parser.add_argument("--to-date", metavar="YYYY-MM-DD")
    parser.add_argument(
        "--limit", type=int, default=10, help="Number of hits (default: 10)"
    )
    args = parser.parse_args()

    filters = []
    if args.min_points is not None:
        filters.append(f"points>={args.min_points}")
    if args.min_comments is not None:
        filters.append(f"num_comments>={args.min_comments}")
    if args.from_date:
        filters.append(f"created_at_i>={epoch(args.from_date)}")
    if args.to_date:
        filters.append(f"created_at_i<{epoch(args.to_date) + 86400}")

    # Algolia's defaults (prefix matching on the last word, typo tolerance)
    # turn short product names into noise: "unifi" matches "unified".
    params = {
        "query": args.query,
        "hitsPerPage": args.limit,
        "queryType": "prefixNone",
        "typoTolerance": "false",
    }
    if args.type != "all":
        params["tags"] = args.type
    if filters:
        params["numericFilters"] = ",".join(filters)

    endpoint = "search" if args.sort == "relevance" else "search_by_date"
    url = API_URL.format(endpoint) + "?" + urllib.parse.urlencode(params)
    try:
        with urllib.request.urlopen(url, timeout=TIMEOUT) as resp:
            data = json.loads(resp.read().decode("utf-8"))
    except urllib.error.HTTPError as e:
        sys.stderr.write(f"Algolia API error {e.code}: {e.read()[:300]!r}\n")
        sys.exit(2)
    except urllib.error.URLError as e:
        sys.stderr.write(f"Network error: {e.reason}\n")
        sys.exit(2)

    hits = data.get("hits") or []
    print(f"{data.get('nbHits', 0)} matches, showing {len(hits)}")
    if not hits:
        print(
            "Every word must match: retry with fewer or broader keywords, "
            "or loosen the filters."
        )
    for hit in hits:
        print()
        print_hit(hit)


def epoch(day):
    dt = datetime.strptime(day, "%Y-%m-%d").replace(tzinfo=timezone.utc)
    return int(dt.timestamp())


def print_hit(hit):
    item_url = f"https://news.ycombinator.com/item?id={hit['objectID']}"
    date = (hit.get("created_at") or "")[:10]
    if hit.get("title"):
        print(f"- {hit['title']}")
        print(
            f"  {hit.get('points') or 0} points · {hit.get('num_comments') or 0} "
            f"comments · {date} · {item_url}"
        )
        if hit.get("url"):
            print(f"  Link: {hit['url']}")
        if hit.get("story_text"):
            print(f"  Text: {snippet(highlighted(hit, 'story_text'))}")
    else:
        story_url = f"https://news.ycombinator.com/item?id={hit.get('story_id')}"
        print(f"- Comment by {hit.get('author')} on \"{hit.get('story_title')}\"")
        print(f"  {date} · {item_url} · thread: {story_url}")
        print(f"  {snippet(highlighted(hit, 'comment_text'))}")


def highlighted(hit, field):
    """Return the field's text with the first match marked by MATCH_MARK."""
    marked = ((hit.get("_highlightResult") or {}).get(field) or {}).get("value")
    if not marked:
        return hit.get(field) or ""
    return marked.replace("<em>", MATCH_MARK, 1).replace("<em>", "").replace("</em>", "")


MATCH_MARK = "\x00"


def snippet(fragment, limit=300):
    """Plain-text excerpt of an HTML fragment, centred on the first match."""
    text = html.unescape(re.sub(r"<[^>]+>", " ", fragment))
    text = re.sub(r"\s+", " ", text).strip()
    start = max(text.find(MATCH_MARK) - limit // 3, 0)
    text = text.replace(MATCH_MARK, "")
    if len(text) <= limit:
        return text
    excerpt = text[start : start + limit - 2]
    return ("…" if start else "") + excerpt + ("…" if start + limit - 2 < len(text) else "")


if __name__ == "__main__":
    main()
