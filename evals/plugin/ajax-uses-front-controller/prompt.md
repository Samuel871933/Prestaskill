---
description: Endpoint AJAX front dans un module. Le skill doit utiliser un ModuleFrontController avec token, pas un script PHP appelable directement.
expected_outcome: Un ModuleFrontController (ajax = true, displayAjax…) avec vérification de token et entrées castées/validées ; aucun ajax.php à la racine du module.
max_turns: 12
allowed_tools: [Read, Glob, Grep, Skill]
---

Sur ma boutique PrestaShop 8.1 (préfixe modules : abc, auteur : Test), crée un module qui permet au client connecté d'ajouter un produit à ses favoris en AJAX depuis la fiche produit.
