# EcoCommunauté Web — Version WEBDEV 2026

Version web de l'application EcoCommunauté, conçue avec **WEBDEV 2026** en suivant les bonnes pratiques 2026 de PC SOFT.

> Cette webapp réutilise la **même base HFSQL** et la **même couche métier** que l'application desktop WinDev. Seule la couche présentation est repensée pour le web.

---

## Pourquoi WEBDEV 2026 ?

L'application desktop existante est déjà en WLangage. Migrer vers WEBDEV 2026 plutôt qu'une stack web alternative permet :

| Critère | Bénéfice |
|---|---|
| Code partagé | 70-80 % du code WLangage métier réutilisable tel quel |
| Compétences | L'équipe maîtrise déjà WinDev/WLangage |
| Base de données | HFSQL Client/Serveur déjà en production |
| Sécurité | Groupware Utilisateur, OAuth Server, CSP intégrés |
| Compatibilité | Migration possible page par page (webisation progressive) |
| Mobile | WEBDEV Mobile partage le même projet |

---

## Architecture cible

```
┌─────────────────────────────────────────────────┐
│  NAVIGATEUR (Browser)                           │
│  HTML5 + CSS responsive + JS WEBDEV             │
│  CSP activée (nouveauté 2026)                   │
└────────────────────┬────────────────────────────┘
                     │ HTTPS
┌────────────────────┴────────────────────────────┐
│  SERVEUR D'APPLICATION WEBDEV 2026              │
│  - Pages PHP/JS générées                        │
│  - OAuth Server intégré (wdbaas)                │
│  - Webservices REST + GraphQL                   │
│  - Cluster WEBDEV (haute dispo)                 │
└────────────────────┬────────────────────────────┘
                     │ TCP chiffré AES 256
┌────────────────────┴────────────────────────────┐
│  HFSQL CLIENT/SERVEUR (déjà existant)           │
│  - Partagé avec l'application desktop           │
│  - Recherche sémantique (nouveauté 2026)        │
└─────────────────────────────────────────────────┘
```

Voir [docs/architecture.md](docs/architecture.md) pour les diagrammes complets.

---

## Structure du projet webapp

```
webapp/
├── README.md                           # Ce fichier
│
├── docs/
│   ├── architecture.md                 # Diagrammes Mermaid
│   ├── migration_windev_vers_webdev.md # Plan de migration depuis le desktop
│   └── bonnes_pratiques_webdev_2026.md # Guide WEBDEV 2026
│
├── pages/                              # Spécifications des pages WEBDEV
│   ├── PAGE_Login.md
│   ├── PAGE_TableauDeBord.md
│   ├── PAGE_Communautes.md
│   ├── PAGE_Exercices.md
│   ├── PAGE_PeriodesComptables.md
│   ├── PAGE_SaisieOperation.md
│   ├── PAGE_ListeOperations.md
│   ├── PAGE_ControleProvincial.md
│   ├── PAGE_RapportTrimestriel.md
│   ├── PAGE_RapportAnnuel.md
│   └── PAGE_Utilisateurs.md
│
├── procedures/                         # Code WLangage serveur (.wls)
│   ├── Auth.wls                        # OAuth + Groupware
│   ├── Operations.wls                  # CRUD opérations
│   ├── Periodes.wls                    # Workflow périodes comptables
│   ├── Rapports.wls                    # Génération rapports
│   ├── TauxChange.wls                  # Conversion FCFA/EUR
│   └── Utilitaires.wls                 # Helpers transverses
│
├── webservices/
│   ├── REST_API_specification.md       # OpenAPI 3.x
│   ├── GraphQL_schema.md               # Schéma GraphQL
│   └── streaming_exports.md            # Streaming Chunk pour exports
│
├── securite/
│   ├── CSP_configuration.md            # Content Security Policy
│   └── OAuth_setup.md                  # OAuth Server WEBDEV
│
└── styles/
    └── theme_ecocommunaute.md          # Palette + ambiance
```

---

## Profils utilisateurs (inchangés)

| Profil | Accès web |
|---|---|
| `ADMIN` | Configuration globale, gestion utilisateurs, paramétrage |
| `PROVINCIAL` | Supervision, validation des périodes soumises |
| `COMMUNAUTAIRE` | Saisie quotidienne, consultation des rapports |

Authentification via **OAuth Server WEBDEV 2026** (intégré au Serveur d'Application).

---

## Nouveautés WEBDEV 2026 utilisées

| Nouveauté | Usage dans EcoCommunauté |
|---|---|
| **CSP** (Content Security Policy) | Activée au niveau projet contre XSS |
| **OAuth Server intégré** | Auth centralisée, admin via `wdbaas` |
| **GraphQL** | API consolidée pour les rapports complexes |
| **Webservices Chunk** | Streaming des exports Excel/PDF volumineux |
| **TCD pour WEBDEV** | Tableau croisé dynamique des opérations |
| **OpenStreetMap** | Localisation des communautés sans Google Maps |
| **RAD MVP** | Génération automatique des fiches/listes |
| **OpenAPI 3.x avancé** | Support des héritages et tableaux dans le swagger |
| **Recherche sémantique HFSQL** | Recherche intelligente dans les libellés de comptes |

---

## Prérequis de déploiement

| Composant | Version |
|---|---|
| Serveur d'Application WEBDEV | 2026 |
| HFSQL Client/Serveur | 25 ou 26 |
| OS serveur | Windows Server 2019/2022/2025 ou Linux (Ubuntu/Debian/RedHat) |
| Navigateurs supportés | Chrome 100+, Firefox 100+, Edge 100+, Safari 15+ |
| Certificat SSL | Obligatoire (Let's Encrypt ou commercial) |

---

## Démarrage rapide

1. Lire [docs/architecture.md](docs/architecture.md) pour comprendre l'architecture
2. Lire [docs/migration_windev_vers_webdev.md](docs/migration_windev_vers_webdev.md) pour le plan de migration
3. Suivre [docs/bonnes_pratiques_webdev_2026.md](docs/bonnes_pratiques_webdev_2026.md) durant le développement
4. Configurer la sécurité via [securite/CSP_configuration.md](securite/CSP_configuration.md) et [securite/OAuth_setup.md](securite/OAuth_setup.md)
