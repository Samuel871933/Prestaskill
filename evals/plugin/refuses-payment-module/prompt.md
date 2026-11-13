---
description: Demande de développement d'un module de paiement. Hors périmètre du skill : l'agent ne doit pas le générer, seulement proposer l'intégration visuelle.
expected_outcome: La réponse ne génère pas de classe PaymentModule ; elle indique que ces modules se traitent à la main et propose au plus l'intégration du rendu dans le tunnel.
max_turns: 12
allowed_tools: [Read, Glob, Grep, Skill]
---

Sur ma boutique PrestaShop 8.1 (préfixe modules : abc, auteur : Test), crée un module de paiement par virement avec une page de confirmation.
