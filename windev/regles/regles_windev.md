# Règles WinDev / WLanguage — EcoCommunautés

## Dates

- Ne pas utiliser `ChaîneVersDate()` pour les dates fixes.
- Utiliser le format :

```wl
MaDate = "20260101"
```

## Retour de procédure

- Utiliser `RETOUR` pour sortir d'une procédure sans valeur de retour.
- Utiliser `RENVOYER` uniquement pour les fonctions avec type de retour.

## Boucles

Éviter :

```wl
POUR i est un entier = 1 A 10
```

Préférer :

```wl
i est un entier
POUR i = 1 A 10
```

## Fenêtres avec paramètres

Toujours déclarer les paramètres :

```wl
PROCÉDURE FEN_DetailRapport(nIDRapportParam est un entier sur 8 octets)
```

## Combos programmables

Pour les combos avec `gLienActive`, utiliser :

```wl
COMBO_Champ..ValeurMémorisée
```

## Simplicité

Les interfaces doivent rester simples, claires et faciles à utiliser.
