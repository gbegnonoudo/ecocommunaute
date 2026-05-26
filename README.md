# EcoCommunauté

Application desktop de gestion économique, comptable et financière des communautés religieuses, développée avec **WinDev 2025** et la base de données **HFSQL Client/Serveur**.

---

## Présentation

EcoCommunauté permet aux communautés de gérer leurs opérations comptables de manière centralisée et sécurisée, avec une supervision provinciale intégrée.

**Fonctionnalités principales :**
- Saisie et suivi des opérations comptables par période
- Gestion des exercices fiscaux (ouverture, soumission, clôture)
- Contrôle et validation par le niveau provincial
- Génération de rapports trimestriels et annuels
- Export en FCFA et EUR
- Importation de plan de comptes et de notes depuis Excel
- Tableau de bord interactif

**Profils utilisateurs :**
| Profil | Accès |
|---|---|
| `ADMIN` | Configuration, gestion des communautés et des utilisateurs |
| `PROVINCIAL` | Supervision, contrôle et validation des périodes |
| `COMMUNAUTAIRE` | Saisie des opérations, consultation de ses rapports |

---

## Stack technique

| Composant | Technologie |
|---|---|
| Environnement | WinDev 2025 |
| Langage | WLangage (L5G) |
| Base de données | HFSQL Client/Serveur |
| Authentification | Groupware Utilisateur WinDev |
| Plateforme cible | Windows 64 bits |
| Migration future | WEBDEV (WebApp) |

---

## Architecture

Voir [`docs/architecture.md`](docs/architecture.md) pour le diagramme complet.

L'application suit une architecture **3-tiers** avec séparation claire :
- **Couche Présentation** — Fenêtres WinDev (`FEN_*.wdw`) organisées par module
- **Couche Métier** — Procédures globales (`Section*.wdg`) par domaine fonctionnel
- **Couche Données** — HFSQL via l'analyse (`EcoCommunaute.ana`)

---

## Structure du projet

```
EcoCommunaute/
├── EcoCommunaute.wdp           # Fichier projet WinDev
├── EcoCommunaute.ana/          # Analyse HFSQL (schéma de données)
├── EcoCommunaute.wdd           # Dictionnaire des données
│
├── FEN_TableauDeBord.wdw       # Tableau de bord principal
├── FEN_Admin.wdw               # Administration
├── FEN_Communautes.wdw         # Gestion des communautés
├── FEN_Exercices.wdw           # Exercices comptables
├── FEN_PeriodesComptables*.wdw # Périodes (Admin / Communauté)
├── FEN_SaisieOperation*.wdw    # Saisie des opérations
├── FEN_ListeOperations.wdw     # Liste des opérations
├── FEN_ComptesTresorerie.wdw   # Comptes de trésorerie
├── FEN_Rapport*.wdw            # Rapports (trimestriel, annuel)
├── FEN_ControlePeriode*.wdw    # Contrôle provincial
├── FEN_Detail*.wdw             # Détails (opérations, rapports)
├── FEN_Fiche_*.wdw             # Fiches (communauté, exercice, user)
├── FEN_Utilisateurs.wdw        # Gestion des utilisateurs
├── FEN_TauxChange.wdw          # Taux de change FCFA/EUR
├── FEN_ImportationFichierExcel.wdw
│
├── Section00_Utilitaires.wdg   # Fonctions transversales
├── Section01_Initialisation.wdg
├── Section02_Utilisateur_Connecte.wdg
├── Section03_Communautes.wdg
├── Section04_Exercices_Periodes.wdg
├── Section05_Controle_Comptable.wdg
├── Section06_Documents.wdg
├── Section07_TauxChange.wdg
├── Section08_ImportNotes.wdg
├── Section08_ImportPlanCompte.wdg
└── Section09_Rapports.wdg
```

---

## Documentation

| Document | Description |
|---|---|
| [`docs/architecture.md`](docs/architecture.md) | Diagramme d'architecture de l'application |
| [`docs/bonnes_pratiques_windev.md`](docs/bonnes_pratiques_windev.md) | Guide des bonnes pratiques WinDev 2025 |

---

## Prérequis

- WinDev 2025 (PC SOFT)
- Serveur HFSQL Client/Serveur (inclus dans WinDev)
- Windows 10/11 64 bits

---

## Versioning

Le projet est versionné via **Git** (format texte hybride YAML de WinDev 2025, compatible GitHub).
