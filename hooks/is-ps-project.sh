# Sourcé par les hooks : le plugin est global, on n'agit que dans un projet PrestaShop.
d="${CLAUDE_PROJECT_DIR:-$PWD}"
[ -f "$d/PRESTASHOP.md" ] || [ -f "$d/classes/ObjectModel.php" ] || [ -f "$d/app/AppKernel.php" ] || [ -f "$d/config/settings.inc.php" ] || exit 0
