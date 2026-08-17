#!/bin/bash
# Last exchange of a transcript, one line: what I asked -> what came back.
# argv: <transcript.jsonl> <columns>
f=$1
cols=${2:-0}
[ -r "$f" ] || exit 0
[ "$cols" -ge 40 ] 2>/dev/null || exit 0

# Bump on any change to the extraction below, or old sessions keep serving
# text cleaned by the previous rules.
stamp="v3 $(stat -c '%s %Y' "$f")"
cache=${XDG_CACHE_HOME:-$HOME/.cache}/claude-recap
mkdir -p "$cache"
c="$cache/$(basename "$f" .jsonl)"

gen=""
[ "$(head -n1 "$c.line" 2>/dev/null)" = "v2" ] &&
  gen=$(sed -n 2p "$c.line" | head -c 400 | tr -d '[:cntrl:]')

# Only the tail of the transcript can hold the last exchange, but "tail" in
# lines is unbounded here - a single turn can be megabytes of tool traffic.
# tac streams from the end and awk quits as soon as both halves are in hand,
# so the read stops a few entries back regardless of file size.
if [ -n "$gen" ]; then
  qa=()
elif [ "$(head -n1 "$c" 2>/dev/null)" = "$stamp" ]; then
  mapfile -t qa < <(tail -n +2 "$c")
else
  mapfile -t qa < <(tac "$f" | jq -r '
      def clean: gsub("<[^>]*>"; " ") | gsub("[*`#>]"; "") | gsub("\\s+"; " ") | sub("^[ -]+"; "") | sub(" +$"; "");
      def text: if type == "string" then . else map(select(.type == "text") | .text) | join(" ") end;
      if .isMeta then empty
      elif .type == "user" and ((.message.content | type) == "string" or ([.message.content[].type] | index("tool_result") | not))
        then "Q\t" + (.message.content | text | clean)
      elif .type == "assistant" then "A\t" + (.message.content | text | clean)
      else empty end
    ' 2>/dev/null |
    awk -F'\t' '
      length($2) < 2 { next }
      $1 == "A" { if (!a) a = $2; next }
      # Reversed stream, so a prompt arrives after the reply it earned. A
      # sign-off recaps nothing, and neither does the reply to one: drop the
      # pair and keep walking back to the last exchange that says something.
      tolower($2) ~ /^(bye|goodbye|see ya|see you|catch you later|later|thanks|thank you|ty|ok|okay|k|cool|nice|perfect|great|awesome)[ !.,]*$/ { a = ""; next }
      # A slash command nothing answered is UI (/exit, /clear, /model), not a
      # prompt; one that drew a reply is a prompt and stays.
      $2 ~ /^\// && !a { next }
      { q = $2; exit }
      END { print q; print a }')
  printf '%s\n%s\n%s\n' "$stamp" "${qa[0]}" "${qa[1]}" > "$c"
fi
[ -n "$gen${qa[0]}${qa[1]}" ] || exit 0

# Only stale sessions get an age. On the window you are actively typing in it
# would always read "0m", and a recap of the turn you just watched happen is
# self-evidently current.
age=$(( $(date +%s) - ${stamp##* } ))
if   [ "$age" -ge 172800 ]; then when="$(( age / 86400 ))d"
elif [ "$age" -ge 3600 ];   then when="$(( age / 3600 ))h"
else                             when=""
fi

cut() {
  local s=$1 n=$2
  [ "${#s}" -le "$n" ] && { printf '%s' "$s"; return; }
  printf '%s…' "${s:0:$(( n - 1 ))}"
}
room=$(( cols - ${#when} - 9 ))
[ -n "$when" ] && room=$(( room - 1 ))

# The generator runs from a hook, which is never told the terminal width - so
# leave it here for the next run to write to. Rewritten only on a resize; this
# is on the render path.
[ "$(cat "$c.cols" 2>/dev/null)" = "$room" ] || printf '%s\n' "$room" > "$c.cols"

line=$'\e[2m'"${when:+$when }"

if [ -n "$gen" ]; then
  printf '%s\e[0m%s\e[0m' "$line" "$(cut "$gen" "$room")"
  exit 0
fi

# A short prompt ("go on") donates its unused columns to the reply rather
# than leaving a gap - the reply is the half that is never short.
if [ -n "${qa[0]}" ]; then
  qmax=$room
  [ -n "${qa[1]}" ] && qmax=$(( room * 2 / 5 ))
  q=$(cut "${qa[0]}" "$qmax")
  line+=$'\e[0;90mQ\e[2m '"$q"
  room=$(( room - ${#q} ))
fi
[ -n "${qa[1]}" ] && line+=$' \e[0;90mA\e[2m '"$(cut "${qa[1]}" "$room")"
printf '%s\e[0m' "$line"
