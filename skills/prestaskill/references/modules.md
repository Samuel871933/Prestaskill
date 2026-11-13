# Modules

## Préfixe

Lu depuis `PRESTASHOP.md` → section « Conventions » (ex. `abc`). Si absent : demander, puis l'écrire dans ce fichier.

| Élément | Convention | Exemple (`prefix: abc`) |
|---|---|---|
| Nom technique / dossier / fichier principal | `<prefix><nom>`, minuscules, alphanumérique, sans `_` ni `-` | `modules/abcfaq/abcfaq.php` |
| Classe principale | même nom que le dossier (casse libre) | `class AbcFaq extends Module` |
| Namespace (`src/`, PSR-4 via composer) | `<namespace>\Module\<Nom>\` | `MaSociete\Module\Faq\` |
| Tables | `_DB_PREFIX_ . '<prefix>_<nom>'` | `ps_abc_faq`, `ps_abc_faq_lang` |
| Clés `Configuration` | `<PREFIX>_<NOM>_<CLE>` majuscules, courtes | `ABC_FAQ_NB_ITEMS` |
| Hooks custom | `display<Prefix><Nom>` / `action<Prefix><Nom>` | `displayAbcFaqAfterList` |
| Classes ObjectModel / onglets admin | `<Prefix><Nom>` | `AbcFaqItem`, `AdminAbcFaq` |

`author` du module = auteur des Conventions. `ps_versions_compliancy` = versions cibles des Conventions.

## Structure de base (1.7+)

```
abcfaq/
├── abcfaq.php           # classe principale
├── config.xml           # généré par PS, ne pas versionner si inutile
├── logo.png             # 32x32 (1.6) / 64x64 (1.7+)
├── composer.json        # autoload PSR-4 + "config": {"prepend-autoloader": false}
├── config/              # services.yml, routes.yml (1.7.5+)
├── controllers/front/   # ModuleFrontController legacy
├── controllers/admin/   # ModuleAdminController legacy
├── src/                 # code namespacé (Controller Symfony, Entity, Grid, Form…)
├── sql/                 # install.php / uninstall.php (ou dans la classe)
├── translations/
├── upgrade/             # upgrade-1.1.0.php → function upgrade_module_1_1_0($module)
└── views/
    ├── templates/{front,admin,hook}/
    ├── css/ js/ img/
```

1.6 : pas de `src/` ni `config/*.yml` ; tout en legacy.

## Classe principale — squelette

```php
<?php
if (!defined('_PS_VERSION_')) {
    exit;
}

class AbcFaq extends Module
{
    public function __construct()
    {
        $this->name = 'abcfaq';
        $this->tab = 'front_office_features';
        $this->version = '1.0.0';
        $this->author = 'Ma Société';
        $this->need_instance = 0;
        $this->ps_versions_compliancy = ['min' => '8.0.0', 'max' => _PS_VERSION_];
        $this->bootstrap = true;
        parent::__construct();
        $this->displayName = $this->trans('FAQ', [], 'Modules.Abcfaq.Admin');
        $this->description = $this->trans('…', [], 'Modules.Abcfaq.Admin');
    }

    public function install()
    {
        return parent::install()
            && $this->installDb()
            && $this->registerHook(['displayFooter', 'actionFrontControllerSetMedia'])
            && Configuration::updateValue('ABC_FAQ_NB_ITEMS', 10);
    }

    public function uninstall()
    {
        return $this->uninstallDb()
            && Configuration::deleteByName('ABC_FAQ_NB_ITEMS')
            && parent::uninstall();
    }

    // 1.7.6+ : sans ça, les chaînes trans() du module n'apparaissent pas dans l'interface de traduction du BO
    public function isUsingNewTranslationSystem()
    {
        return true;
    }
}
```

Adapter : `$this->l()` au lieu de `trans()` avant 1.7.6 (et retirer `isUsingNewTranslationSystem`) ; `array()` si PHP 5.3.

Onglets admin, hooks custom, front controllers, emails, commandes console, webservice : [module-types.md](module-types.md).

## Règles

- Guard `_PS_VERSION_` en tête de chaque fichier PHP (security.md § 3).
- Un `index.php` de protection dans **chaque** dossier du module (exigé par le validateur Addons, bloque le listage).
- Mise à jour du schéma ou de la config d'un module déjà installé → script `upgrade/upgrade-X.Y.Z.php` + bump de `version`. Ne jamais compter sur une réinstallation.
- Hooks : avant d'en enregistrer un, `grep` son nom dans le core de la version cible (`Hook::exec('nomDuHook'` ou `{hook h='nomDuHook'` dans le thème). Les noms sont listés en BDD (`ps_hook`) mais un hook peut exister en BDD sans jamais être appelé.
- Données traduisibles → table `_lang` + `ObjectModel::$definition['multilang' => true]`. Par boutique → `_shop` + `Shop::addTableAssociation`.
- Formulaires de configuration : `HelperForm` (toutes versions) ou Symfony Form + `config/services.yml` (1.7.6+/8/9 — préférer ça en 8/9).
- Listes admin : `HelperList` (legacy) ou Grid Symfony (1.7.6+/8/9 — préférer en 8/9).
- Assets BO : hook `actionAdminControllerSetMedia` (toutes versions, 1.6.1 compris ; pages Symfony en 8+ via `LegacyControllerBridge`, grep si doute), `$this->context->controller->addCSS()` / `addJS()`, et seulement sur les pages du module (ex. `Tools::getValue('configure') === $this->name` ou le controller du module), pas sur tout le BO.
- Fiche produit BO : voir le fichier de la version (8 / 9), les hooks dépendent de la page produit utilisée.

## Doc à WebFetch selon le besoin (remplacer `<v>` par 1.7, 8 ou 9)

- Démarrage module : `https://devdocs.prestashop-project.org/<v>/modules/creation/`
- Liste des hooks : `https://devdocs.prestashop-project.org/<v>/modules/concepts/hooks/list-of-hooks/`
- Controllers admin Symfony : `https://devdocs.prestashop-project.org/<v>/modules/concepts/controllers/admin-controllers/`
- Services : `https://devdocs.prestashop-project.org/<v>/modules/concepts/services/`
- Grid / Form hooks : `https://devdocs.prestashop-project.org/<v>/development/components/grid/` et `…/components/form/`

Si une URL renvoie 404 : partir de `https://devdocs.prestashop-project.org/<v>/` et naviguer.

## Module compatible multi-versions

- Fixer `ps_versions_compliancy` honnêtement.
- Brancher par feature, pas par numéro, quand c'est possible : `method_exists()`, `class_exists()`, `interface_exists()`.
- Sinon `version_compare(_PS_VERSION_, '1.7.6', '>=')`.
- Code PHP écrit pour le PHP **minimum** de la plage.
- Hooks : enregistrer ceux de toutes les versions visées (ex. `displayHeader` 1.6 + `actionFrontControllerSetMedia` 1.7+) — enregistrer un hook inexistant est sans effet.
