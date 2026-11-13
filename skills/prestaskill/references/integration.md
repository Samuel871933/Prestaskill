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
- fil d'Ariane, pagination, filtres (`ps_facetedsearch`), formulaires (`_partials/form-fields.tpl`)

### États dynamiques (jamais dans les maquettes, toujours à faire)

Les maquettes montrent des pages au repos. Lister et habiller aussi ce qui n'apparaît qu'après une action, dans le style de la maquette :

| État | Où (1.7+ ; confirmer par `ls themes/<parent>/…`) |
|---|---|
| Modale d'ajout au panier | `modules/ps_shoppingcart/modal.tpl` du parent → surcharger dans l'enfant au même chemin |
| Notifications (succès, erreur, info) | `_partials/notifications.tpl` |
| Erreurs de formulaire, champs invalides | `_partials/form-fields.tpl`, `_partials/form-errors.tpl` |
| Panier vide, recherche sans résultat, liste sans produit | `checkout/cart-empty.tpl`, `catalog/_partials/products.tpl` / `errors/not-found.tpl` |
| Menu mobile ouvert, recherche ouverte, sous-menus | tpl de `ps_mainmenu` et `ps_searchbar` du parent |
| Chargements (spinner pendant AJAX), boutons désactivés, rupture de stock | grep `spinner`, `disabled`, `product-unavailable` dans le parent |
| Modale rapide (quickview), favoris (blockwishlist) | `catalog/_partials/quickview.tpl`, tpl du module |

Pour chacun : déclencher l'état réellement (ajout au panier, formulaire envoyé vide…) et le capturer.

### Placer un module dans la page

- Changer l'emplacement d'un module : BO > Apparence > Positions (greffer, déplacer, exceptions par page), pas de copie de son HTML dans le tpl.
- Appeler un module à un endroit précis du tpl : `{widget name='ps_shoppingcart'}` (module qui implémente `WidgetInterface`, 1.7+), ou un hook `{hook h='displayNav2'}`. Le widget accepte `hook='displayNav2'` pour reproduire le rendu de ce hook.
- Thème distribué : greffes du thème déclarées dans `config/theme.yml` (`global_settings.hooks.modules_to_hook`), appliquées à l'installation du thème. Les lire dans le parent avant d'en ajouter. Piège : un module cité dans `modules_to_hook` est **décroché de tous ses autres hooks display** non cités (`HookConfigurator::getThemeHooksConfiguration`) → lister chaque hook display utile du module, pas seulement le nouveau.
- Contenu HTML saisi en BO (pages CMS, `ps_customtext`…) : filtré par HTMLPurifier si `PS_USE_HTMLPURIFIER` = 1 (`<section>`, `<details>`, `<input>`, `data-*`… supprimés à l'enregistrement). Y garder un balisage simple (`div`, `p`, `h2`, `ul`, classes) et ajouter le comportement en JS dans le thème ; prévenir l'utilisateur que l'éditeur du BO peut abîmer la mise en page.

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
2. Thème enfant, choix SCSS ou CSS demandé à l'utilisateur, chaîne de build si SCSS (themes.md). Variables, polices (+ préchargement, § 5), icônes.
3. Composants communs.
4. Pages, une par une : `{extends file='parent:…'}` et seulement les `{block}` qui changent.
5. Tpl des modules visibles, surchargés dans le thème.
6. États dynamiques (§ 2) et traductions manquantes.
7. Passe performance (§ 5) et mesure Lighthouse.

Après chaque étape : vider le cache, vérifier aux largeurs du § 5, comparer à la maquette.

## 5. Responsive, performance et propreté

Ces règles valent dès la première ligne écrite, pas en fin de projet.

### Responsive

- Mobile d'abord : écrire le style mobile, puis `@media (min-width: …)` avec les **breakpoints du parent** (Bootstrap 5 : 576 / 768 / 992 / 1200 / 1400 ; Classic : ceux de Bootstrap 4), jamais des valeurs inventées. Maquette sans version mobile : le demander, sinon adapter et lister les choix faits.
- Largeurs à vérifier à chaque page : 360, 390, 768, 1024, 1280, 1440. Aucun défilement horizontal, rien de coupé, textes lisibles (16 px min. pour les champs, sinon zoom auto sur iOS).
- Cibles tactiles de 44 px min. (icônes du header, pastilles, quantités), rien qui ne marche qu'au survol : ce qui apparaît au `:hover` (tailles sur les miniatures, sous-menus) doit avoir un équivalent tactile.
- Utiliser la grille et les utilitaires responsives du parent (`col-md-*`, `d-none d-lg-block`) plutôt que du CSS maison ; tailles fluides avec `clamp()` pour les titres.

### CSS / JS

- Commun à tout le site → `custom.css` / `custom.js` (ou build SCSS). Propre à une page → fichier dédié déclaré seulement pour cette page (`assets.css.<page>` / `assets.js.<page>` du theme.yml, voir themes.md). Exemples : FAQ, fiche produit, tunnel.
- JS en `position: bottom` avec `attribute: defer` ; pas de jQuery ajouté (`core.js` le fournit déjà en 1.7–8 ; Hummingbird 9 : JS natif). Pas de librairie pour un effet faisable en CSS ou déjà fourni par le parent (carrousel, modale, accordéon : `details`/Bootstrap).
- En production : activer « Smart cache » CSS et JS (BO > Performances) pour combiner et minifier ; le vider après chaque livraison (versions/<v>.md § Cache).
- Pas de `!important` sauf pour battre un `!important` du parent ; pas de sélecteurs à rallonge.

### Images

- Toujours via les types d'image PrestaShop (`{$product.cover.bySize.<type>.url}`, `{$product.cover.bySize.<type>.width/height}`) ; créer un type à la taille de la maquette plutôt que réduire en CSS, puis régénérer les miniatures.
- Formats modernes : 8.0+ génère WebP/AVIF (BO > Design > Paramètres des images, clé `PS_IMAGE_FORMAT`) ; utiliser les `<picture>`/`sources` que le parent sait déjà produire (grep `<picture` dans ses tpl) plutôt que de les réécrire.
- `loading="lazy"` hors premier écran ; **jamais** sur l'image principale (hero, 1re photo produit, 1res miniatures du listing) : `fetchpriority="high"` sur celle-là. `width`/`height` toujours renseignés (pas de décalage de mise en page).
- Images de déco en CSS : légères, `image-set()` si plusieurs densités.

### Polices

- `woff2`, auto-hébergées, `font-display: swap`, seulement les graisses et styles utilisés, sous-ensemble latin.
- Précharger (`<link rel="preload" as="font" crossorigin>`) la ou les 2 polices du premier écran. Hummingbird : il lit `assets/preload.html` du **thème actif** (`_PS_THEME_DIR_`) ; un enfant sans ce fichier perd les préchargements du parent (icônes) → créer `themes/<enfant>/assets/preload.html` avec ses polices (chemins `../fonts/…`, réécrits vers les assets de l'enfant) et, pour celles du parent, leur chemin absolu `/themes/<parent>/assets/fonts/…`.

### Propreté

- Pas de texte en dur dans les tpl : `{l s='…' d='Shop.Theme.…'}` ; pas d'URL en dur : `{$urls.*}`.
- Accessibilité : `alt` des images, labels des champs, contrastes de la maquette vérifiés, focus visible, navigation clavier sur menu et modales.
- Mesurer à la fin : Lighthouse (mobile) sur accueil, catégorie, produit ; signaler LCP, CLS et poids des pages à l'utilisateur.

## Vérification avant de rendre la main

- Pages et éléments légaux listés à l'utilisateur, ceux qui existent intégrés.
- Chaque page maquettée comparée **côte à côte** à sa maquette (captures à la même largeur, desktop et mobile) : écarts listés à l'utilisateur, corrigés ou justifiés. Une page « jolie » n'est pas une page conforme.
- États dynamiques du § 2 déclenchés et habillés (au minimum : modale d'ajout au panier, notifications, erreurs de formulaire, panier vide, menu mobile).
- **Aucun texte en anglais** dans la langue de la boutique : le pack de langue officiel ne traduit pas tout le parent (Hummingbird en 9.x). Sur chaque page et chaque état dynamique, repérer les chaînes non traduites (lecture des captures, ou grep du HTML rendu pour des mots anglais courants : `Add|Added|your|cart|Continue|Send|Free|Sort|Search|Remove`) puis les traduire pour le thème (BO > International > Traductions > Thème, ou même table `ps_translation` par script, voir module-config.md) ; lister ce qui a été traduit.
- Responsive vérifié aux largeurs du § 5, Lighthouse mobile mesuré.
- Toutes les pages du § 1 affichées sans erreur, y compris celles sans maquette (elles doivent rester cohérentes avec le nouveau style).
- Aucun fichier copié du parent sans modification.
- `PRESTASHOP.md` : section Intégration et liste des tpl surchargés à jour.
