# Exports Excel officiels

## Rôle

Les exports Excel produisent les fichiers officiels à partir des rapports générés.

## Fichiers concernés

- `rapport`
- `ligne_rapport`
- `modele_rapport`
- `mapping_rapport_excel`

## Modèles officiels

- `Template Bilan Euro CFA.xlsx`
- `Template Bilan CFA Euro.xlsx`

## Principe

Les modèles Excel officiels ne remplacent pas les fichiers HFSQL. Ils servent uniquement à l'export.

## Processus

1. Sélectionner un rapport.
2. Copier le modèle officiel.
3. Lire les lignes `ligne_rapport`.
4. Utiliser `mapping_rapport_excel` pour placer les montants dans les bonnes cellules.
5. Sauvegarder le fichier exporté.

## Devises

Les rapports destinés à Rome doivent contenir les montants en :

- FCFA
- EUR

La devise d'origine reste utile pour l'analyse locale de la communauté.
