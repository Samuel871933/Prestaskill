#!/usr/bin/env bash
# Auto-test des hooks : bash hooks/test-hooks.sh
h="$(cd "$(dirname "$0")" && pwd)"; fail=0
ps=$(mktemp -d); other=$(mktemp -d); trap 'rm -rf "$ps" "$other"' EXIT
touch "$ps/PRESTASHOP.md"
check() { # attendu(0|2) dossier hook json
  printf '%s' "$4" | CLAUDE_PROJECT_DIR="$2" bash "$h/$3" 2>/dev/null; r=$?
  [ "$r" = "$1" ] || { echo "ÉCHEC ($r au lieu de $1) : $3 $4"; fail=1; }
}
g=guard-secrets.sh
check 2 "$ps" $g '{"tool_input":{"file_path":"/shop/app/config/parameters.php"}}'
check 2 "$ps" $g '{"tool_input":{"file_path":"/shop/config/settings.inc.php"}}'
check 2 "$ps" $g '{"tool_input":{"file_path":"/shop/.env.local"}}'
check 2 "$ps" $g '{"tool_input":{"command":"cat dump.sql.gz"}}'
check 2 "$ps" $g '{"tool_input":{"pattern":"x","path":"/shop/admin123/backups/"}}'
check 2 "$ps" $g '{"tool_input":{"command":"bash ~/s/scripts/scan.sh . abc; cat app/config/parameters.php"}}'
check 0 "$ps" $g '{"tool_input":{"command":"bash ~/s/scripts/scan.sh /shop abc"}}'
check 0 "$ps" $g '{"tool_input":{"file_path":"/shop/modules/abcfaq/sql/install.sql"}}'
check 0 "$ps" $g '{"tool_input":{"file_path":"/shop/classes/Product.php"}}'
check 0 "$ps" $g '{"tool_input":{"command":"ls","description":"ne lit pas parameters.php"}}'
check 0 "$other" $g '{"tool_input":{"file_path":"/x/.env"}}'
if command -v php >/dev/null; then
  echo '<?php echo 1;' > "$ps/ok.php"; echo '<?php echo ;' > "$ps/ko.php"
  check 0 "$ps" php-lint.sh "{\"tool_input\":{\"file_path\":\"$ps/ok.php\"}}"
  check 2 "$ps" php-lint.sh "{\"tool_input\":{\"file_path\":\"$ps/ko.php\"}}"
  check 0 "$other" php-lint.sh "{\"tool_input\":{\"file_path\":\"$ps/ko.php\"}}"
fi
[ $fail = 0 ] && echo "hooks OK"; exit $fail
