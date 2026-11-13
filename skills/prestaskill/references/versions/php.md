# Compatibilité PHP

Source : devdocs `…/<1.7|8|9>/basics/installation/system-requirements/` (relevé 2026-11). Pour une mineure absente ou récente, WebFetch la page de la version.

| PrestaShop | PHP supporté | Recommandé |
|---|---|---|
| 1.6.1.x | 5.2 → 7.1 (7.1 : dernières 1.6.1 seulement) | 7.1 |
| 1.7.0 → 1.7.3 | 5.4 → 7.1 | 7.1 |
| 1.7.4 | 5.6 → 7.1 | 7.1 |
| 1.7.5 → 1.7.6 | 5.6 → 7.2 | 7.2 |
| 1.7.7 | 7.1 → 7.3 | 7.3 |
| 1.7.8 | 7.1 → 7.4 | 7.4 |
| 8.0 → 8.2 | 7.2 → 8.1 | 8.1 |
| 9.0 | 8.1 → 8.4 | 8.4 |
| 9.1 | 8.1 → 8.5 | 8.5 |
| 9.2 | 8.1 min (composer.json) ; max absent de devdocs au 2026-11 → WebFetch | — |

## Écrire pour le PHP minimum de la plage cible

| Syntaxe | PHP min |
|---|---|
| `[]` tableaux courts | 5.4 |
| `??`, types scalaires, types de retour | 7.0 |
| `?Type` nullable, `void`, `[$a, $b] = …` | 7.1 |
| typed properties, `fn() =>`, `??=` | 7.4 |
| `match`, nullsafe `?->`, union types, promotion de constructeur, `#[Attribut]` | 8.0 |
| `enum`, `readonly`, `never`, `new` en valeur par défaut | 8.1 |
| classes `readonly`, types DNF | 8.2 |
| constantes de classe typées, `#[\Override]` | 8.3 |

## Pistes quand ça casse

- **PHP serveur hors plage** de la version PS (mise à jour PHP par l'hébergeur) : cause fréquente de page blanche ou d'erreur 500 sur 1.6/1.7. Comparer `php -v` (et la version PHP du site, qui peut différer du CLI) à la table.
- **PHP 8.0+** : `each()`, `create_function()`, accolades `$str{0}` supprimés ; comparaisons chaîne/nombre changées (`0 == 'a'` est faux) ; arguments `null` passés aux fonctions internes → deprecated en 8.1.
- **PHP 8.2** : propriétés dynamiques deprecated (fréquent dans les vieux modules et overrides).
- Module tiers qui casse après montée de PHP : vérifier sa compatibilité avant de patcher ; si patch nécessaire, override (`/override/modules/…`), pas d'édition du module.
