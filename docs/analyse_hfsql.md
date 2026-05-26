# Analyse HFSQL — EcoCommunautés

## Fichiers principaux

- `communaute`
- `utilisateur`
- `exercice`
- `periode_comptable`
- `operation`
- `ligne_operation`
- `plan_compte`
- `note`
- `compte_tresorerie`
- `solde_periode_tresorerie`
- `taux_change_communaute`
- `document`
- `ressource`
- `ressource_fonciere`
- `rapport`
- `ligne_rapport`
- `modele_rapport`
- `mapping_rapport_excel`

## Règles principales

- `EXERCICE` représente l'année comptable globale.
- `PERIODE_COMPTABLE` représente une période rattachée à une communauté et à un exercice.
- Les rapports sont générés dans `rapport` et `ligne_rapport`.
- Les opérations sont enregistrées en partie double avec `operation` et `ligne_operation`.
- Les comptes viennent du fichier réel `plan_compte`.
- Les notes explicatives viennent du fichier `note`.

## Cycle de période

```text
OUVERTE -> SOUMISE -> A_CORRIGER ou VALIDEE_PROVINCE -> CLOTUREE
```

## Accès par groupe

- `ADMIN` : accès complet.
- `PROVINCIAL` : contrôle, validation, clôture, rapports consolidés.
- `COMMUNAUTAIRE` : accès limité à sa communauté, saisie et soumission.
