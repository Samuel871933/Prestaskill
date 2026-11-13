---
type: llm
---

PASS si la modification du rendu du panier est faite dans `themes/montheme/modules/ps_shoppingcart/…` (même chemin que dans le module) et/ou dans le CSS du thème enfant.

FAIL si la réponse modifie un fichier dans `modules/ps_shoppingcart/`, dans le thème parent `classic`, ou crée un override PHP pour un simple changement d'affichage.
