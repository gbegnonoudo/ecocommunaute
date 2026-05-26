# Module Comptes de trésorerie

## Rôle

Le module Comptes de trésorerie permet de gérer les caisses, banques et autres supports financiers d'une communauté.

## Fichier HFSQL

`compte_tresorerie`

Rubriques validées :

- `IDcompte_tresorerie`
- `IDcommunaute`
- `TypeCompteTresorerie`
- `LibelleCompteTresorerie`
- `NumeroCompteTresorerie`
- `DeviseCompteTresorerie`
- `SoldeInitialCompteTresorerie`
- `DateSoldeInitialCompteTresorerie`
- `StatutCompteTresorerie`
- `IDplan_compte`

## Règles principales

- Un compte de trésorerie appartient à une communauté.
- Un compte de trésorerie est relié à un compte du plan comptable.
- Un compte peut être actif ou inactif.
- La suppression physique est évitée : on désactive le compte.
- Quand un compte tend vers zéro, il ne doit pas être supprimé automatiquement.
- Si le solde devient nul, le compte reste visible pour l'historique et les contrôles.
- Un compte ne doit être désactivé que par décision explicite de l'utilisateur autorisé.

## Comportement quand le solde tend vers zéro

- Solde positif : compte utilisable normalement.
- Solde nul : compte utilisable, mais afficher une alerte simple si une dépense est saisie sans alimentation préalable.
- Solde négatif : autoriser ou bloquer selon la règle de gestion décidée pour la communauté. Par défaut, signaler clairement l'anomalie.
