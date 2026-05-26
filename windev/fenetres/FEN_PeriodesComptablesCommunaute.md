# FEN_PeriodesComptablesCommunaute

## Rôle

Fenêtre réservée au groupe COMMUNAUTAIRE.

Permet :

- consulter les périodes de sa communauté ;
- contrôler techniquement la période ;
- soumettre la période à la Province.

## Boutons

- `BTN_COM_ControlerPeriode`
- `BTN_COM_SoumettrePeriode`
- `BTN_COM_Actualiser`
- `BTN_COM_Fermer`

## Champs importants

- `TABLE_Periode`
- `SAI_ObservationProvince`

## Règles

- Le communautaire ne génère pas les périodes.
- Le communautaire ne valide pas les périodes.
- Le communautaire ne clôture pas les périodes.
- Le communautaire ne voit que sa communauté.
- `SAI_ObservationProvince` est un champ multiligne en lecture seule.
