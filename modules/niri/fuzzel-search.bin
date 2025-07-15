#!/usr/bin/env bash

query=$(
  fuzzel \
    -d \            # dmenu/Dmenu-compatible
    -l 0 \          # single line
    --placeholder "Search:" \
    --no-fork       # don’t detach, so we can read its stdout
)

if [ -n "$query" ]; then
  encoded=$(printf '%s' "$query" | jq -sRr @uri)

  xdg-open "https://unduck.link?q=$encoded" >/dev/null 2>&1 &
fi