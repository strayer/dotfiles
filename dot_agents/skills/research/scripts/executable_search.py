#!/usr/bin/env python3
"""Call Linkup /search with outputType=sourcedAnswer and emit ready-to-paste markdown."""

import argparse
import json
import os
import sys
import urllib.error
import urllib.request

API_URL = "https://api.linkup.so/v1/search"
TIMEOUT = 120

MISSING_KEY_HINT = (
    "Error: LINKUP_API_KEY is not set.\n"
    "Export it in the environment before invoking this script.\n"
    "Get a key at https://app.linkup.so.\n"
)


def main():
    parser = argparse.ArgumentParser(
        description="Linkup /search wrapper (sourcedAnswer)"
    )
    parser.add_argument(
        "query", help="Natural language query (write it as a research brief)"
    )
    parser.add_argument(
        "--depth",
        choices=["fast", "standard", "deep"],
        default="standard",
        help="Search depth (default: standard)",
    )
    parser.add_argument(
        "--include-images", action="store_true", help="Include images in sources"
    )
    args = parser.parse_args()

    api_key = os.environ.get("LINKUP_API_KEY")
    if not api_key:
        sys.stderr.write(MISSING_KEY_HINT)
        sys.exit(1)

    body = {
        "q": args.query,
        "depth": args.depth,
        "outputType": "sourcedAnswer",
        "includeInlineCitations": True,
        "includeImages": args.include_images,
    }
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
        sys.stderr.write(f"Linkup API error {e.code}: {body_text}\n")
        sys.exit(2)
    except urllib.error.URLError as e:
        sys.stderr.write(f"Network error: {e.reason}\n")
        sys.exit(2)

    print_sourced_answer(data)


def print_sourced_answer(data):
    answer = data.get("answer", "")
    sources = data.get("sources", []) or []

    if not answer and not sources:
        print(json.dumps(data, indent=2, ensure_ascii=False))
        return

    # Linkup already emits [1][2]-style inline markers. Leave them as plain
    # numeric citations — markdown footnote syntax ([^1]) does not render in
    # most terminal markdown renderers (including Claude Code's).
    print(answer.strip())

    if not sources:
        return

    print()
    print("## Sources")
    print()
    for i, src in enumerate(sources, 1):
        name = (src.get("name") or "Source").strip().replace("\n", " ")
        url = src.get("url", "")
        print(f"[{i}] [{name}]({url})")


if __name__ == "__main__":
    main()
