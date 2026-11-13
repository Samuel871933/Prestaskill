#!/usr/bin/env bash
# Relevé factuel et compact d'un projet PrestaShop, pour remplir PRESTASHOP.md sans explorer à la main.
# Usage : scan.sh [racine_projet] [prefixe_modules]
# N'affiche jamais d'identifiants : seul le préfixe de tables est extrait des fichiers de config.
set -u
root="${1:-.}"; prefix="${2:-}"
cd "$root" || exit 1

first() { grep -hoE "$1" "${@:2}" 2>/dev/null | head -1; }
quoted() { grep -oE "'[^']*'" | tail -1 | tr -d "'"; }

echo "## Scan $(date +%F)"

v=$(first "VERSION = '[^']+'" src/Core/Version.php | quoted)
[ -z "$v" ] && v=$(first "const VERSION = '[^']+'" app/AppKernel.php | quoted)
[ -z "$v" ] && v=$(first "_PS_VERSION_', '[^']+'" config/settings.inc.php | quoted)
if [ -n "$v" ]; then
  echo "- PrestaShop : $v"
else
  # module isolé : la plage cible est dans la classe principale (<dossier>.php)
  c=$(grep -h "ps_versions_compliancy" "$(basename "$PWD").php" 2>/dev/null | head -1 | sed 's/^ *//')
  echo "- PrestaShop : introuvable${c:+ — module isolé : $c}"
fi
echo "- PHP CLI : $(php -r 'echo PHP_VERSION;' 2>/dev/null || echo 'non disponible')"

dbp=$(first "'database_prefix' => '[^']*'" app/config/parameters.php | quoted)
[ -z "$dbp" ] && dbp=$(first "_DB_PREFIX_', '[^']*'" config/settings.inc.php | quoted)
echo "- Préfixe tables : ${dbp:-introuvable}"

if [ -d themes ]; then
  # 1.7+ : PS écrit config/themes/<theme>/shop<id>.json pour le thème activé
  active=$(ls -d config/themes/*/ 2>/dev/null | xargs -r -n1 basename | tr '\n' ' ' | sed 's/ $//')
  echo "- Thèmes (actif d'après config/themes/ : ${active:-inconnu, demander} — à confirmer) :"
  for d in themes/*/; do
    t=$(basename "$d")
    if [ -f "$d/config/theme.yml" ]; then
      p=$(grep -E '^parent:' "$d/config/theme.yml" | awk '{print $2}')
      build=""; [ -f "$d/_dev/package.json" ] && build=" [build: _dev/]"
      echo "  - $t${p:+ (enfant de $p)}$build"
    elif [ -f "$d/config.xml" ]; then
      echo "  - $t (1.6)"
    fi
  done
fi

if [ -d modules ]; then
  total=$(find modules -mindepth 1 -maxdepth 1 -type d | wc -l)
  echo "- Modules : $total dossiers"
  if [ -n "$prefix" ]; then
    echo "  Modules du projet (préfixe '$prefix') :"
    for d in modules/"$prefix"*/; do
      [ -d "$d" ] || continue
      n=$(basename "$d")
      mv=$(first "version = '[^']+'" "$d/$n.php" | quoted)
      echo "  - $n ${mv:+v$mv}$( [ -d "$d/override" ] && echo ' [embarque des overrides]')"
    done
  fi
fi

if [ -d override ]; then
  echo "- Overrides actifs :"
  find override -type f -name '*.php' ! -name index.php | sort | sed 's/^/  - /'
fi
