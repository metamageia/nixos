#!/usr/bin/env bash

query=$(
  fuzzel -d --prompt-only="󰍉 Search: "
)

if [ -n "$query" ]; then
  encoded=$(printf '%s' "$query" | jq -sRr @uri)

  xdg-open "https://unduck.link?q=$encoded" >/dev/null 2>&1 &
fi