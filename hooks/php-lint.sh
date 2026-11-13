#!/usr/bin/env bash
# PostToolUse Edit|Write|MultiEdit : php -l sur le fichier PHP modifié, silencieux si OK.
source "$(dirname "$0")/is-ps-project.sh"
f=$(cat | grep -oE '"file_path" *: *"[^"]*\.php"' | head -1 | sed -E 's/.*"([^"]*)"$/\1/')
[ -n "$f" ] && [ -f "$f" ] && command -v php >/dev/null || exit 0
out=$(php -l "$f" 2>&1) || { echo "$out" >&2; exit 2; }
