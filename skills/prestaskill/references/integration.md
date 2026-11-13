# Intégration de maquettes

Objectif : un thème enfant le plus léger possible, qui **réutilise** le parent (templates, classes, variables) au lieu de le réécrire. Prérequis : [themes.md](themes.md) (enfant, `{extends}`, surcharge de tpl de module).

Le format des maquettes n'est pas notre sujet : partir de ce que l'utilisateur fournit.

## 1. Inventaire : maquettes → pages PrestaShop

Les pages front sont fixes (un controller = un template). Associer chaque maquette à sa ligne, puis **signaler les pages sans maquette** (souvent : compte client, tunnel, 404, recherche vide, pages légales ci-dessous) et les maquettes sans page native (→ page CMS, ou controller front de module).

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

### Pages et éléments légaux

Souvent absents des maquettes : **toujours les lister à l'utilisateur** en lui demandant lesquels existent. Le texte est fourni par le client (ou son juriste), jamais rédigé par l'agent ; l'intégration ne fait que la mise en page.

| Élément | Où dans PrestaShop |
|---|---|
| CGV, mentions légales, politique de confidentialité, politique cookies, livraison, paiement sécurisé, droit de rétractation (+ formulaire type) | Pages CMS (`cms/page.tpl`) : une seule mise en page pour toutes ; vérifier lesquelles existent déjà en BO (certaines sont créées à l'installation) |
| Case « J'accepte les CGV » au tunnel | Réglage BO des commandes (page CMS des conditions liée) ; rendu dans `checkout/_partials/steps/payment.tpl` (bloc `#conditions-to-approve`, Classic ; autre thème : grep `conditions_to_approve`) |
| Liens légaux du footer | Modules de liens du footer (`ps_linklist` en 1.7+) : configuration en BO, pas en dur dans le tpl |
| Consentements RGPD (formulaires contact, inscription, newsletter) | Module `psgdpr` (version du module selon PS : lire son `ps_versions_compliancy` ; la version actuelle exige 8.0+), case affichée par le hook `displayGDPRConsent` |
| Bandeau cookies / consentement | Pas de module natif : module tiers ou solution du client (CMP) → demander lequel, puis intégrer son style |
| Informations de mentions (raison sociale, SIRET, hébergeur, médiateur) | Coordonnées boutique en BO + page CMS ; pas en dur dans le footer |

Les chemins viennent de Classic : **les confirmer** par `ls themes/<parent>/templates/**` avant de s'en servir (Hummingbird et les thèmes du commerce diffèrent).

## 2. Composants communs avant les pages

Lister ce qui se répète d'une maquette à l'autre et le traiter une fois, dans les partials du parent :

- header, footer, menu (souvent des modules : `ps_mainmenu`, `ps_shoppingcart`, `ps_searchbar`… → surcharge de leurs tpl dans le thème)
- miniature produit : `catalog/_partials/miniatures/product.tpl` (sert à l'accueil, aux listings, à la recherche, aux produits associés)
- fil d'Ariane, pagination, filtres (`ps_facetedsearch`), formulaires (`_partials/form-fields.tpl`), notifications, modale d'ajout au panier

### Placer un module dans la page

- Changer l'emplacement d'un module : BO > Apparence > Positions (greffer, déplacer, exceptions par page), pas de copie de son HTML dans le tpl.
- Appeler un module à un endroit précis du tpl : `{widget name='ps_shoppingcart'}` (module qui implémente `WidgetInterface`, 1.7+), ou un hook `{hook h='displayNav2'}`. Le widget accepte `hook='displayNav2'` pour reproduire le rendu de ce hook.
- Thème distribué : greffes du thème déclarées dans `config/theme.yml` (`global_settings.hooks.modules_to_hook`), appliquées à l'installation du thème. Les lire dans le parent avant d'en ajouter.

### JS après un rechargement AJAX

Sur la fiche produit (changement de déclinaison), le listing (filtres facettés, pagination) et le panier, le parent **remplace des morceaux du DOM** en AJAX : les écouteurs posés au chargement ne s'appliquent plus aux nouveaux éléments. Dans `custom.js` de l'enfant :

```js
prestashop.on('updatedProduct', init);      // déclinaison changée (fiche produit)
prestashop.on('updateProductList', init);   // listing rechargé (filtres, tri, pagination)
prestashop.on('updateCart', init);          // panier modifié
```

Ou délégation d'événements (`document.addEventListener('click', e => e.target.closest('.x') …)`). Noms des événements : grep `prestashop.emit` dans le JS du parent (Classic et Hummingbird).

### Tunnel : livraison et paiement

Les modules de paiement et de transport ne sont pas développés ni modifiés ici (voir [module-types.md](module-types.md)) : on ne fait que leur **rendu**.

- Étapes (1.7+) : `checkout/_partials/steps/shipping.tpl` (liste des transporteurs, `delivery_options`) et `checkout/_partials/steps/payment.tpl` (options de paiement, `payment_options`, conditions à accepter). 1.6 : `order-carrier.tpl`, `order-payment.tpl` (ou `order-opc.tpl` en commande en une page).
- Logos des transporteurs : image du transporteur en BO, pas en dur. Logos de paiement : fournis par chaque module (`PaymentOption::setLogo`) ; seule la mise en page se règle dans le thème.
- Bloc d'un module de paiement ou de transport (formulaire de carte, choix de point relais, page de retour) : surcharger son tpl dans le thème actif (themes.md § Surcharger les templates d'un module), sans toucher à sa logique ni à ses champs de formulaire (`name`, `id`, attributs `data-*` lus par son JS).
- Tester avec les modules réellement installés (paiement par chèque / virement en local) : chaque option doit rester sélectionnable et le bouton « Commander » s'activer.

### Emails et PDF

Souvent oubliés des maquettes : demander s'ils sont à habiller.

- Emails 1.7.6+ : thèmes d'emails Twig (`mails/themes/<classic|modern>/`), choisis et régénérés dans le BO (Apparence > Thème d'e-mails) ; personnaliser via un module qui ajoute un thème d'emails (hook `actionListMailThemes`, 1.7.6+), pas en éditant `mails/` à la racine.
- Emails 1.6 → 1.7.5 : copies dans `themes/<theme>/mails/<iso>/` (et `themes/<theme>/modules/<module>/mails/<iso>/` pour ceux d'un module).
- PDF (facture, bon de livraison, avoir) : copier le tpl voulu de `pdf/` vers `themes/<theme>/pdf/` et ne modifier que la mise en page. CSS inline simple (moteur TCPDF : pas de flex ni de grid).

## 3. Réutiliser le CSS du parent

Ordre de préférence, du moins au plus coûteux :

1. **Variables** du parent (couleurs, polices, arrondis, espacements, breakpoints) : en SCSS, recompilées avec les valeurs de l'enfant ; en CSS simple, variables CSS `--bs-*` (Hummingbird) dans `custom.css`. Choix SCSS / CSS et mise en place : [themes.md § Assets du thème enfant](themes.md).
2. **Classes existantes** dans les tpl (`btn btn-primary`, `card`, `form-control`… selon le framework du parent). Les modules natifs et tiers les utilisent déjà : ils prennent le style sans retouche.
3. **CSS ciblé** dans l'enfant, uniquement pour ce que 1 et 2 ne couvrent pas.

Ne jamais créer une classe maison quand une classe du parent fait le travail. Framework : lire `package.json` du parent (Bootstrap 3 en 1.6 ; Classic : Bootstrap 4 ; Hummingbird : Bootstrap 5.3).

Classes les plus utilisées du parent (à styler en premier) :

```bash
grep -rhoE 'class="[^"]*"' themes/<parent>/templates | sed 's/^class="//; s/"$//' \
  | tr ' ' '\n' | grep -vE '^$|[{}$]' | sort | uniq -c | sort -rn | head -40
```

## 4. Ordre de travail

1. Inventaire (§ 1 et 2) validé par l'utilisateur, noté dans `PRESTASHOP.md` § Intégration. Demander aussi : **intégration seule, ou aussi paramétrage des modules** (liens du menu, blocs du footer, textes…) ? Si oui : [module-config.md](module-config.md).
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

- Pages et éléments légaux listés à l'utilisateur, ceux qui existent intégrés.
- Toutes les pages du § 1 affichées sans erreur, y compris celles sans maquette (elles doivent rester cohérentes avec le nouveau style).
- Aucun fichier copié du parent sans modification.
- `PRESTASHOP.md` : section Intégration et liste des tpl surchargés à jour.
