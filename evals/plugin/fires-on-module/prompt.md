---
description: Demande de création de module PrestaShop sans préfixe ni version précisés. Le skill doit se déclencher et l'agent doit demander les conventions au lieu de les inventer.
expected_outcome: Le skill prestashop est invoqué ; la réponse demande le préfixe / auteur (ou la version cible) avant de générer le module.
max_turns: 12
allowed_tools: [Read, Glob, Grep, Skill]
---

Crée-moi un module PrestaShop de FAQ produit, avec une page de configuration dans le back-office.
