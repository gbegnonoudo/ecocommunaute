# FEN_SaisieOperation

## Rôle

Fenêtre principale de saisie des opérations comptables.

## Sections

1. Informations générales
2. Compte de trésorerie
3. Pièces justificatives
4. Lignes comptables
5. Ressources éventuelles

## Champs importants

- `TABLE_LignesSaisie`
- `SAI_TotalDebit`
- `SAI_TotalCredit`
- `SAI_Ecart`

## Boutons

- `BTN_AjouterLigne`
- `BTN_SupprimerLigne`
- `BTN_EnregistrerOperation`
- `BTN_RessourceOperation`

## Règles importantes

- Total débit = Total crédit.
- Une période VALIDEE_PROVINCE ou CLOTUREE interdit les modifications.
- Les lignes utilisent `ligne_operation.IDligneOperation`.
- Les comptes proviennent du fichier `plan_compte`.
- Vérifier `EstSaisissableCompte` et `StatutCompte`.
- Les montants doivent être disponibles en devise d'origine, EUR et FCFA.

## Simplicité

La fenêtre doit rester simple et facile à utiliser pour des utilisateurs non spécialistes en comptabilité.
