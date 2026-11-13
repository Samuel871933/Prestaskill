# Overrides

## Avant d'écrire un override, répondre à ces questions

1. Un **hook** permet-il de le faire ? (grep le core autour de la ligne à modifier : y a-t-il un `Hook::exec` ?)
2. Un **service Symfony** décorable ? (1.7.5+ côté BO ; `config/services.yml` du module avec `decorates:`)
3. Est-ce un problème d'**affichage** ? → surcharge de template dans le thème actif (voir themes.md) ou de Twig BO (ci-dessous), pas d'override PHP.
4. Sinon seulement : override. Le dire à l'utilisateur, avec la raison, et le noter dans `PRESTASHOP.md`.

Pourquoi : un override est exclusif (deux modules qui overrident la même méthode ne cohabitent pas), il casse aux mises à jour du core, et il peut être désactivé globalement (BO > Paramètres avancés > Performances > « Désactiver tous les overrides »). Interdit dans un module distribué sur Addons.

## Où : le dossier `override/` à la racine de la boutique

Tout override PHP va dans `/override/`, avec la même arborescence que le fichier d'origine. Jamais dans `classes/`, `controllers/` ni dans le dossier du module overridé.

| Cible | Fichier | Classe |
|---|---|---|
| Classe core | `override/classes/Product.php` | `class Product extends ProductCore` |
| Sous-dossier de `classes/` | `override/classes/order/Order.php` | `class Order extends OrderCore` |
| Controller front core | `override/controllers/front/ProductController.php` | `class ProductController extends ProductControllerCore` |
| Controller admin legacy | `override/controllers/admin/AdminOrdersController.php` | `extends AdminOrdersControllerCore` (inopérant sur une page BO migrée Symfony) |
| Classe d'un module | `override/modules/<module>/<module>.php` | `class <Module>Override extends <Module>` |
| Controller d'un module | `override/modules/<module>/controllers/front/<fichier>.php` (ou `admin/`) | `class <Module><Fichier>ModuleFrontControllerOverride extends <Module><Fichier>ModuleFrontController` (1.7.2+) |

- Ne déclarer que les méthodes modifiées, appeler `parent::methode()` quand c'est possible, pas de propriété/constante inutile.
- Overrider un module dépend du code exact de ce module : relire sa version installée et re-vérifier après chaque mise à jour du module.
- **Rien dans `src/` (namespacé) n'est overridable** ainsi → décoration de service ou hooks.
- Doc : `https://devdocs.prestashop-project.org/<v>/modules/concepts/overrides/` — WebFetch au moindre doute sur un chemin ou une version.

Variante : un module peut embarquer ses overrides dans `modules/<module>/override/…` (même arborescence) ; PS les copie/fusionne dans `/override/` à l'installation et les retire à la désinstallation. Après modification, réinstaller (reset) le module, sinon `/override/` garde l'ancienne version. Suivre la convention notée dans `PRESTASHOP.md` ; par défaut : `/override/` à la racine.

## Templates Twig du BO (1.7.3+)

Pas d'override PHP : copier le chemin du template dans un module, `src/PrestaShopBundle/Resources/views/` devenant `modules/<module>/views/PrestaShop/`. Ex : `@PrestaShop/Admin/Product/CatalogPage/catalog.html.twig` → `modules/<module>/views/PrestaShop/Admin/Product/CatalogPage/catalog.html.twig`, qui fait `{% extends '@!PrestaShop/Admin/…' %}` (le `!` cible l'original) et ne redéfinit que les blocs voulus. Nom du template : barre de debug Symfony > Twig.

## Après tout changement

Régénérer l'index des classes :
- 1.6 : supprimer `cache/class_index.php`
- 1.7 / 8 / 9 : supprimer `var/cache/*/class_index.php` (ou vider `var/cache/`).

Vérifier aussi que les overrides ne sont pas désactivés dans le BO.
