# EcoCommunautés

Application WinDev 2025 / HFSQL pour la gestion économique, comptable, patrimoniale et financière des communautés.

## Objectif

EcoCommunautés aide les communautés à :

- saisir les opérations comptables ;
- suivre les exercices et périodes comptables ;
- soumettre les périodes à la Province ;
- contrôler, valider et clôturer les périodes ;
- produire les rapports trimestriels et le rapport annuel final ;
- exporter les rapports officiels en FCFA et en EUR.

## Principes validés

- Application desktop WinDev 2025 avec HFSQL.
- Architecture pensée pour une future migration WEBDEV, sans développer la version web maintenant.
- Groupware Utilisateur WinDev comme source officielle pour l'authentification, les groupes et les droits.
- Fichier `UTILISATEUR` utilisé comme miroir applicatif pour l'identifiant interne EcoCommunautés.
- Groupes principaux : `ADMIN`, `PROVINCIAL`, `COMMUNAUTAIRE`.
- Rapports gérés avec `RAPPORT` et `LIGNE_RAPPORT`.
- Saisie en masse via une table mémoire de fenêtre, pas via un fichier tampon HFSQL.
- Exports Excel produits à partir des modèles officiels.
- Les montants finaux doivent être disponibles en devise d'origine, en FCFA et en EUR.

## Structure du dépôt

```text
.
├── docs/                 Documentation fonctionnelle et technique
├── windev/               Procédures, fenêtres, constantes et règles WinDev
├── data/                 Données de référence et modèles officiels
└── todo/                 Suivi des prochaines étapes
```

## Modules principaux

1. Administration et utilisateurs
2. Communautés
3. Exercices et périodes comptables
4. Comptes de trésorerie
5. Saisie des opérations
6. Ressources et patrimoine
7. Rapports trimestriels
8. Rapport annuel final
9. Exports Excel officiels

## Règle de simplicité

L'application est destinée à des utilisateurs qui n'ont pas nécessairement une grande formation en économie. Les écrans, procédures, messages et workflows doivent donc rester simples, guidés et faciles à comprendre.
