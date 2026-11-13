# Paramétrer un module existant (menu, liens, blocs…)

Changer les **données** d'un module installé (liens du menu, blocs du footer, textes, slides, positions) sans passer par le BO. Ce n'est pas du développement : on écrit dans la base d'une boutique.

## Quand

- **Jamais par défaut.** Pendant une intégration, demander une fois au départ : « intégration seule (templates, CSS) ou aussi paramétrage des modules ? ». Noter la réponse dans `PRESTASHOP.md` § Intégration.
- Même avec un oui, annoncer la liste des modules qu'on va paramétrer et ce qu'on va y changer avant de commencer.
- Boutique locale ou de préproduction. Sur une production : seulement si l'utilisateur le demande explicitement pour cette boutique.

## 1. Lire le module avant d'écrire

Chaque module stocke ses données à sa façon : clés `Configuration`, tables propres (`<prefixe>_<table>`, `_lang`, `_shop`), fichiers (images dans le dossier du module). Le savoir **dans le code**, pas de mémoire :

- `getContent()` / `postProcess()` / `processSave*()`, ou le controller admin et les formulaires Symfony du module (1.7+) : ce qu'ils écrivent et avec quelles méthodes.
- `install()` et les fichiers SQL : tables et clés créées.
- Les classes du module (`classes/`, `src/`) : ObjectModel ou repository à réutiliser.

Écrire **avec les mêmes méthodes que le module** (`Configuration::updateValue`, ses ObjectModel, son repository). SQL direct (`Db::getInstance()->update/insert`, `_DB_PREFIX_`, `pSQL`/cast) seulement si le module fait lui-même ainsi. Après écriture, appeler la méthode de vidage de cache du module si elle existe (souvent `_clearCache`), puis vider le cache.

Lecture de la base : colonnes et clés précises seulement (règles de SKILL.md § Données sensibles).

Module sans logique lisible (chiffré, ioncube, très complexe) : ne pas écrire au hasard ; donner à l'utilisateur la liste des réglages à faire dans le BO.

## 2. Script temporaire en ligne de commande

- Écrit **hors de la racine web** de la boutique (dossier temporaire / scratchpad) : la racine PrestaShop est publique, un `.php` posé là s'exécute depuis le navigateur.
- Refuse tout autre mode que la CLI, charge la boutique par chemin absolu.
- **Simulation par défaut** : affiche « ancienne valeur → nouvelle valeur » sans rien écrire. `--apply` seulement après accord de l'utilisateur sur ce diff.
- Avant d'écrire, sauvegarde les anciennes valeurs (lignes concernées des tables du module comprises) dans un JSON à côté du script.
- Rejouable : relancé, il ne crée pas de doublon (comparer avant d'insérer).
- Supprimé à la fin (garder la sauvegarde jusqu'à validation de l'utilisateur).

Squelette (clés `Configuration` ; pour des tables du module, même schéma avec ses classes) :

```php
<?php
// Temporaire : paramétrage de <module>. À supprimer après usage.
if (PHP_SAPI !== 'cli') {
    exit(1);
}
require '/chemin/absolu/boutique/config/config.inc.php';

$apply = in_array('--apply', $argv, true);
$changes = [
    // 'CLE_LUE_DANS_LE_MODULE' => 'nouvelle valeur',
];

$backup = [];
foreach ($changes as $key => $new) {
    $old = Configuration::get($key);
    if ((string) $old === (string) $new) {
        continue;
    }
    $backup[$key] = $old;
    echo $key . ' : ' . var_export($old, true) . ' -> ' . var_export($new, true) . PHP_EOL;
}

if (!$backup) {
    exit("Rien à changer.\n");
}
if (!$apply) {
    exit("Simulation. Relancer avec --apply pour écrire.\n");
}
$file = __DIR__ . '/backup-' . date('YmdHis') . '.json';
file_put_contents($file, json_encode($backup, JSON_PRETTY_PRINT)) or exit("Sauvegarde impossible, rien écrit.\n");
foreach (array_keys($backup) as $key) {
    Configuration::updateValue($key, $changes[$key]);
}
echo 'Appliqué. Sauvegarde : ' . $file . PHP_EOL;
```

- Valeurs traduisibles : `Configuration::get($key, $idLang)` et `updateValue($key, [$idLang => $valeur])`, pour chaque langue active.
- Multiboutique : fixer le contexte (`Shop::setContext(...)`) et passer `$idShopGroup` / `$idShop` comme le fait le module.
- Lancer avec le même PHP que la boutique (conteneur, version) : `php script.php`, puis `php script.php --apply`.

## 3. Après

- Vérifier en front que le rendu correspond, vider le cache.
- Noter dans `PRESTASHOP.md` ce qui a été paramétré (module, réglage, date), sans valeur sensible.
- Dire à l'utilisateur que ces réglages sont **dans la base** de cette boutique : ils ne suivent pas le code et sont à refaire ou à migrer vers les autres environnements.
