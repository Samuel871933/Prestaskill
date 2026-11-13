# Thèmes

Ces règles valent quel que soit le thème (Classic, Hummingbird, thème du commerce). Seul le **parent** change : identifie-le, puis lis ses fichiers réels au lieu de supposer leur contenu.

## Identifier le contexte

1. Thème actif : `config/theme.yml` de chaque dossier `themes/*` + BO, ou `SELECT theme_name FROM ps_shop` (1.7+).
2. Si le thème actif a `parent:` dans `config/theme.yml` → c'est un enfant ; noter le parent.
3. Repérer la chaîne de build des assets : présence de `_dev/` + `package.json` (webpack/vite) → on modifie les sources dans `_dev/` et on rebuild ; sinon CSS/JS directs.
4. Thème du commerce : **ne pas le modifier directement** (perdu à sa mise à jour) → créer un enfant.

## Héritage (1.7 / 8 / 9)

Enfant minimal :

```
themes/montheme/
├── config/theme.yml
└── preview.png
```

```yaml
parent: classic          # nom du dossier du parent
name: montheme
display_name: Mon thème
version: 1.0.0
assets:
  use_parent_assets: true
```

- Résolution des templates : enfant d'abord, puis parent. Ne copier dans l'enfant **que** les fichiers modifiés.
- Étendre plutôt que copier : `{extends file='parent:catalog/product.tpl'}` puis ne redéfinir que les `{block name='…'}` voulus. `{$smarty.block.parent}` pour garder le contenu d'origine.
- Avant de redéfinir un bloc, lire le tpl du parent pour avoir son nom exact.
- `use_parent_assets: true` charge le CSS/JS du parent ; ajouter les siens dans `assets:` du theme.yml ou via `registerStylesheet` (dans un module).
- Le thème enfant doit être activé dans le BO ; vider le cache Smarty après chaque changement de structure.

1.6 : **pas** d'héritage. Dupliquer le thème et documenter ce qui a été modifié.

## Surcharger les templates / assets d'un module depuis le thème

Toujours dans le **thème actif** noté dans `PRESTASHOP.md` (ou donné par l'utilisateur, puis noté). Si c'est un thème du commerce ou natif sans enfant : créer l'enfant d'abord. Jamais dans le dossier du module (écrasé à sa mise à jour).

| Version | Templates | CSS / JS |
|---|---|---|
| 1.6 | `themes/<theme>/modules/<module>/<fichier>.tpl` | `themes/<theme>/css/modules/<module>/…`, `themes/<theme>/js/modules/<module>/…` |
| 1.7 / 8 / 9 | `themes/<theme>/modules/<module>/<même chemin que dans le module>` (ex. `views/templates/hook/x.tpl`) | `themes/<theme>/modules/<module>/<même chemin que dans le module>` *(à vérifier)* |

- Un fichier d'asset de surcharge **vide** supprime l'asset du module (ni l'original ni la surcharge ne sont chargés).
- Un tpl surchargé qui fait `{include file='./x.tpl'}` oblige à surcharger aussi `x.tpl` ; dans ses propres modules, écrire `{include file='module:<module>/views/templates/…'}` (1.7+).
- Doc : `https://devdocs.prestashop-project.org/<v>/themes/reference/overriding-modules/`.

## Smarty / Twig — règles

- Échappement : voir security.md § XSS.
- Traductions dans le thème : `{l s='Texte' d='Shop.Theme.Global'}` (1.7+) ; dans un module : `d='Modules.<Nom>.Shop'`.
- URLs : `{$urls.pages.*}`, `{url entity=…}`, `$link->getXLink()` — jamais d'URL en dur.

## Doc à WebFetch (remplacer `<v>`)

- Thèmes : `https://devdocs.prestashop-project.org/<v>/themes/`
- Thème enfant : `https://devdocs.prestashop-project.org/<v>/themes/reference/template-inheritance/parent-child-feature/`
- Hummingbird : `https://devdocs.prestashop-project.org/<v>/themes/hummingbird/`

Si 404 : partir de `https://devdocs.prestashop-project.org/<v>/themes/`.
