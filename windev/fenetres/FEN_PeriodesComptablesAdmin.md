# FEN_PeriodesComptablesAdmin

## Rôle

Fenêtre réservée aux groupes ADMIN et PROVINCIAL.

Permet :

- générer les périodes ;
- consulter les périodes d'une communauté ;
- voir les blocages ;
- valider une période ;
- retourner une période en correction ;
- clôturer une période.

## Champs principaux

### Combos

- `COMBO_Exercice`
- `COMBO_Communaute`

## Tables

- `TABLE_Periode`
- `TABLE_BlocagesCloture`

## Zones

- `SC_COMMUNAUTAIRE`
- `SC_PROVINCE`

## Boutons périodes

- `BTN_PER_GenererPeriodes`
- `BTN_PER_Actualiser`
- `BTN_PER_ValiderProvince`
- `BTN_PER_RetournerCorrection`
- `BTN_PER_CloturerPeriode`

## Boutons blocages

- `BTN_BLOC_Actualiser`
- `BTN_BLOC_ValiderProvince`
- `BTN_BLOC_RetournerCorrection`
- `BTN_BLOC_CloturerPeriode`

## Règles

- Les tables sont programmables.
- Les combos sont liées aux fichiers HFSQL.
- Le provincial ne soumet jamais une période.
- Une période VALIDEE_PROVINCE ou CLOTUREE n'est plus modifiable.
