#!/usr/bin/env bash
# new-daimon — instantiate a new council daimon (Hermes profile) from the
# canonical empty-vessel template. Usage:
#     new-daimon <name> ["one-line role description for kanban routing"]
set -euo pipefail

names="${1:-}"
[ -z "$names" ] && { echo "usage: new-daimon <name> [role-description]" >&2; exit 1; }
desc="${2:-}"

echo "Binding a new daimon: $names"

# Preferred: clone the canonical empty vessel (profile `template`). It holds
# the blank state — empty SOUL, name-only memory, five op skills, shared
# DISCORD_*/.env only, no pfp — so a new daimon inherits nothing but the name.
# (Previously cloned Aisling and purged; the live daimon is never a source.)
hermes profile create "$names" --clone-from template

# If a role description was given, record it so the kanban orchestrator knows
# what this daimon is for (routing hint, not a personality).
if [ -n "$desc" ]; then
  if hermes -p "$names" profile describe --help >/dev/null 2>&1; then
    hermes -p "$names" profile describe "$desc" 2>/dev/null \
      || echo "  (note: could not set profile description — set manually if needed)"
  else
    echo "  (note: this hermes build lacks 'profile describe'; role noted for later)"
  fi
fi

echo
echo "Daimon $names bound at \${HERMES_HOME}/profiles/$names"
echo "  - SOUL.md: empty (generic default) — write her soul when ready"
echo "  - memories/USER.md: name only; MEMORY.md: empty"
echo "  - skills: the five Hermes-operation skills only"
echo "  - command:  $names chat / $names config set ... / $names gateway start"
echo "Tabula rasa. Nothing inherited but the name."
