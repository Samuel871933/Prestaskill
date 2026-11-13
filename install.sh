#!/usr/bin/env bash
# Installe le skill prestashop pour Claude Code.
#   ./install.sh                 -> pour l'utilisateur (~/.claude/skills/prestashop), tous projets
#   ./install.sh --project DIR   -> pour un seul projet (DIR/.claude/skills/prestashop)
set -euo pipefail

src="$(cd "$(dirname "$0")" && pwd)/skills/prestashop"
case "${1:-}" in
  --project) dest="${2:?Usage: $0 --project <dossier_projet>}/.claude/skills/prestashop" ;;
  "")        dest="$HOME/.claude/skills/prestashop" ;;
  *)         echo "Usage: $0 [--project <dossier_projet>]"; exit 1 ;;
esac

if [ -d "$dest" ]; then
  # hors de skills/, sinon Claude Code chargerait la sauvegarde comme un 2e skill
  backup="$(dirname "$(dirname "$dest")")/prestashop-skill.bak.$(date +%Y%m%d%H%M%S)"
  mv "$dest" "$backup"
  echo "Ancienne version sauvegardée dans $backup"
fi

mkdir -p "$(dirname "$dest")"
cp -r "$src" "$dest"
chmod +x "$dest/scripts/scan.sh"
echo "Skill installé dans $dest"
echo "Redémarrez Claude Code (ou ouvrez une nouvelle session) pour le charger."
