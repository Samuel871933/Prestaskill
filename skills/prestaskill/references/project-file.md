# PRESTASHOP.md — mémoire du projet

Fichier à la racine du projet (boutique ou module isolé). Il remplace l'exploration du code à chaque session : **lis-le en premier, mets-le à jour en dernier**.

## Règles

- **Court** : viser < 150 lignes. Une ligne par fait. Pas de code, pas de copie de doc, pas de liste des modules natifs.
- **Jamais de secret** : ni mot de passe BDD, ni clé API, ni cookie_key. Seulement le préfixe des tables.
- **Factuel** : ce qui vient du scan est vrai à la date du scan ; ce qui vient de l'agent décrit ce qui a été *fait* ou *décidé*, pas ce qui est prévu.
- **Mise à jour à chaque tâche qui change** : un module (créé, hook ajouté, table, clé de config, version), un override, un fichier du thème enfant, une décision technique. Modifier la ligne existante plutôt que d'en ajouter une.
- **Si le fichier contredit le code**, le code a raison : corriger le fichier.

## Création

1. `bash <dossier du skill>/scripts/scan.sh <racine> <prefixe>` (préfixe vide si inconnu).
2. Demander à l'utilisateur ce que le scan ne peut pas savoir : préfixe des modules, auteur, namespace, versions cibles, thème actif (toujours le faire confirmer : le scan ne le déduit que de `config/themes/`).
3. Écrire le fichier selon le modèle ci-dessous.

Relancer le scan (pas d'exploration manuelle) quand la version, le thème ou les overrides semblent avoir changé, et remplacer la section « Environnement ».

## Modèle

```markdown
# PRESTASHOP.md
> Mémoire du projet pour Claude (skill prestaskill). Mis à jour le AAAA-MM-JJ.

## Conventions
- Préfixe modules : abc  · Namespace : MaSociete\Module\  · Auteur : Ma Société
- Versions cibles : 8.0.0 → 9.x  · PHP min : 8.1
- Overrides PHP : /override/ à la racine  · Tpl/assets : thème actif

## Environnement (scan AAAA-MM-JJ)
- PrestaShop 8.1.7 · PHP 8.1 · tables `ps_`
- Thème actif : montheme (enfant de classic, build _dev/)
- Overrides : override/classes/Cart.php (← abcpromo)

## Modules du projet
### abcfaq v1.2.0 — FAQ produit
- Hooks : displayProductAdditionalInfo, actionFrontControllerSetMedia
- Tables : abc_faq, abc_faq_lang · Config : ABC_FAQ_NB_ITEMS
- Admin : controller Symfony /abcfaq (config/routes.yml)

## Thème (montheme)
- Surchargés : catalog/product.tpl (blocs product_prices, product_add_to_cart), modules/ps_shoppingcart/…

## Décisions / pièges
- Vérifié AAAA-MM-JJ : hook actionProductFormBuilderModifier appelé en 8.1 (grep src/).
- AAAA-MM-JJ : override Cart::getOrderTotal plutôt que hook car aucun hook avant le calcul des règles panier.
```
