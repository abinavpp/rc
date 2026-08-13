#!/bin/bash
input=$(cat)
model=$(echo "$input" | jq -r '.model.display_name')
ctx=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
rate_5h=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
rate_7d=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')
reset_5h=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
effort=$(echo "$input" | jq -r '.effort.level // empty')
# session_name is auto-derived from the first prompt, so it can be a whole
# sentence; it gets whatever width is left over, full text in the terminal
# title.
tag=$(echo "$input" | jq -r '.session_name // .worktree.name // .workspace.git_worktree // empty')

# Red flags the expensive tier; everything cheaper is green.
case "${model,,}" in
  fable*) c=$'\e[1;31m' ;;
  *)      c=$'\e[1;32m' ;;
esac
line="${c}${model}${effort:+ ($effort)}"$'\e[0m'

pct() {
  if [ "$(printf '%.0f' "$1")" -gt 90 ]; then
    printf '\e[1;31m%.0f%%\e[0m' "$1"
  else
    printf '%.0f%%' "$1"
  fi
}

# The 5h window is rolling - it starts at its own first message, so time
# left can't be inferred from the clock the way the weekly one can. It
# replaces the "5h" label; falls back to it when resets_at is missing.
countdown() {
  local left=$(( $1 - $(date +%s) ))
  [ "$left" -le 0 ] && return
  if [ "$left" -ge 3600 ]; then
    printf '%dh%02dm' $(( left / 3600 )) $(( left % 3600 / 60 ))
  else
    printf '%dm' $(( (left + 59) / 60 ))
  fi
}

# Every meter reads as "used", so the red-above-90 rule means the same
# thing across the whole line.
[ -n "$ctx" ] && line="$line | ctx: $(pct "$ctx")"

# Every meter is omitted when its data is unavailable. 5h/7d come from
# the harness JSON; the model-scoped weekly cap comes from the claude.ai
# usage endpoint (the number the web UI shows; not in the harness JSON)
# via ~/.claude/scoped-quota.sh.
quota=()
if [ -n "$rate_5h" ]; then
  window=${reset_5h:+$(countdown "$reset_5h")}
  quota+=("$(pct "$rate_5h") of ${window:-5h}")
fi
[ -n "$rate_7d" ] && quota+=("$(pct "$rate_7d") of 7d")
scoped=$(~/.claude/scoped-quota.sh 2>/dev/null)
if [ -n "$scoped" ]; then
  quota+=("$(pct "$(echo "$scoped" | cut -d' ' -f1)") of 7d-$(echo "$scoped" | cut -d' ' -f2)")
fi
if [ ${#quota[@]} -gt 0 ]; then
  qstr=""
  for q in "${quota[@]}"; do qstr+="${qstr:+, }$q"; done
  line="$line | lim: $qstr"
fi

# The tag is flush right, minus the columns the harness keeps for its own
# right-aligned "/rc active" badge. No tty on stdin here, so width comes
# from /dev/tty; without it padding would wrap, so fall back to the left.
if [ -n "$tag" ]; then
  cols=${COLUMNS:-$(tput cols </dev/tty 2>/dev/null)}
  bare=$(printf '%s' "$line" | sed 's/\x1b\[[0-9;]*m//g')
  room=$(( ${cols:-0} - ${#bare} - 14 ))
  if [ "$room" -ge 12 ]; then
    tag=${tag:0:$(( room - 2 ))}
    pad=$(( room - ${#tag} ))
    line="$line$(printf '%*s' "$pad" '')"$'\e[1;36m'"$tag"$'\e[0m'
  else
    line=$'\e[1;36m'"${tag:0:24}"$'\e[0m | '"$line"
  fi
fi

printf "%s" "$line"
