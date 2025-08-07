#!/usr/bin/env bash
# shellcheck disable=SC2312

set -euo pipefail

# Configuration:
# - You can create a TSV file to define engines:
#   ~/.config/fuzzel-search/engines.tsv
#   Format per line: key<TAB>label<TAB>url_template<TAB>emoji<TAB>icon_name
#   url_template must include %s where the query will be inserted.
#
# - If the TSV doesn't exist, defaults below are used.

CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/fuzzel-search"
CONFIG_FILE="$CONFIG_DIR/engines.tsv"

# Default engines (edit here if you prefer inline config):
DEFAULT_ENGINES=(
  "u|Unduck|https://unduck.link?q=%s|󰍉|web-browser"
  "4o|T3 Chat (GPT-4o)|https://t3.chat/new?model=gpt-4o&q=%s|󱚢|chat"
  "5|T3 Chat (GPT-5 Chat)|https://t3.chat/new?model=gpt-5-chat&q=%s|󰭹|chat"
)

DEFAULT_KEY="u"

ensure_config_dir() {
  mkdir -p "$CONFIG_DIR"
}

# Load engines from TSV if present; otherwise use defaults
declare -A ENGINES_LABEL
declare -A ENGINES_URL
declare -A ENGINES_EMOJI
declare -A ENGINES_ICON
ENGINE_KEYS=()

load_engines() {
  if [[ -f "$CONFIG_FILE" ]]; then
    while IFS=$'\t' read -r key label url emoji icon || [[ -n "${key:-}" ]]; do
      [[ -z "${key:-}" || -z "${label:-}" || -z "${url:-}" ]] && continue
      ENGINE_KEYS+=("$key")
      ENGINES_LABEL["$key"]="$label"
      ENGINES_URL["$key"]="$url"
      ENGINES_EMOJI["$key"]="${emoji:-}"
      ENGINES_ICON["$key"]="${icon:-}"
    done <"$CONFIG_FILE"
  fi

  if [[ ${#ENGINE_KEYS[@]} -eq 0 ]]; then
    for line in "${DEFAULT_ENGINES[@]}"; do
      IFS='|' read -r key label url emoji icon <<<"$line"
      ENGINE_KEYS+=("$key")
      ENGINES_LABEL["$key"]="$label"
      ENGINES_URL["$key"]="$url"
      ENGINES_EMOJI["$key"]="$emoji"
      ENGINES_ICON["$key"]="$icon"
    done
  fi
}

# Build dmenu input with rofi icon protocol
build_engine_menu() {
  for key in "${ENGINE_KEYS[@]}"; do
    label="${ENGINES_LABEL[$key]}"
    emoji="${ENGINES_EMOJI[$key]}"
    icon="${ENGINES_ICON[$key]}"

    display="${emoji:-} ${label}  [${key}]"
    display="${display#" "}" # trim if no emoji

    if [[ -n "$icon" ]]; then
      printf "%s\0icon\x1f%s\n" "$display" "$icon"
    else
      printf "%s\n" "$display"
    fi
  done
}

# Map selection text back to engine key
key_from_selection() {
  local selection="$1"
  if [[ "$selection" =~ \[([A-Za-z0-9_.+-]+)\][[:space:]]*$ ]]; then
    printf "%s" "${BASH_REMATCH[1]}"
    return 0
  fi
  for key in "${ENGINE_KEYS[@]}"; do
    if [[ "$selection" == *"${ENGINES_LABEL[$key]}"* ]]; then
      printf "%s" "$key"
      return 0
    fi
  done
  printf "%s" "$DEFAULT_KEY"
}

# Detect URLs and domain-like strings
is_url_like() {
  local q="$1"
  if [[ "$q" =~ ^[A-Za-z][A-Za-z0-9+.-]*:// ]]; then
    return 0
  fi
  if [[ "$q" =~ ^[A-Za-z0-9.-]+\.[A-Za-z]{2,}(/.*)?$ ]]; then
    return 0
  fi
  return 1
}

open_url() {
  local url="$1"
  nohup xdg-open "$url" >/dev/null 2>&1 &
  disown || true
}

urlencode() {
  jq -sRr @uri
}

main() {
  ensure_config_dir
  load_engines

  # 1) Choose engine
  engine_selection="$(
    build_engine_menu |
      fuzzel --dmenu \
        --prompt " Engine: " \
        --placeholder "Pick a search engine (default: Unduck)" \
        --width 45 \
        --lines "${#ENGINE_KEYS[@]}" \
        --select-index 0
  )" || true

  ENGINE_KEY="$(key_from_selection "${engine_selection:-}")"
  ENGINE_LABEL="${ENGINES_LABEL[$ENGINE_KEY]}"
  ENGINE_URL_TPL="${ENGINES_URL[$ENGINE_KEY]}"
  ENGINE_EMOJI="${ENGINES_EMOJI[$ENGINE_KEY]}"

  # 2) Prompt for query (no auto-paste)
  query="$(
    fuzzel -d --prompt-only="${ENGINE_EMOJI:-󰍉} ${ENGINE_LABEL}: " \
      --placeholder "Type your search or URL" \
      --width 45
  )" || true

  if [[ -z "${query:-}" ]]; then
    exit 0
  fi

  # Optional inline override: "key: query"
  if [[ "$query" =~ ^([A-Za-z0-9_.+-]{1,8}):[[:space:]]*(.*)$ ]]; then
    maybe_key="${BASH_REMATCH[1]}"
    rest="${BASH_REMATCH[2]}"
    for k in "${ENGINE_KEYS[@]}"; do
      if [[ "$maybe_key" == "$k" ]]; then
        ENGINE_KEY="$k"
        ENGINE_LABEL="${ENGINES_LABEL[$ENGINE_KEY]}"
        ENGINE_URL_TPL="${ENGINES_URL[$ENGINE_KEY]}"
        query="$rest"
        break
      fi
    done
  fi

  if is_url_like "$query"; then
    if [[ "$query" =~ ^[A-Za-z][A-Za-z0-9+.-]*:// ]]; then
      open_url "$query"
    else
      open_url "https://$query"
    fi
    exit 0
  fi

  encoded="$(printf '%s' "$query" | urlencode)"
  if [[ "$ENGINE_URL_TPL" != *"%s"* ]]; then
    if [[ "$ENGINE_URL_TPL" == *"?"* ]]; then
      ENGINE_URL_TPL="${ENGINE_URL_TPL}&q=%s"
    else
      ENGINE_URL_TPL="${ENGINE_URL_TPL}?q=%s"
    fi
  fi

  final_url="$(printf "$ENGINE_URL_TPL" "$encoded")"
  open_url "$final_url"
}

main "$@"