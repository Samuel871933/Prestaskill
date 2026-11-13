---
description: Modifier l'affichage d'un module natif. Le skill doit surcharger le tpl dans le thème actif, jamais dans le dossier du module.
expected_outcome: Le tpl est créé sous themes/<thème actif>/modules/ps_shoppingcart/…, pas dans modules/ps_shoppingcart/.
max_turns: 12
allowed_tools: [Read, Glob, Grep, Skill]
---

Sur ma boutique PrestaShop 8.1 (préfixe modules : abc, auteur : Test, thème actif : montheme enfant de classic), ajoute le nombre d'articles en badge rouge sur l'icône du panier dans le header.
