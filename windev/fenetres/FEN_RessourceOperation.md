# FEN_RessourceOperation

## Rôle

Fenêtre séparée permettant de rattacher une ressource à une opération comptable.

## Principe

`FEN_SaisieOperation` reste simple et contient seulement le bouton :

- `BTN_RessourceOperation`

Les détails sont saisis ici.

## Champs possibles

- Ressource existante ou nouvelle ressource
- Type de ressource
- Libellé
- Description
- Valeur
- Date d'acquisition
- Document justificatif

## Règles

- Une ressource liée à une opération suit les règles de modification de la période.
- Si la période est validée ou clôturée, le lien ne doit plus être modifié.
