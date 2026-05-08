#!/usr/bin/env python3
"""Call Firecrawl /v2/scrape and emit clean markdown with a small header."""

import argparse
import json
import os
import sys
import urllib.error
import urllib.request

API_URL = "https://api.firecrawl.dev/v2/scrape"
TIMEOUT = 90

MISSING_KEY_HINT = (
    "Error: FIRECRAWL_API_KEY not set.\n"
    'Add it to the "env" block of ~/.claude/settings.json:\n'
    '  "env": { "FIRECRAWL_API_KEY": "fc-..." }\n'
    "Get a key at https://firecrawl.dev, then restart Claude Code.\n"
)


def main():
    parser = argparse.ArgumentParser(description="Firecrawl /v2/scrape wrapper")
    parser.add_argument("url", help="URL to scrape")
    parser.add_argument(
        "--wait-for",
        type=int,
        default=0,
        metavar="MS",
        help="Extra delay in ms before grabbing content (for JS-heavy SPAs)",
    )
    parser.add_argument(
        "--fresh",
        action="store_true",
        help="Bypass Firecrawl's 2-day cache and force a fresh scrape",
    )
    parser.add_argument("--mobile", action="store_true", help="Emulate a mobile device")
    parser.add_argument(
        "--proxy",
        choices=["basic", "enhanced", "auto"],
        default="auto",
        help="Proxy mode (default: auto). Use 'enhanced' for 403/anti-bot retries.",
    )
    parser.add_argument(
        "--include-links",
        action="store_true",
        help="Also include extracted links in the output",
    )
    args = parser.parse_args()

    api_key = os.environ.get("FIRECRAWL_API_KEY")
    if not api_key:
        sys.stderr.write(MISSING_KEY_HINT)
        sys.exit(1)

    formats = ["markdown"]
    if args.include_links:
        formats.append("links")

    body = {
        "url": args.url,
        "formats": formats,
        "onlyMainContent": True,
        "proxy": args.proxy,
    }
    if args.wait_for:
        body["waitFor"] = args.wait_for
    if args.fresh:
        body["maxAge"] = 0
    if args.mobile:
        body["mobile"] = True

    req = urllib.request.Request(
        API_URL,
        data=json.dumps(body).encode("utf-8"),
        headers={
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json",
        },
        method="POST",
    )
    try:
        with urllib.request.urlopen(req, timeout=TIMEOUT) as resp:
            data = json.loads(resp.read().decode("utf-8"))
    except urllib.error.HTTPError as e:
        body_text = e.read().decode("utf-8", errors="replace")[:500]
        sys.stderr.write(f"Firecrawl API error {e.code}: {body_text}\n")
        sys.exit(2)
    except urllib.error.URLError as e:
        sys.stderr.write(f"Network error: {e.reason}\n")
        sys.exit(2)

    print_scrape(data, include_links=args.include_links)


def print_scrape(data, include_links=False):
    payload = data.get("data") or {}
    markdown = payload.get("markdown")
    metadata = payload.get("metadata") or {}

    if not markdown:
        print(json.dumps(data, indent=2, ensure_ascii=False))
        return

    title = (metadata.get("title") or "Untitled").strip().replace("\n", " ")
    source_url = metadata.get("sourceURL") or metadata.get("url") or ""
    status = metadata.get("statusCode")

    print(f"# {title}")
    if source_url:
        print(f"URL: {source_url}")
    if status is not None:
        print(f"Status: {status}")
    print()
    print("---")
    print()
    print(markdown.strip())

    if include_links:
        links = payload.get("links") or []
        if links:
            print()
            print("## Links")
            print()
            for link in links:
                print(f"- {link}")


if __name__ == "__main__":
    main()
