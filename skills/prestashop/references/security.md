# Sécurité — checklist à chaque développement

La plupart des failles publiées sur des modules PrestaShop sont des injections SQL et des fichiers PHP accessibles directement. Repasser **chaque point** sur le code ajouté ou modifié, et rapporter le résultat (OK / corrigé / non applicable).

## 1. Injection SQL
- Toute valeur venant de l'extérieur (`Tools::getValue`, cookie, `$_SERVER`, webservice, fichier importé) est castée ou échappée **au moment** de la requête : `(int)`, `(float)`, `pSQL()` pour les chaînes, `bqSQL()` pour les noms de colonnes/tables.
- `ORDER BY` / `LIMIT` / noms de colonnes dynamiques : liste blanche, jamais la valeur brute.
- `IN (...)` : `implode(',', array_map('intval', $ids))`.
- Préférer `DbQuery`, `Db::insert/update` avec données échappées, ou Doctrine (1.7+) avec paramètres liés.

## 2. XSS
- Smarty : `{$var|escape:'html':'UTF-8'}` (attributs : `'htmlall'`). `nofilter` seulement sur du HTML produit par le core ou nettoyé.
- Twig : pas de `|raw` sur une donnée utilisateur.
- Vers le JS : `Media::addJsDef()` ou `json_encode`, jamais de concaténation dans un `<script>`.
- Contenu riche saisi en BO : `Validate::isCleanHtml()`.

## 3. Accès direct et points d'entrée
- `if (!defined('_PS_VERSION_')) { exit; }` en tête de chaque fichier PHP.
- **Aucun script PHP appelable directement** à la racine du module (`ajax.php`, `cron.php`, `export.php`…). Utiliser un `ModuleFrontController` (avec `ajax = true` si besoin) ou une route Symfony admin.
- Tâche cron : front controller protégé par un token secret aléatoire stocké en `Configuration`, comparé avec `hash_equals`.
- `vendor/` et dossiers internes du module : `index.php` dans chaque dossier + `.htaccess` `Deny from all` / `Require all denied` sur `vendor/`.

## 4. CSRF et autorisations
- Admin legacy (`ModuleAdminController`) : token vérifié par le core — ne pas le désactiver ; vérifier les droits (`$this->access('edit')`) avant toute action qui modifie.
- Admin Symfony : formulaires avec CSRF (par défaut) ; protéger chaque action avec `AdminSecurity` (annotation 1.7/8, attribut en 9 — *à vérifier*).
- Page de configuration du module (`getContent`) : valider chaque champ avant `Configuration::updateValue`.
- Front, action qui modifie des données : vérifier le token (`Tools::getToken(false)`) et que le client est connecté si nécessaire.
- AJAX côté BO : vérifier l'employé connecté (`$this->context->employee`) et ses droits, pas seulement le token.
- Redirection : jamais `Tools::redirect()` vers une URL venant de la requête (open redirect) → liste blanche ou URL construite par `$link`.

## 5. Contrôle de propriété (IDOR)
- Tout objet chargé par un ID venant de la requête (commande, adresse, panier, fichier, retour…) : vérifier qu'il appartient au client courant (`$order->id_customer == $this->context->customer->id`) ou à la boutique courante, et `Validate::isLoadedObject()`.

## 6. Validation des entrées
- `Tools::getValue()` ne valide rien : utiliser `Validate::isEmail`, `isUnsignedId`, `isGenericName`, `isUrl`… selon le type attendu, et rejeter sinon.
- Jamais `unserialize()` sur une donnée externe → `json_decode`.
- Jamais `eval`, `exec`, `system`, `shell_exec`, `include` d'un chemin construit avec une entrée.
- Chemins de fichiers : `basename()` + liste blanche de dossiers ; refuser `..`.

## 7. Upload de fichiers
- Vérifier extension **et** type MIME réel (liste blanche), taille max ; images : `ImageManager::validateUpload()` / `isRealImage()`.
- Renommer avec un nom aléatoire ; stocker hors des dossiers exécutables ; `.htaccess` qui interdit l'exécution PHP dans le dossier d'upload du module.

## 8. Secrets et données personnelles
- Clés API et mots de passe dans `Configuration` (saisis en BO), jamais dans le code ni dans git.
- Pas de données personnelles (email, adresse, IP) dans les logs (`PrestaShopLogger`) ni dans les messages d'erreur affichés.
- Réponses AJAX : renvoyer uniquement les champs nécessaires, jamais l'objet `Customer` / `Address` entier.
- Mode debug (`_PS_MODE_DEV_`) jamais activé par le code du module.

## 9. Désinstallation
- `uninstall()` supprime les tables, les clés de config, les fichiers uploadés propres au module et les onglets ; pas de données orphelines contenant des infos clients.
