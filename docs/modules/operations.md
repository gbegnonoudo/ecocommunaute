# Module Opérations

## Rôle

Le module Opérations permet de saisir, modifier, consulter et contrôler les opérations comptables d'une communauté.

## Fichiers HFSQL concernés

- `operation`
- `ligne_operation`
- `plan_compte`
- `periode_comptable`
- `document`
- `ressource` si une opération concerne un bien ou une ressource.

## Fenêtres principales

- `FEN_SaisieOperation`
- `FEN_ListeOperations`
- `FEN_DetailOperation`
- `FEN_RessourceOperation`

## Règles principales

- Une opération appartient à une communauté, un exercice et une période.
- Une opération contient au minimum deux lignes comptables.
- Total débit = total crédit.
- La modification est autorisée seulement si la période est `OUVERTE` ou `A_CORRIGER`.
- Après `VALIDEE_PROVINCE` ou `CLOTUREE`, les opérations ne sont plus modifiables.
- Les comptes utilisés doivent être actifs et saisissables.
- Les montants sont conservés en devise d'origine, en EUR et en FCFA.

## Comportement attendu

Le communautaire saisit les opérations de sa communauté. Le provincial contrôle ensuite les opérations au moment de la validation de la période.
