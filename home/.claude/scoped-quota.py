#!/usr/bin/env python3
# Prints the model-scoped weekly limit, from the undocumented claude.ai usage
# endpoint behind /usage.
import json
import time
import urllib.request
from pathlib import Path

CACHE = Path.home() / ".claude/cache/scoped-quota-cache"
CREDS = Path.home() / ".claude/.credentials.json"
TTL = 300


def fetch():
    tok = json.loads(CREDS.read_text())["claudeAiOauth"]["accessToken"]
    req = urllib.request.Request(
        "https://api.anthropic.com/api/oauth/usage",
        headers={
            "Authorization": f"Bearer {tok}",
            "anthropic-beta": "oauth-2025-04-20",
        },
    )
    d = json.load(urllib.request.urlopen(req, timeout=5))
    for lim in d.get("limits", []):
        model = ((lim.get("scope") or {}).get("model") or {}).get("display_name")
        if lim.get("kind") == "weekly_scoped" and model:
            return f"{lim['percent']} {model} {(lim.get('resets_at') or '')[:16]}"
    return None


def cached():
    try:
        return CACHE.read_text()
    except OSError:
        return ""


def main():
    if CACHE.exists() and time.time() - CACHE.stat().st_mtime < TTL:
        print(cached(), end="")
        return
    try:
        out = fetch()
    except Exception:
        out = None
    if not out:
        print(cached(), end="")
        return
    CACHE.parent.mkdir(parents=True, exist_ok=True)
    CACHE.write_text(out)
    print(out, end="")


main()
