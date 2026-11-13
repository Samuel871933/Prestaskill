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
- Assets (CSS/JS) de l'enfant : section suivante.
- Le thème parent doit être présent dans `themes/`, puis l'enfant activé dans le BO ; vider le cache Smarty après chaque changement de structure.

1.6 : **pas** d'héritage. Dupliquer le thème et documenter ce qui a été modifié.

## Assets du thème enfant (CSS / JS)

**Avant de créer le premier fichier de style, demander à l'utilisateur : SCSS ou CSS simple ?** Noter le choix dans `PRESTASHOP.md` § Intégration. Sans préférence : CSS simple si les changements sont légers, SCSS si la maquette change les couleurs, polices, boutons sur tout le site.

### Fonctionnement (1.7 / 8 / 9, vérifié dans le core 1.7.8, 8.1, develop)

- Le core enregistre toujours, sur chaque page :

  | Fichier | ID | Priorité |
  |---|---|---|
  | `assets/css/theme.css` | `theme-main` | 50 |
  | `assets/css/rtl.css` (langues RTL) | `theme-rtl` | 900 |
  | `assets/css/custom.css` | `theme-custom` | 1000 (en dernier) |
  | `/themes/core.js` (jQuery, objet `prestashop`) | `corejs` | 0 |
  | `assets/js/theme.js` | `theme-main` | 50 |
  | `assets/js/custom.js` | `theme-custom` | 1000 |

- Chaque chemin est cherché **dans l'enfant, puis dans le parent, puis à la racine** du site. Donc un fichier présent dans l'enfant **remplace** celui du parent ; absent, celui du parent est servi. Rien à enregistrer pour ces fichiers.
- `use_parent_assets` (garder `true`) ne change que les variables Smarty `{$urls.css_url}`, `{$urls.img_url}`, `{$urls.js_url}`… qui pointent alors vers le parent ; `{$urls.child_css_url}`, `{$urls.child_img_url}`… pointent vers l'enfant (8+ ; en 1.7, grep `use_parent_assets` dans `classes/` pour confirmer).

### Option CSS simple (sans build)

- Écrire dans `themes/<enfant>/assets/css/custom.css` et `assets/js/custom.js` : chargés automatiquement après le thème parent, sans configuration.
- Ne pas créer `assets/css/theme.css` dans l'enfant : il remplacerait tout le CSS du parent.
- Hummingbird (Bootstrap 5.3) : beaucoup de valeurs passent par des variables CSS (`--bs-*`, sur `:root` et sur les composants), surchargeables dans `custom.css` *(vérifier dans `assets/css/theme.css` du parent)*. Classic (Bootstrap 4 alpha) : pas de variables CSS, surcharger les sélecteurs.
- Limite : les couleurs et tailles du parent sont dupliquées dans des sélecteurs ; au-delà de quelques dizaines de règles, passer en SCSS.

### Option SCSS (build dans l'enfant)

But : recompiler le SCSS **du parent** avec les variables de l'enfant, pour produire `themes/<enfant>/assets/css/theme.css`, qui remplace celui du parent.

1. Sources du parent :
   - Classic : `_dev/css/theme.scss`, variables dans `_dev/css/partials/_variables.scss`, build webpack (`_dev/package.json`, sortie `../assets/css/theme.css` et `../assets/js/theme.js`), Bootstrap 4.0.0-alpha.5.
   - Hummingbird : `src/scss/theme.scss`, variables dans `src/scss/abstract/variables/` et `src/scss/bootstrap/overrides/variables/`, build webpack (`webpack.config.js` + `webpack/`), Bootstrap 5.3, version de Node dans `.nvmrc` du parent (24 pour Hummingbird 2.1). Hummingbird 2.x range ses styles dans des `@layer` CSS : `custom.css`, hors couche, passe devant sans surenchère de spécificité. Revers : une règle générique hors couche bat **tous** les composants du parent, même plus spécifiques (ex. `a { color: inherit }` écrase les couleurs des `.btn` en `<a>`) → cibler étroitement (`.footer a`), ou mettre les règles génériques dans une couche (`@layer marea-base { … }`). Inversement, un `!important` **dans** une couche du parent bat tout `!important` hors couche (pour les déclarations importantes, l'ordre des couches s'inverse : la première couche gagne). Pour le battre : déclarer sa règle `!important` dans la **première** couche du parent (lire l'ordre dans `@layer a, b, c;` en tête de son `theme.css`, ex. `@layer vendors { .x { color: red !important } }`).
   - Thème du commerce : chercher `package.json` et le `.scss` d'entrée ; s'il n'y a pas de sources, seule l'option CSS simple est possible.
2. Dans l'enfant, `_dev/` contient la chaîne de build : reprendre le `package.json` et la config webpack du parent (mêmes versions, sortie vers `../assets/`), plutôt qu'inventer une autre chaîne.
3. Point d'entrée `_dev/css/theme.scss` de l'enfant :
   - si les variables du parent sont en `!default` : déclarer les siennes, puis `@import` du `theme.scss` du parent ;
   - sinon (cas de Classic et Hummingbird, variables sans `!default`) : **copier** le `theme.scss` du parent, faire pointer chaque import vers le dossier du parent, et remplacer seulement l'import des variables par le fichier de l'enfant (qui commence par importer celui du parent puis redéfinit ce qui change).
   - styles propres à l'enfant : partials importés à la fin.
4. `url()` relatives (polices, images) : après le premier build, vérifier qu'elles pointent vers des fichiers existants ; sinon copier les fichiers dans `assets/` de l'enfant ou corriger le chemin.
5. Pas de `theme.js` dans l'enfant sauf besoin : celui du parent reste servi. JS spécifique → `assets/js/custom.js`.
6. Livrer le CSS **compilé et minifié** (`npm run build`) ; `_dev/node_modules` hors du dépôt et du zip du thème.

### Fichiers supplémentaires ou par page

Dans `config/theme.yml` de l'enfant, clé **`assets` à la racine** (même clé que `use_parent_assets`). Page = `php_self` du controller (`index`, `category`, `product`, `cart`, `order`, `cms`…), `all` = toutes les pages. Chemins relatifs à la racine du thème.

```yaml
assets:
  use_parent_assets: true
  css:
    product:
      - id: theme-product          # id unique, préfixé
        path: assets/css/product.css
        media: all                 # défaut all
        priority: 200              # défaut 50 ; 0 = premier
  js:
    all:
      - id: theme-menu
        path: assets/js/menu.js
        position: bottom           # head | bottom (défaut)
        priority: 200
        attribute: defer           # async | defer — au singulier dans theme.yml
```

- `id` et `path` obligatoires, sinon l'entrée est ignorée sans erreur. `server: remote` + chemin `//…` pour un CDN.
- La clé `assets` de l'enfant **remplace entièrement** celle du parent (fusion non récursive) : si le parent déclare des assets par page dans son `theme.yml`, les recopier dans l'enfant.
- Ignorer un exemple de doc qui place ces assets sous `global_settings:` : le core lit `assets.css.<page>` et `assets.js.<page>` à la racine.
- Préférer un fichier par page à un gros fichier `all` quand le code ne sert qu'à une page.
- Depuis un module (pas le thème) : `registerStylesheet` / `registerJavascript` dans `hookActionFrontControllerSetMedia`, voir modules.md.

### 1.6

Pas d'enfant ni de `theme.yml`. Le core charge `css/global.css`, `js/global.js`, puis **tout fichier** de `css/autoload/*.css` et `js/autoload/*.js` du thème : y mettre les ajouts, sans enregistrement. CSS par page : fichiers du thème chargés par chaque controller (ex. `css/product.css`). SCSS : default-bootstrap a des sources dans `sass/`, compilées avec Compass (`config.rb` à la racine du thème : `compass compile`).

## Surcharger les templates / assets d'un module depuis le thème

Toujours dans le **thème actif** noté dans `PRESTASHOP.md` (ou donné par l'utilisateur, puis noté). Si c'est un thème du commerce ou natif sans enfant : créer l'enfant d'abord. Jamais dans le dossier du module (écrasé à sa mise à jour).

| Version | Templates | CSS / JS |
|---|---|---|
| 1.6 | `themes/<theme>/modules/<module>/<fichier>.tpl` | `themes/<theme>/css/modules/<module>/…`, `themes/<theme>/js/modules/<module>/…` |
| 1.7 / 8 / 9 | `themes/<theme>/modules/<module>/<même chemin que dans le module>` (ex. `views/templates/hook/x.tpl`) | `themes/<theme>/modules/<module>/<même chemin que dans le module>` (ex. `views/css/front.css`) : le core cherche le chemin relatif enregistré par le module dans le thème, puis le parent, puis la racine. Ne marche que pour les assets enregistrés en chemin relatif (`registerStylesheet`), pas pour une URL absolue ou `server: remote`. |

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
