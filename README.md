# prestaskill

Un skill [Claude Code](https://claude.com/claude-code) pour développer sur **PrestaShop 1.6, 1.7, 8 et 9** : modules, overrides, hooks, thèmes et thèmes enfants.

Sans consignes, un agent IA code PrestaShop « de mémoire » : il mélange les versions, abuse des overrides, modifie le core ou le thème parent, et oublie la sécurité. Ce skill l'oblige à suivre la méthode d'un développeur PrestaShop expérimenté.

## Ce que fait le skill

**1. Il détecte la version avant d'écrire du code.**
La version de PrestaShop est lue dans le code de la boutique (`src/Core/Version.php`, `app/AppKernel.php` ou `config/settings.inc.php`), puis l'agent applique les règles de cette version (PHP, Symfony, thème par défaut, commande de vidage du cache, pièges connus).

**2. Il vérifie au lieu de deviner.**
Avant d'utiliser un hook ou une méthode, l'agent vérifie qu'il existe dans le core installé, puis consulte la doc officielle de la version ([devdocs.prestashop-project.org](https://devdocs.prestashop-project.org/)). Les points incertains sont marqués *(à vérifier)* dans le skill, ce qui force cette recherche.

**3. Il tient une mémoire du projet, `PRESTASHOP.md`.**
Un fichier court à la racine du projet, que l'agent lit en premier et met à jour après chaque tâche :

- conventions (préfixe, auteur, namespace, versions cibles) ;
- environnement (version, PHP, préfixe des tables, thème actif et son parent, overrides) ;
- modules du projet avec leurs hooks, tables et clés de config ;
- fichiers surchargés dans le thème enfant ;
- décisions techniques et leur raison.

L'agent n'a plus besoin de réexplorer tout le projet à chaque session, ce qui économise des tokens. Le fichier peut être versionné et partagé avec l'équipe.

Pour le remplir sans explorer, le script `scripts/scan.sh` fait un relevé en une vingtaine de lignes :

```
## Scan 2026-11-13
- PrestaShop : 8.1.7
- PHP CLI : 8.4.27
- Préfixe tables : ps_
- Thèmes (actif d'après config/themes/ : montheme — à confirmer) :
  - classic
  - montheme (enfant de classic) [build: _dev/]
- Modules : 74 dossiers
  Modules du projet (préfixe 'abc') :
  - abcfaq v1.2.0 [embarque des overrides]
- Overrides actifs :
  - override/classes/Cart.php
```

**4. Il impose un préfixe partout.**
Le préfixe est demandé une fois par projet, puis appliqué partout :

| Élément | Exemple avec le préfixe `abc` |
|---|---|
| Dossier du module | `modules/abcfaq/` |
| Table en base | `ps_abc_faq`, `ps_abc_faq_lang` |
| Clé de configuration | `ABC_FAQ_NB_ITEMS` |
| Hook personnalisé | `displayAbcFaqAfterList` |
| Namespace | `MaSociete\Module\Faq\` |

**5. Il applique des principes de développement.**

- Une fonctionnalité correspond à un module dédié, qui se désinstalle proprement.
- Avant de coder, l'agent vérifie si un module existant peut faire le travail par configuration.
- Le thème ne sert qu'à l'affichage : pas de logique métier ni de SQL dans les templates.
- Rien n'est écrit en dur : IDs, emails, montants et textes sont configurables en BO et traduisibles.
- L'ordre de préférence pour modifier un comportement est : hook, puis service Symfony, puis surcharge de template, puis override en dernier recours, avec justification.
- Une nouvelle fonctionnalité va dans un module dédié ; si un hook ou un service ne suffit pas, override.
- Pour modifier un module existant (natif ou acheté), on ne touche jamais à son dossier : le PHP est surchargé dans `/override/` à la racine (`override/classes/`, `override/controllers/`, `override/modules/<module>/`), les tpl, CSS et JS dans le thème actif (`themes/<actif>/modules/<module>/`). Le skill indique l'arborescence et le nommage exacts (`ProductCore`, `<Module>Override`…), ainsi que la surcharge des templates Twig du BO.
- Le code est écrit pour la version de PHP minimale de la plage cible. Une table de compatibilité PHP par version de PrestaShop (1.6.1 → 9.1, d'après la doc officielle) aide aussi à diagnostiquer les bugs liés à PHP.
- Les règles de performance couvrent les requêtes en boucle, les hooks appelés sur chaque page et le cache.

**6. Il fait une revue de sécurité à chaque développement.**
La checklist couvre 9 points propres à PrestaShop : injection SQL, XSS, fichiers PHP appelables directement (`ajax.php`, `vendor/`…), CSRF, droits d'accès et open redirect, accès aux données d'un autre client (IDOR), validation des entrées, upload, secrets et données personnelles, désinstallation. L'agent la repasse sur son code et détaille les points corrigés ou à risque (le reste est résumé en une ligne).

**7. Il protège les données sensibles.**
L'agent a pour consigne de ne jamais lire les fichiers de configuration contenant des identifiants (`parameters.php`, `settings.inc.php`, `.env`), les dumps SQL, les logs ou les fichiers clients. Il ne doit pas non plus faire de `SELECT *` sur les tables clients, commandes ou configuration. Le script de scan n'extrait que le préfixe des tables.

> Installé en plugin, un hook bloque techniquement la lecture de ces fichiers. Avec `install.sh`, ce ne sont que des consignes : voir [Renforcer la protection](#renforcer-la-protection-des-données-sensibles).

**8. Il couvre les thèmes, quels qu'ils soient.**
Classic, Hummingbird ou thème acheté : le skill décrit l'héritage parent/enfant, `{extends file='parent:…'}`, la surcharge des templates de modules depuis le thème et le build des assets (`_dev/`). Il interdit de modifier directement un thème acheté.

## Installation

Prérequis : [Claude Code](https://claude.com/claude-code), bash. PHP est optionnel, pour `php -l` et la détection de la version de PHP.

### En plugin (recommandé)

Dans Claude Code :

```
/plugin marketplace add Samuel871933/Prestaskill
/plugin install prestaskill@prestaskill
```

Le plugin installe le skill **et** deux hooks, actifs seulement dans un projet PrestaShop (présence de `PRESTASHOP.md`, `classes/ObjectModel.php`, `app/AppKernel.php` ou `config/settings.inc.php`) :

- **blocage des fichiers sensibles** : toute lecture (Read, Grep, Bash) de `parameters.php/yml`, `settings.inc.php`, `.env*`, dumps `.sql` (hors `modules/*/sql/`), `backups/` ou `.htpasswd` est refusée ; seul `scan.sh` peut en extraire le préfixe des tables ;
- **`php -l` automatique** après chaque modification d'un fichier PHP ; l'agent ne voit que les erreurs.

Mises à jour : `/plugin marketplace update prestaskill`.

### Avec install.sh (skill seul, sans hooks)

```bash
git clone https://github.com/Samuel871933/Prestaskill.git prestaskill
cd prestaskill
./install.sh
```

Le skill est installé dans `~/.claude/skills/prestaskill` et devient disponible dans tous vos projets.

Pour l'installer dans un seul projet, par exemple pour le partager avec l'équipe via git :

```bash
./install.sh --project /chemin/vers/ma-boutique
```

Il est alors installé dans `/chemin/vers/ma-boutique/.claude/skills/prestaskill`.

Vous pouvez aussi l'installer à la main en copiant `skills/prestaskill/` dans `~/.claude/skills/`.

Si un skill `prestaskill` existe déjà, `install.sh` le sauvegarde dans `.claude/prestaskill.bak.<date>` avant de le remplacer.

Ouvrez ensuite une nouvelle session Claude Code.

## Utilisation

Le skill se déclenche tout seul quand vous travaillez dans un projet PrestaShop ou que vous parlez de module, hook, override ou thème PrestaShop. Vous pouvez aussi l'appeler explicitement avec `/prestaskill` (`/prestaskill:prestaskill` en plugin).

Exemples :

```
crée un module de FAQ produit avec une page de configuration en BO
ajoute un bandeau de réassurance sous le bouton "ajouter au panier"
crée un thème enfant de classic et change le header
pourquoi mon override de Cart n'est pas pris en compte ?
```

À la première utilisation dans un projet, l'agent lance le scan, vous demande le préfixe, l'auteur et le namespace, puis crée `PRESTASHOP.md`.

## Renforcer la protection des données sensibles

Inutile si vous avez installé le plugin (le hook s'en charge). Avec `install.sh`, pour qu'un fichier soit vraiment illisible par l'outil de lecture, ajoutez des règles `deny` dans `~/.claude/settings.json` (ou `.claude/settings.json` du projet) :

```json
{
  "permissions": {
    "deny": [
      "Read(**/app/config/parameters.php)",
      "Read(**/app/config/parameters.yml)",
      "Read(**/config/settings.inc.php)",
      "Read(**/.env*)",
      "Read(**/*.sql)",
      "Read(**/*.sql.gz)"
    ]
  }
}
```

Le script de scan continue de fonctionner, car il extrait uniquement la ligne du préfixe avec `grep`.

## Structure

```
prestaskill/
├── .claude-plugin/               # plugin.json + marketplace.json
├── hooks/                        # hooks.json, guard-secrets.sh, php-lint.sh, is-ps-project.sh, test-hooks.sh
├── evals/plugin/                 # cas pour `claude plugin eval`
├── install.sh                    # installation sans plugin
├── README.md
├── LICENSE
└── skills/prestaskill/
    ├── SKILL.md                  # point d'entrée : méthode, principes, règles
    ├── scripts/scan.sh           # relevé factuel du projet
    └── references/               # chargés seulement quand la tâche le demande
        ├── versions/             # un fichier par version : 1.6, 1.7, 8, 9 + php.md (compatibilité PHP)
        ├── modules.md            # préfixes, structure, squelette, hooks
        ├── module-types.md       # onglets, hooks custom, front controllers, emails, console, webservice (paiement/transport : hors périmètre)
        ├── overrides.md          # quand et comment overrider (/override/, modules, Twig BO)
        ├── themes.md             # héritage, surcharges de templates
        ├── integration.md        # maquettes → pages, composants communs, CSS parent, tunnel, emails, PDF
        ├── module-config.md      # paramétrer un module installé par script CLI (simulation, sauvegarde)
        ├── security.md           # checklist de sécurité
        └── project-file.md       # format de PRESTASHOP.md
```

Seul `SKILL.md` est chargé au déclenchement. Les fichiers de `references/` ne sont lus que si la tâche les concerne (et seulement celui de la version détectée), ce qui limite la consommation de tokens. Les points vérifiés sont notés dans `PRESTASHOP.md` pour ne pas refaire la recherche, et un sous-agent reçoit ce contexte au lieu de réexplorer le projet.

## Limites

- Le contenu a été écrit à partir des connaissances générales sur PrestaShop. Les points incertains sont marqués *(à vérifier)* et l'agent est censé les vérifier dans la doc ou le core. Les corrections sont bienvenues.
- Le thème actif est stocké en base de données : en 1.7+, le scan le déduit de `config/themes/` (à confirmer) ; en 1.6, l'agent vous le demande.
- Le scan a été testé sur une arborescence PrestaShop 8, pas encore sur des boutiques 1.6 et 1.7 réelles.

## Contribuer

Les issues et pull requests sont les bienvenues, en particulier pour :

- corriger un point *(à vérifier)* avec un lien vers la doc officielle ;
- ajouter un piège rencontré sur une version précise ;
- tester `scan.sh` sur d'autres versions.

Avant une PR : `bash hooks/test-hooks.sh` (gratuit). Pour vérifier que le skill se déclenche au bon moment : `claude plugin eval . --no-publish` (consomme des tokens).

Gardez les fichiers courts : chaque ligne du skill coûte des tokens à chaque utilisation.

## Licence

[MIT](LICENSE)
# Prestaskill
