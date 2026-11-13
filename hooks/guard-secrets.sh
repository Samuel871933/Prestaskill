#!/usr/bin/env bash
# PreToolUse Read|Grep|Bash : refuse la lecture des fichiers à secrets / données clients.
# shortcut: ne voit que les chemins écrits dans l'appel (un grep -r . passe), c'est un garde-fou, pas un bac à sable.
source "$(dirname "$0")/is-ps-project.sh"
input=$(cat)
vals=$(printf '%s' "$input" | grep -oE '"(file_path|path|glob|command)" *: *"([^"\\]|\\.)*"')
# scan.sh n'extrait que le préfixe des tables ; refusé s'il est chaîné à autre chose
# \ exclu : un retour à la ligne échappé (\n) chaînerait une 2e commande ; <> : redirections
printf '%s' "$vals" | grep -qE '"command" *: *"bash [^";&|`$<>\\]*scripts/scan\.sh[^";&|`$<>\\]*"' && exit 0
hit=$(printf '%s\n' "$vals" | grep -oE 'app/config/parameters\.(php|yml)|config/settings\.inc\.php|(^|[/ "=])\.env[^ "]*|\.htpasswd|(^|[/ "])(admin[^/ "]*/)?backups?/|(^|[/ "])(var/logs?|log)/')
[ -z "$hit" ] && hit=$(printf '%s\n' "$vals" | grep -E '\.sql(\.gz|\.bz2|\.zip)?\b' | grep -vE 'modules/[^ "]*\.sql\b' | grep -oE '[^ "/]*\.sql[^ "]*')
[ -z "$hit" ] && exit 0
echo "Bloqué par le skill prestaskill : $(echo "$hit" | head -1 | tr -d ' \"=') peut contenir des secrets ou des données clients (identifiants, logs, dumps). Pour le préfixe des tables, utiliser scripts/scan.sh ; sinon demander à l'utilisateur." >&2
exit 2
