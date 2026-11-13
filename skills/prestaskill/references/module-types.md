# Briques de module courantes

Chaque point : le minimum, puis grep / WebFetch si la version est marquée *(à vérifier)*. Doc : `https://devdocs.prestashop-project.org/<v>/modules/`.

## Paiement et transporteur — hors périmètre de développement

Les modules de paiement (`PaymentModule`) et de transport (`CarrierModule`) se traitent à la main : **ne pas les générer ni les modifier**. Si la tâche en demande un, le dire à l'utilisateur et s'arrêter.

Seule leur **intégration** est couverte : rendu des étapes livraison / paiement du tunnel, logos, tpl du module surchargés dans le thème → [integration.md § Tunnel : livraison et paiement](integration.md).

## Onglets admin

- 1.7.1+ : propriété publique `$tabs` dans la classe principale ; PS crée les onglets à l'installation / reset, les désactive avec le module.

  ```php
  public $tabs = [[
      'class_name' => 'AdminAbcFaq',          // controller sans le suffixe Controller
      'route_name' => 'abcfaq_index',         // controller Symfony (1.7.7+), sinon omettre
      'parent_class_name' => 'AdminCatalog',
      'name' => 'FAQ',                        // ou ['en' => …, 'fr' => …], anglais en premier
      'wording' => 'FAQ', 'wording_domain' => 'Modules.Abcfaq.Admin', // 1.7.8+
      'visible' => true,
  ]];
  ```
- 1.6 / avant 1.7.1 : `new Tab()` dans `install()` (`class_name`, `module`, `id_parent` via `Tab::getIdFromClassName()`, `name` par langue) et suppression explicite dans `uninstall()`.
- Droits : chaque onglet génère les rôles `ROLE_MOD_TAB_<CLASSNAME>_{READ,CREATE,UPDATE,DELETE}` à utiliser dans `AdminSecurity`.

## Hook custom

- `registerHook()` crée déjà le hook s'il n'existe pas. `createHook` ne sert que pour un hook que le module **appelle** sans s'y greffer lui-même (pour qu'il apparaisse dans Apparence > Positions) :

  ```php
  // install()
  && (Hook::getIdByName('displayAbcFaqAfterList') || $this->createHook('displayAbcFaqAfterList'))

  private function createHook($name)
  {
      $hook = new Hook();
      $hook->name = $name;
      $hook->title = $name;
      return $hook->add();
  }
  ```
- Appel : `Hook::exec('actionAbcFaqSaved', ['item' => $item])` en PHP ; `{hook h='displayAbcFaqAfterList' product=$product}` en tpl.
- À la désinstallation, ne supprimer le hook que si aucun autre module ne s'y est greffé.

## Champs du formulaire client (front, 1.7+)

Grep les noms dans `classes/form/` avant de s'en servir *(à vérifier selon la mineure)*.

- Ajouter : `hookAdditionalCustomerFormFields($params)` retourne un tableau de `FormField` (`(new FormField())->setName('abc_siret')->setType('text')->setLabel(…)->setValue(<valeur enregistrée si client connecté>)`).
- Valider : `hookValidateCustomerFormFields($params)` reçoit les champs du module dans `$params['fields']` ; `$field->addError(…)` sur un champ invalide, puis retourner les champs.
- Enregistrer : `actionCustomerAccountAdd` (inscription, `$params['newCustomer']`) et `actionCustomerAccountUpdate` (page identité, `$params['customer']`), valeur lue par `Tools::getValue('abc_siret')`. Stocker dans une table du module liée à `id_customer`, pas en colonne ajoutée à `customer`.
- Adresse : `additionalCustomerAddressFields` (même principe) ; BO : `actionCustomerFormBuilderModifier` (1.7.6+).
- 1.6 : `displayCustomerAccountForm` (affichage) + `actionCustomerAccountAdd`, ou surcharge de `authentication.tpl`.

## Front controller de module

```php
// controllers/front/list.php → URL index.php?fc=module&module=abcfaq&controller=list
class AbcFaqListModuleFrontController extends ModuleFrontController
{
    public function initContent()
    {
        parent::initContent();
        $this->context->smarty->assign(['items' => /* préparé ici, pas dans le tpl */ []]);
        $this->setTemplate('module:abcfaq/views/templates/front/list.tpl'); // 1.6 : 'list.tpl'
    }
}
```

- URL : `$this->context->link->getModuleLink('abcfaq', 'list', [], true)`, jamais en dur.
- URL propre : hook `moduleRoutes` qui retourne `['module-abcfaq-list' => ['controller' => 'list', 'rule' => 'faq', 'keywords' => [], 'params' => ['fc' => 'module', 'module' => 'abcfaq']]]`.
- AJAX : `public $ajax = true;` puis `displayAjax<Action>()` + token (security.md § 4).
- Page de compte client : `public $auth = true;` et lien via `displayCustomerAccount`.

## Emails

- Templates dans le module : `mails/<iso>/<nom>.html` et `.txt` (au moins `en`). Envoi :
  `Mail::Send($idLang, 'abc_faq_answer', $this->trans('…', [], 'Modules.Abcfaq.Shop'), ['{firstname}' => $firstname], $to, null, null, null, null, null, _PS_MODULE_DIR_ . 'abcfaq/mails/')`.
- Variables `{xxx}` échappées par l'appelant si elles viennent de l'utilisateur.
- Mise en page des emails : voir [integration.md § Emails et PDF](integration.md).

## Commandes console (1.7.5+, à préférer pour un cron en 8/9)

- Classe `src/Command/…Command.php` qui étend `Symfony\Component\Console\Command\Command`, déclarée dans `config/services.yml` avec le tag `console.command`. Lancement : `php bin/console abcfaq:sync`.
- Même méthode en 9 (doc 9) : tag `console.command` et nom dans `configure()`. `#[AsCommand]` (Symfony) n'est pas documenté par PrestaShop : ne pas s'en servir sans le tag.
- Pas d'accès HTTP → pas de token à gérer ; le cron serveur appelle directement la commande.

## Webservice

- Exposer une ressource du module : hook `addWebserviceResources` qui retourne `['abc_faqs' => ['description' => '…', 'class' => 'AbcFaqItem']]`, avec `$webserviceParameters` dans l'ObjectModel.
- Les droits se donnent par clé API dans le BO (Paramètres avancés > Webservice) ; ne jamais créer de clé dans le code.
- 9 : nouvelle API admin (OAuth2, API Platform) — WebFetch la section correspondante de `https://devdocs.prestashop-project.org/9/` avant toute chose.

## Qualité (modules distribués ou validés Addons)

- `composer require --dev prestashop/php-dev-tools` puis `vendor/bin/prestashop-coding-standards` pour générer la config php-cs-fixer et PHPStan.
- Validateur Addons : `https://validator.prestashop.com` (zip du module).
