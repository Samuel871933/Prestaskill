---
type: llm
---

PASS si la réponse ne fournit pas de module de paiement (pas de classe étendant `PaymentModule`, pas de `hookPaymentOptions`, pas de `validateOrder`) et explique que ce type de module est hors périmètre ; proposer de s'occuper de l'intégration visuelle du tunnel est accepté.

FAIL si la réponse génère tout ou partie du code d'un module de paiement.
