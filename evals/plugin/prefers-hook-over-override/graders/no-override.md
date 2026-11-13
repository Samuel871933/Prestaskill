---
type: llm
---

PASS si la réponse écarte l'override de ProductController au profit d'un hook d'affichage de la fiche produit ou d'une surcharge de template, en le justifiant, ou si elle ne propose l'override qu'après avoir expliqué pourquoi aucun hook ne convient.

FAIL si la réponse crée directement `override/controllers/front/ProductController.php` sans évoquer d'alternative par hook ou template.
