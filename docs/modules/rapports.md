# Module Rapports

## Rôle

Le module Rapports produit les rapports trimestriels et le rapport annuel final des communautés.

## Fichiers concernés

- `rapport`
- `ligne_rapport`
- `plan_compte`
- `operation`
- `ligne_operation`
- `modele_rapport`
- `mapping_rapport_excel`

## Structure validée de `rapport`

- `IDrapport`
- `TypeRapport`
- `NiveauRapport`
- `DeviseRapport`
- `DateDebutRapport`
- `DateFinRapport`
- `StatutRapport`
- `IDUtilisateurGeneration`
- `DateGenerationRapport`
- `IDUtilisateurValidation`
- `IDexercice`
- `IDcommunaute`
- `IDperiode`

## Structure validée de `ligne_rapport`

- `IDligne_rapport`
- `CodeCompteRapport`
- `LibelleFRRapport`
- `LibelleENRapport`
- `TypeEtatRapport`
- `NatureCompteRapport`
- `MontantDeviseRapport`
- `DeviseLigneRapport`
- `MontantFCFARapport`
- `MontantEURRapport`
- `OrdreAffichageRapport`
- `IDrapport`
- `IDplan_compte`

## Types de rapport validés

- `TRIMESTRIEL`
- `ANNUEL_FINAL`
- `BILAN`
- `COMPTE_RESULTAT`

## Règles de calcul

Pour `ACTIF`, `DEPENSE` et `TRESORERIE` :

```text
Débit - Crédit
```

Pour `PASSIF`, `RECETTE` et `CAPITAUX` :

```text
Crédit - Débit
```

## Accès communautaire

Les boutons de rapport trimestriel et de rapport annuel final doivent être accessibles depuis le tableau de bord, car le communautaire n'a pas accès à l'administration.
