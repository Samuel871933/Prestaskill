---
name: prestaskill
description: Développement PrestaShop 1.6 à 9 — modules, overrides, hooks, thèmes (enfants, Classic, Hummingbird, du commerce), templates Smarty/Twig, controllers, intégration de maquettes. Utilise-le pour toute tâche sur un projet PrestaShop (classes/ObjectModel.php, app/AppKernel.php, config/settings.inc.php) ou quand l'utilisateur parle de PrestaShop, module PS, override, hook, thème PS, tpl Smarty, ou d'intégrer des maquettes dans PrestaShop.
allowed-tools: Bash(bash *scan.sh*)
---

# PrestaShop

Tu travailles sur PrestaShop. Le comportement correct dépend **de la version** : une règle vraie en 1.6 peut être fausse en 9. Ne code jamais "de mémoire" sans avoir fait les étapes 1 à 3.

## Étape 0 — Lire `PRESTASHOP.md` (mémoire du projet)

S'il existe à la racine du projet, lis-le **avant tout** et fais-lui confiance : version, préfixes, thème, modules du projet, overrides, décisions. N'explore le code que pour ce qu'il ne dit pas. S'il manque, crée-le dès que la tâche modifie le projet (pas pour une simple question). À la fin de chaque tâche qui change quelque chose, mets-le à jour. Format et règles : `references/project-file.md`.

Si `PRESTASHOP.md` donne déjà la version et la config, saute les étapes 1 et 2.

## Étape 1 — Détecter la version (obligatoire, avant toute ligne de code)

Lance `bash <dossier de ce skill>/scripts/scan.sh <racine> [prefixe]` (pas d'exploration manuelle) : version, PHP, préfixe des tables, thèmes (+ actif si détectable), modules du projet, overrides ; pour un module isolé, son `ps_versions_compliancy`. Si rien n'en sort, demande la plage cible.

Ensuite lis **uniquement** le fichier de la version : `references/versions/<1.6|1.7|8|9>.md`.

## Étape 2 — Conventions du projet

Préfixe des modules, auteur, namespace et versions cibles sont dans la section « Conventions » de `PRESTASHOP.md`. S'ils manquent et que la tâche crée un module, une table, une clé de config ou un hook custom : **demande-les** à l'utilisateur (ne devine pas), puis écris-les dans `PRESTASHOP.md`. Le préfixe s'applique partout — voir `references/modules.md` (Préfixe).

## Étape 3 — Vérifier dans la source de vérité

Ordre de confiance, du plus fiable au moins fiable :

1. **Le code du core installé** (`classes/`, `controllers/`, `src/`, `themes/<parent>/`). Avant d'appeler, surcharger ou hooker quelque chose, `grep` pour confirmer que la méthode/le hook existe *dans cette version* et lis sa signature. Ex : `grep -rn "Hook::exec('displayProductAdditionalInfo'" classes controllers src`.
2. **La doc officielle de la version** : `https://devdocs.prestashop-project.org/<1.7|8|9>/` (1.6 : `https://doc.prestashop.com/display/PS16/Developer+Guide`). Fais un WebFetch de la page pertinente quand la tâche touche un point marqué *(à vérifier)*, ou dès que tu as un doute — sauf si `PRESTASHOP.md` contient déjà la réponse. Une fois vérifié, note le résultat en une ligne dans `PRESTASHOP.md` (« Décisions / pièges ») pour ne pas refaire la recherche.
3. **Modules officiels comme modèles** : les modules natifs présents dans `modules/` (ps_*), et `https://github.com/PrestaShop/example-modules`.
4. Ce skill, puis ta mémoire — en dernier, et signale à l'utilisateur ce que tu n'as pas vérifié.

**Ce skill n'est pas la vérité absolue.** Il a été relevé à une date donnée (2026-11, jusqu'à PrestaShop 9.2) ; PrestaShop évolue. Si le core installé ou la doc officielle le contredit, ils ont raison : suis-les et note l'écart dans `PRESTASHOP.md` (« Décisions / pièges »). Version plus récente que celles couvertes ici → traite le skill comme une piste et vérifie chaque point. **Si quelque chose ne fonctionne pas** (hook jamais appelé, chemin de tpl ignoré, asset non chargé…), ne réessaie pas la même chose : vide le cache, puis vérifie dans le core (grep de l'appel, lecture de la méthode) et en conditions réelles (mode debug, logs que l'utilisateur te montre, rendu front/BO) avant de conclure.

## Données sensibles — interdit de lire

Jamais (ni Read, ni cat, ni grep) : `app/config/parameters.{php,yml}`, `config/settings.inc.php`, `.env*`, dumps `*.sql*` et `backups/`, `var/logs/`, `log/`, `download/`, `upload/`, `.htpasswd`, fichiers de credentials des modules. Le préfixe des tables s'obtient par `scan.sh`. Installé en plugin, un hook bloque déjà tous ces chemins sauf `download/`, `upload/` et les credentials des modules.

BDD : jamais `SELECT *` sur `customer`, `address`, `orders`, `employee`, `connections`, `guest`, `configuration` ; colonnes précises non personnelles + `LIMIT` ; clients de test factices.

Si une tâche l'exige, **demande d'abord** en expliquant pourquoi. Ne recopie jamais un secret (code, commit, `PRESTASHOP.md`, réponse).

## Principes de développement

1. **Une fonctionnalité = un module.** Chaque fonctionnalité métier vit dans un module dédié, préfixé, autonome et désinstallable proprement. Ne pas empiler des fonctionnalités sans rapport dans un même module « fourre-tout ».
2. **Réutiliser avant de développer.** Avant de créer un module, vérifier (PRESTASHOP.md, `modules/`, BO) si un module natif ou déjà installé fait le travail par configuration. Le proposer à l'utilisateur plutôt que de coder.
3. **Le thème ne fait que de la présentation.** Aucune logique métier, requête SQL ou calcul dans les templates : les variables sont préparées dans le hook, widget ou controller du module.
4. **Rien en dur.** IDs (catégories, CMS, transporteurs…), emails, montants, textes → clés `Configuration` éditables dans la page de configuration du module, et chaînes traduisibles.
5. **Performance.** Pas de requête SQL dans une boucle ; attention aux hooks appelés sur chaque page (`displayHeader`, `actionFrontControllerSetMedia`, `actionDispatcher`) : y faire le minimum et charger les assets seulement sur les pages concernées ; mettre en cache ce qui est coûteux (`Cache::store`, `isCached()` Smarty).
6. **Pas de dépendance inutile.** Composer seulement si nécessaire ; alors `vendor/` livré avec le module et `"prepend-autoloader": false`.

## Règles non négociables (toutes versions)

1. **Ne jamais modifier le core** (`classes/`, `controllers/`, `src/`, `vendor/`, `admin*/`, ni le thème parent). Tout passe par module, override, ou thème enfant.
2. **Ordre de préférence pour changer un comportement** : hook existant → service Symfony / décoration (1.7.5+ selon zone) → surcharge de template dans le thème → override de classe/controller **en dernier recours**. Justifie tout override.
   - Modifier un module existant (natif ou acheté) → jamais dans son dossier : PHP dans `/override/modules/<module>/…`, tpl/CSS/JS dans le **thème actif** (`themes/<actif>/modules/<module>/…`).
   - Override PHP → toujours dans `/override/` à la racine (arborescence et nommage : `references/overrides.md`).
3. **Sécurité** : appliquer `references/security.md` en écrivant le code, puis repasser la checklist avant de rendre la main.
4. **Installation réversible** : tout ce que `install()` crée (tables, config, onglets, hooks, overrides), `uninstall()` le supprime. Les deux retournent un booléen et s'arrêtent au premier échec.
5. **Multiboutique et multilingue** : utiliser `Configuration::updateValue` avec le contexte shop, et des tables `_lang` / `_shop` quand la donnée est traduisible ou par boutique. Textes via `$this->trans()` (1.7.6+) ou `$this->l()` (1.6/legacy).
6. **Après modification** d'un override, d'un service, d'une route ou d'un template : vider le cache (voir le fichier de la version) avant de conclure que "ça ne marche pas".
7. **Compatibilité PHP** : écrire pour le PHP **minimum** de la plage cible (table dans `references/versions/php.md`). Bug inexpliqué (deprecated, fatal, page blanche) → comparer d'abord le PHP du serveur à cette table.

## Selon la tâche, lis

| Tâche | Fichier |
|---|---|
| Créer / modifier un module, hooks, config, BDD, controllers | [references/modules.md](references/modules.md) |
| Onglets admin, hook custom, front controller, emails, commande console, webservice, qualité · paiement / transporteur (hors périmètre) | [references/module-types.md](references/module-types.md) |
| Override de classe, controller ou module | [references/overrides.md](references/overrides.md) |
| Thème, thème enfant, templates, assets, surcharge de tpl de module | [references/themes.md](references/themes.md) |
| Intégrer des maquettes (pages, composants communs, positions des modules, JS après AJAX, CSS du parent, tunnel, emails, PDF) | [references/integration.md](references/integration.md) |
| Paramétrer un module installé (menu, liens, blocs, textes) sans le BO | [references/module-config.md](references/module-config.md) |
| Différences et pièges de la version | `references/versions/<version>.md` |
| Compatibilité PHP, bug lié à la version de PHP | `references/versions/php.md` |
| Tout développement (checklist de fin) | [references/security.md](references/security.md) |
| Créer / mettre à jour PRESTASHOP.md | `references/project-file.md` |

## Vérification avant de rendre la main

- **Revue sécurité** : relire tout le code ajouté ou modifié avec la checklist de [references/security.md](references/security.md) et corriger. Dans la réponse finale, ne détailler que les points corrigés ou à risque, puis une ligne « Autres points : OK / non applicable ».
- `php -l` sur chaque fichier PHP modifié (automatique si le skill est installé en plugin : une erreur s'affiche d'elle-même).
- `PRESTASHOP.md` mis à jour.
- Si une boutique est disponible : installer / réinstaller le module (`php bin/console prestashop:module install <nom>` en 1.7+, sinon BO), vider le cache, puis **tester réellement** ce qui a été fait (page front ou BO concernée, action déclenchée, désinstallation propre). Écrit ≠ fonctionnel.
- Dire explicitement ce qui n'a pas pu être testé (pas de boutique, pas de BDD, etc.).

## Déléguer à un sous-agent

Un sous-agent démarre sans contexte : mets dans son prompt la version, les Conventions et les sections utiles de `PRESTASHOP.md`, et dis-lui de ne pas relancer le scan ni explorer ce qui y est déjà.
