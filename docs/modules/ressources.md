# Module Ressources et patrimoine

## Rôle

Le module Ressources permet de suivre les biens, ressources matérielles, foncières et patrimoniales des communautés.

## Fichiers concernés

- `ressource`
- `ressource_fonciere`
- `operation`
- `document`

## Principe validé

La fenêtre `FEN_SaisieOperation` reste simple. Elle contient seulement un bouton :

- `BTN_RessourceOperation`

Les détails de la ressource sont gérés dans une fenêtre séparée :

- `FEN_RessourceOperation`

## Règles principales

- Une ressource peut être liée à une opération.
- L'opération comptable reste dans le module Opérations.
- Les informations patrimoniales détaillées restent dans le module Ressources.
- Les pièces justificatives peuvent être liées à la ressource ou à l'opération.
- Les amortissements ne doivent pas surcharger la saisie simple des opérations.

## Amortissements

Les amortissements seront gérés comme un sous-module spécifique. Ils pourront générer des écritures comptables, mais leur saisie ne doit pas compliquer l'écran principal de saisie des opérations.
