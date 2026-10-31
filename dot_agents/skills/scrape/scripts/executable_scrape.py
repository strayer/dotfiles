#!/usr/bin/env python3
"""Scrape one URL to clean markdown with a small header.

Engines, chosen per URL:
- Hacker News item pages go to the free Algolia items API, rendered as an
  indented comment tree.
- Sites Firecrawl refuses (social networks) go to Linkup /fetch first.
- Everything else goes to Firecrawl /v2/scrape, falling back to Linkup /fetch
  when Firecrawl errors, returns an HTTP error status, or returns a block page.
- Reddit is refused up front: every engine only gets a login wall or CAPTCHA.

IMPORTANT: only Linkup's synchronous /v1/fetch endpoint may be used here.
Linkup's async endpoints (/research, /tasks, /extract) store every task and
expose org-wide GET listings. Do not add support for them.
"""

import argparse
import html
import json
import os
import re
import sys
import urllib.error
import urllib.parse
import urllib.request
from datetime import datetime, timezone

FIRECRAWL_URL = "https://api.firecrawl.dev/v2/scrape"
LINKUP_FETCH_URL = "https://api.linkup.so/v1/fetch"
HN_ITEM_URL = "https://hn.algolia.com/api/v1/items/{}"
TIMEOUT = 90

# Firecrawl answers these with "we do not support this site" or a
# paid-enrichment error; Linkup /fetch returns usable content for them.
LINKUP_FIRST_DOMAINS = {
    "x.com",
    "twitter.com",
    "linkedin.com",
    "instagram.com",
    "facebook.com",
    "threads.com",
    "threads.net",
    "tiktok.com",
}
REDDIT_DOMAINS = {"reddit.com", "redd.it"}

BLOCK_MARKERS = (
    "prove your humanity",
    "verify you are human",
    "blocked by network security",
    "access denied",
    "just a moment...",
    "enable javascript and cookies",
)

DATA_URI = re.compile(r"\(data:[^)]*\)")


class EngineError(Exception):
    pass


def main():
    parser = argparse.ArgumentParser(description="Single-page scraper")
    parser.add_argument("url", help="URL to scrape")
    parser.add_argument(
        "--engine",
        choices=["auto", "firecrawl", "linkup"],
        default="auto",
        help="Force an engine (default: auto routing with fallback)",
    )
    parser.add_argument(
        "--wait-for",
        type=int,
        default=0,
        metavar="MS",
        help="Firecrawl: extra delay in ms before grabbing content (JS-heavy SPAs)",
    )
    parser.add_argument(
        "--fresh",
        action="store_true",
        help="Firecrawl: bypass the 2-day cache and force a fresh scrape",
    )
    parser.add_argument(
        "--mobile", action="store_true", help="Firecrawl: emulate a mobile device"
    )
    parser.add_argument(
        "--proxy",
        choices=["basic", "enhanced", "auto"],
        default="auto",
        help="Firecrawl proxy mode (default: auto)",
    )
    parser.add_argument(
        "--include-links",
        action="store_true",
        help="Firecrawl: also include extracted links in the output",
    )
    parser.add_argument(
        "--max-chars",
        type=int,
        default=80000,
        help="Cap the content length; truncation is noted (default: 80000)",
    )
    args = parser.parse_args()

    host = hostname(args.url)

    if matches(host, REDDIT_DOMAINS):
        sys.stderr.write(
            "Reddit cannot be scraped: Firecrawl refuses the site, Linkup gets a "
            "CAPTCHA and old.reddit requires a login. Use search snippets "
            "(research with --include-domains reddit.com) instead.\n"
        )
        sys.exit(3)

    hn_id = hn_item_id(args.url)
    if hn_id and args.engine == "auto":
        try:
            print_hn_thread(hn_id, args.max_chars)
            return
        except EngineError as e:
            if "HTTP 404" in str(e):
                sys.stderr.write(f"Hacker News item {hn_id} does not exist\n")
                sys.exit(2)
            sys.stderr.write(f"Algolia failed ({e}), falling back to Firecrawl\n")

    if args.engine == "firecrawl":
        order = ["firecrawl"]
    elif args.engine == "linkup":
        order = ["linkup"]
    elif matches(host, LINKUP_FIRST_DOMAINS):
        order = ["linkup", "firecrawl"]
    else:
        order = ["firecrawl", "linkup"]

    errors = []
    for engine in order:
        try:
            page = firecrawl(args) if engine == "firecrawl" else linkup_fetch(args.url)
        except EngineError as e:
            errors.append(f"{engine}: {e}")
            continue
        if errors:
            sys.stderr.write("Fell back after: " + "; ".join(errors) + "\n")
        print_page(page, args.max_chars)
        return

    sys.stderr.write("All engines failed:\n" + "\n".join(errors) + "\n")
    sys.exit(2)


def hostname(url):
    host = (urllib.parse.urlsplit(url).hostname or "").lower()
    return host[4:] if host.startswith("www.") else host


def matches(host, domains):
    return any(host == d or host.endswith("." + d) for d in domains)


def hn_item_id(url):
    parts = urllib.parse.urlsplit(url)
    if hostname(url) != "news.ycombinator.com" or parts.path != "/item":
        return None
    ids = urllib.parse.parse_qs(parts.query).get("id") or []
    return ids[0] if ids and ids[0].isdigit() else None


def post_json(url, body, api_key):
    req = urllib.request.Request(
        url,
        data=json.dumps(body).encode("utf-8"),
        headers={
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json",
        },
        method="POST",
    )
    return send(req)


def send(req):
    try:
        with urllib.request.urlopen(req, timeout=TIMEOUT) as resp:
            return json.loads(resp.read().decode("utf-8"))
    except urllib.error.HTTPError as e:
        body_text = e.read().decode("utf-8", errors="replace")[:300]
        raise EngineError(f"HTTP {e.code}: {body_text}")
    except urllib.error.URLError as e:
        raise EngineError(f"network error: {e.reason}")
    except TimeoutError:
        raise EngineError("timed out")


def require_key(name):
    key = os.environ.get(name)
    if not key:
        raise EngineError(f"{name} is not set")
    return key


def check_block_page(markdown):
    if not markdown.strip():
        raise EngineError("empty content")
    if len(markdown) < 3000:
        lowered = markdown.lower()
        for marker in BLOCK_MARKERS:
            if marker in lowered:
                raise EngineError(f"block page ({marker!r})")


def firecrawl(args):
    api_key = require_key("FIRECRAWL_API_KEY")
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

    data = post_json(FIRECRAWL_URL, body, api_key)
    payload = data.get("data") or {}
    metadata = payload.get("metadata") or {}
    markdown = DATA_URI.sub("()", payload.get("markdown") or "")
    status = metadata.get("statusCode")
    if isinstance(status, int) and status >= 400:
        raise EngineError(f"target returned HTTP {status}")
    check_block_page(markdown)
    return {
        "engine": "firecrawl",
        "title": metadata.get("title"),
        "url": metadata.get("sourceURL") or metadata.get("url") or args.url,
        "status": status,
        "markdown": markdown,
        "links": payload.get("links") if args.include_links else None,
    }


def linkup_fetch(url):
    api_key = require_key("LINKUP_API_KEY")
    # "pro" reaches some sites "standard" cannot (and vice versa), so try both.
    errors = []
    for mode in ("standard", "pro"):
        try:
            data = post_json(
                LINKUP_FETCH_URL, {"url": url, "mode": mode, "renderJs": True}, api_key
            )
            markdown = DATA_URI.sub("()", data.get("markdown") or "")
            check_block_page(markdown)
        except EngineError as e:
            errors.append(f"{mode}: {e}")
            continue
        heading = re.search(r"^# (.+)$", markdown, re.MULTILINE)
        return {
            "engine": f"linkup-fetch ({mode})",
            "title": heading.group(1) if heading else None,
            "url": url,
            "status": None,
            "markdown": markdown,
            "links": None,
        }
    raise EngineError("; ".join(errors))


def print_page(page, max_chars):
    title = (page["title"] or "Untitled").strip().replace("\n", " ")
    print(f"# {title}")
    print(f"URL: {page['url']}")
    print(f"Engine: {page['engine']}")
    if page["status"] is not None:
        print(f"Status: {page['status']}")
    print()
    print("---")
    print()
    markdown = page["markdown"].strip()
    if len(markdown) > max_chars:
        cut = markdown.rfind("\n", 0, max_chars)
        markdown = markdown[: cut if cut > 0 else max_chars]
        markdown += (
            f"\n\n[Truncated at {max_chars} of {len(page['markdown'])} chars. "
            "Raise --max-chars for more.]"
        )
    print(markdown)

    if page["links"]:
        print()
        print("## Links")
        print()
        for link in page["links"]:
            print(f"- {link}")


def print_hn_thread(item_id, max_chars):
    item = send(urllib.request.Request(HN_ITEM_URL.format(item_id)))
    if not item or "id" not in item:
        raise EngineError("item not found")

    title = item.get("title") or f"Comment by {item.get('author')}"
    total = count_comments(item)
    meta = [f"by {item.get('author')}", short_date(item.get("created_at"))]
    if item.get("points") is not None:
        meta.insert(0, f"{item['points']} points")
    meta.append(f"{total} comments")

    print(f"# {title}")
    print(f"URL: https://news.ycombinator.com/item?id={item_id}")
    print("Engine: hn-algolia")
    if item.get("url"):
        print(f"Link: {item['url']}")
    print("Meta: " + " · ".join(m for m in meta if m))
    print()
    print("---")
    print()

    out = []
    if item.get("text"):
        out.extend([html_to_text(item["text"]), ""])
    # Algolia does not return HN's ranking; busiest subthreads first is the
    # closest proxy and keeps the most discussed parts inside the char cap.
    for child in sorted_children(item):
        render_comment(child, 0, out)

    text = "\n".join(out)
    if len(text) > max_chars:
        cut = text.rfind("\n", 0, max_chars)
        text = text[: cut if cut > 0 else max_chars]
        shown = len(re.findall(r"^\s*- \*\*", text, re.MULTILINE))
        text += (
            f"\n\n[Truncated at {max_chars} chars: {shown} of {total} comments "
            "shown. Raise --max-chars for more.]"
        )
    print(text.strip())


def count_comments(node):
    return sum(
        (1 if c.get("author") else 0) + count_comments(c)
        for c in node.get("children") or []
    )


def sorted_children(node):
    kids = [
        c for c in node.get("children") or [] if c.get("author") or c.get("children")
    ]
    return sorted(kids, key=count_comments, reverse=True)


def render_comment(node, depth, out):
    indent = "  " * depth
    if node.get("author"):
        lines = html_to_text(node.get("text") or "").splitlines() or [""]
        date = short_date(node.get("created_at"))
        out.append(f"{indent}- **{node['author']}** ({date}): {lines[0]}")
        out.extend(f"{indent}  {line}" if line else "" for line in lines[1:])
    else:
        out.append(f"{indent}- [deleted]")
    for child in sorted_children(node):
        render_comment(child, depth + 1, out)


def html_to_text(fragment):
    text = re.sub(
        r"<pre><code>(.*?)</code></pre>", r"\n```\n\1\n```\n", fragment, flags=re.S
    )
    text = re.sub(r'<a href="([^"]+)"[^>]*>.*?</a>', r"\1", text, flags=re.S)
    text = re.sub(r"</?i>", "*", text)
    text = text.replace("<p>", "\n\n")
    text = re.sub(r"<[^>]+>", "", text)
    return html.unescape(text).strip()


def short_date(iso):
    if not iso:
        return ""
    try:
        dt = datetime.fromisoformat(iso.replace("Z", "+00:00"))
    except ValueError:
        return iso
    return dt.astimezone(timezone.utc).strftime("%Y-%m-%d")


if __name__ == "__main__":
    main()
