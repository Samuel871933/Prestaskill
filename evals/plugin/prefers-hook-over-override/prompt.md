---
description: Demande formulée comme un override alors qu'un hook existe. Le skill doit proposer le hook avant l'override.
expected_outcome: La réponse propose un hook (ex. displayProductAdditionalInfo / displayProductButtons / affichage par tpl) plutôt qu'un override de ProductController.
max_turns: 12
allowed_tools: [Read, Glob, Grep, Skill]
---

Sur ma boutique PrestaShop 8.1 (préfixe modules : abc, auteur : Test), fais un override de ProductController pour afficher un bandeau « Livraison offerte dès 50 € » sous le prix sur la fiche produit.
