#!/bin/bash
# Fetch the model-scoped weekly limit from the claude.ai OAuth usage
# endpoint - the same data the /usage screen and the web UI show.
# Undocumented endpoint; on any failure falls back to the last cached
# value. Prints "<percent> <model> <resets-at>".

CACHE=~/.claude/cache/scoped-quota-cache
TTL=300

if [ -f "$CACHE" ] && [ $(( $(date +%s) - $(stat -c %Y "$CACHE") )) -lt $TTL ]; then
  cat "$CACHE"
  exit 0
fi

out=$(python3 - <<'EOF' 2>/dev/null
import json, os, urllib.request
tok = json.load(open(os.path.expanduser(
    '~/.claude/.credentials.json')))['claudeAiOauth']['accessToken']
req = urllib.request.Request(
    'https://api.anthropic.com/api/oauth/usage',
    headers={'Authorization': f'Bearer {tok}',
             'anthropic-beta': 'oauth-2025-04-20'})
d = json.load(urllib.request.urlopen(req, timeout=5))
for lim in d.get('limits', []):
    model = ((lim.get('scope') or {}).get('model') or {}).get('display_name')
    if lim.get('kind') == 'weekly_scoped' and model:
        print(f"{lim['percent']} {model} {(lim.get('resets_at') or '')[:16]}")
        break
EOF
)

mkdir -p ~/.claude/cache
if [ -n "$out" ]; then
  printf '%s' "$out" | tee "$CACHE"
else
  cat "$CACHE" 2>/dev/null
fi
