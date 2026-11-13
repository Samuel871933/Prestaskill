# Intégration de maquettes

Objectif : un thème enfant le plus léger possible, qui **réutilise** le parent (templates, classes, variables) au lieu de le réécrire. Prérequis : [themes.md](themes.md) (enfant, `{extends}`, surcharge de tpl de module).

Le format des maquettes n'est pas notre sujet : partir de ce que l'utilisateur fournit.

## 1. Inventaire : maquettes → pages PrestaShop

Les pages front sont fixes (un controller = un template). Associer chaque maquette à sa ligne, puis **signaler les pages sans maquette** (souvent : compte client, tunnel, 404, recherche vide) et les maquettes sans page native (→ page CMS, ou controller front de module).

| Page | Controller | Template 1.7+ (1.6 : à la racine du thème) |
|---|---|---|
| Accueil | index | `index.tpl` |
| Catégorie, recherche, marque, fournisseur, promos, nouveautés, meilleures ventes | category, search, manufacturer, supplier, prices-drop, new-products, best-sales | `catalog/listing/<page>.tpl` → `product-list.tpl` |
| Fiche produit | product | `catalog/product.tpl` |
| Panier | cart | `checkout/cart.tpl` |
| Tunnel de commande | order | `checkout/checkout.tpl` + `checkout/_partials/steps/*` |
| Confirmation | order-confirmation | `checkout/order-confirmation.tpl` |
| CMS / catégorie CMS | cms | `cms/page.tpl`, `cms/category.tpl` |
| Contact | contact | `contact.tpl` (formulaire : module contactform) |
| Magasins, plan du site | stores, sitemap | `cms/stores.tpl`, `cms/sitemap.tpl` |
| Connexion, inscription, mot de passe | authentication, registration, password | `customer/authentication.tpl`, `customer/registration.tpl`, `customer/password-*.tpl` |
| Compte client (+ sous-pages) | my-account, identity, addresses, history, order-detail… | `customer/*.tpl` |
| Erreurs, maintenance | pagenotfound, maintenance | `errors/404.tpl`, `errors/maintenance.tpl` |

Les chemins viennent de Classic : **les confirmer** par `ls themes/<parent>/templates/**` avant de s'en servir (Hummingbird et les thèmes du commerce diffèrent).

## 2. Composants communs avant les pages

Lister ce qui se répète d'une maquette à l'autre et le traiter une fois, dans les partials du parent :

- header, footer, menu (souvent des modules : `ps_mainmenu`, `ps_shoppingcart`, `ps_searchbar`… → surcharge de leurs tpl dans le thème)
- miniature produit : `catalog/_partials/miniatures/product.tpl` (sert à l'accueil, aux listings, à la recherche, aux produits associés)
- fil d'Ariane, pagination, filtres (`ps_facetedsearch`), formulaires (`_partials/form-fields.tpl`), notifications, modale d'ajout au panier

## 3. Réutiliser le CSS du parent

Ordre de préférence, du moins au plus coûteux :

1. **Variables** du parent (couleurs, polices, arrondis, espacements, breakpoints) : en SCSS, recompilées avec les valeurs de l'enfant ; en CSS simple, variables CSS `--bs-*` (Hummingbird) dans `custom.css`. Choix SCSS / CSS et mise en place : [themes.md § Assets du thème enfant](themes.md).
2. **Classes existantes** dans les tpl (`btn btn-primary`, `card`, `form-control`… selon le framework du parent). Les modules natifs et tiers les utilisent déjà : ils prennent le style sans retouche.
3. **CSS ciblé** dans l'enfant, uniquement pour ce que 1 et 2 ne couvrent pas.

Ne jamais créer une classe maison quand une classe du parent fait le travail. Framework : lire `package.json` du parent (Bootstrap 3 en 1.6 ; Classic : Bootstrap 4 ; Hummingbird : Bootstrap 5 *(à vérifier selon version)*).

Classes les plus utilisées du parent (à styler en premier) :

```bash
grep -rhoE 'class="[^"]*"' themes/<parent>/templates | sed 's/^class="//; s/"$//' \
  | tr ' ' '\n' | grep -vE '^$|[{}$]' | sort | uniq -c | sort -rn | head -40
```

## 4. Ordre de travail

1. Inventaire (§ 1 et 2) validé par l'utilisateur, noté dans `PRESTASHOP.md` § Intégration.
2. Thème enfant, choix SCSS ou CSS demandé à l'utilisateur, chaîne de build si SCSS (themes.md). Variables, polices, icônes.
3. Composants communs.
4. Pages, une par une : `{extends file='parent:…'}` et seulement les `{block}` qui changent.
5. Tpl des modules visibles, surchargés dans le thème.

Après chaque étape : vider le cache, vérifier mobile et desktop.

## 5. Performance et propreté

- Polices : `woff2`, auto-hébergées, `font-display: swap`, ne charger que les graisses utilisées.
- Images : passer par les types d'image PrestaShop (`{$product.cover.bySize.<type>.url}`) ; créer un type d'image plutôt que redimensionner en CSS. `loading="lazy"` hors premier écran, `width`/`height` renseignés.
- Un seul CSS / JS de thème buildé et minifié. Assets spécifiques à une page : déclarés pour cette page seulement (`assets.css.<page>` du theme.yml, voir themes.md).
- Pas de librairie JS ajoutée pour un effet faisable en CSS ou déjà fourni par le parent (carrousel, modale…).
- Pas de texte en dur dans les tpl : `{l s='…' d='Shop.Theme.…'}` ; pas d'URL en dur : `{$urls.*}`.
- Accessibilité : `alt` des images, labels des champs, contrastes de la maquette vérifiés, navigation clavier sur menu et modales.

## Vérification avant de rendre la main

- Toutes les pages du § 1 affichées sans erreur, y compris celles sans maquette (elles doivent rester cohérentes avec le nouveau style).
- Aucun fichier copié du parent sans modification.
- `PRESTASHOP.md` : section Intégration et liste des tpl surchargés à jour.
