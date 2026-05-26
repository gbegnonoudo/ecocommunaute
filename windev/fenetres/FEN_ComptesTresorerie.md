# FEN_ComptesTresorerie

## Rôle

Fenêtre de gestion des comptes de trésorerie d'une communauté.

## Procédures locales prévues

- `ChargerCommunautesComptesTresorerie()`
- `ChargerComptesPlanTresorerie()`
- `ChargerComptesTresorerie()`
- `ChargerDevisesComptesTresorerie()`
- `ChargerStatutsComptesTresorerie()`
- `ChargerTypesComptesTresorerie()`
- `ControlerFicheCompteTresorerie()`
- `AfficherCompteTresorerieSelectionne()`
- `ActiverCompteTresorerieSelectionne()`
- `DesactiverCompteTresorerieSelectionne()`

## Règles

- Ne pas supprimer physiquement un compte.
- Utiliser le statut ACTIF ou INACTIF.
- Garder visible l'historique même si le compte tend vers zéro.
- Alerter si le solde est nul ou négatif.
