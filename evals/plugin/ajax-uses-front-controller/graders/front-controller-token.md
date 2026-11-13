---
type: llm
---

PASS si l'appel AJAX passe par un `ModuleFrontController` (URL construite par `getModuleLink`), vérifie un token et que le client est connecté, et caste ou valide l'ID produit.

FAIL si le module contient un script PHP appelable directement (`ajax.php`, `favorites.php`…) ou si l'action modifie des données sans vérifier le token ni le client.
