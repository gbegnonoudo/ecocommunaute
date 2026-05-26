# Architecture — EcoCommunauté Web (WEBDEV 2026)

## Vue d'ensemble

Architecture **3-tiers stricte** avec séparation **MVP côté présentation** et exposition des services métier via **REST + GraphQL**, conformément aux bonnes pratiques WEBDEV 2026.

---

## Architecture globale

```mermaid
graph TB
    subgraph CLIENT["Couche Client (Navigateur)"]
        BROWSER[Navigateur Web<br/>HTML5 + CSS responsive<br/>CSP activée]
        MOBILE[Navigateur Mobile<br/>Responsive design]
    end

    subgraph DMZ["Zone DMZ"]
        LB[Load Balancer<br/>HTTPS / TLS 1.3]
        WAF[WAF / Reverse Proxy]
    end

    subgraph APP["Serveur d'Application WEBDEV 2026 (Cluster)"]
        direction TB
        OAUTH[OAuth Server WEBDEV<br/>wdbaas]
        GRP[Groupware Utilisateur<br/>ADMIN / PROVINCIAL / COMMUNAUTAIRE]
        PAGES[Pages WEBDEV<br/>MVP]
        REST[Webservices REST<br/>OpenAPI 3.x]
        GQL[Webservices GraphQL]
        STREAM[Streaming Chunk<br/>Exports volumineux]
    end

    subgraph METIER["Couche Métier (WLangage partagée)"]
        AUTH_S[Auth.wls]
        OP_S[Operations.wls]
        PER_S[Periodes.wls]
        RAP_S[Rapports.wls]
        TX_S[TauxChange.wls]
    end

    subgraph DATA["Couche Données"]
        HFSQL[(HFSQL Client/Serveur<br/>Chiffrement AES 256<br/>Recherche sémantique 2026)]
        SPARE[(HFSQL Spare<br/>Réplication continue)]
    end

    BROWSER --> LB
    MOBILE --> LB
    LB --> WAF
    WAF --> OAUTH
    WAF --> PAGES
    WAF --> REST
    WAF --> GQL

    OAUTH --> GRP
    PAGES --> METIER
    REST --> METIER
    GQL --> METIER
    STREAM --> METIER

    METIER --> HFSQL
    HFSQL -.réplication.-> SPARE
```

---

## Couche présentation — Pattern MVP

WEBDEV 2026 fournit le **RAD MVP** qui génère automatiquement les pages Fiche/Liste avec leurs états associés.

```mermaid
graph LR
    subgraph V["Vue (Page WEBDEV)"]
        PAGE[PAGE_SaisieOperation]
        STYLE[Styles + Palette<br/>Responsive]
    end

    subgraph P["Présenteur (Classe WLangage)"]
        PRES[ClassePresOperation<br/>- Validation<br/>- Formatage<br/>- État UI]
    end

    subgraph M["Modèle (Classe WLangage)"]
        MOD[ClasseOperation<br/>- Propriétés<br/>- Sérialisation JSON<br/>- Validation métier]
    end

    subgraph S["Service (Procédures globales)"]
        SVC[Operations.wls<br/>- Accès HFSQL<br/>- Règles transactionnelles]
    end

    PAGE -->|événements| PRES
    PRES -->|met à jour| PAGE
    PRES <-->|lit/écrit| MOD
    MOD -->|persiste via| SVC
    SVC --> HFSQL[(HFSQL)]
```

**Avantage :** la vue n'a aucune logique métier. Tests automatisés possibles sur le Présenteur sans navigateur.

---

## Flux d'authentification OAuth 2.0

```mermaid
sequenceDiagram
    actor U as Utilisateur
    participant B as Navigateur
    participant W as Serveur WEBDEV
    participant O as OAuth Server<br/>(wdbaas)
    participant G as Groupware
    participant H as HFSQL

    U->>B: Saisit login + mot de passe
    B->>W: POST /oauth/token (grant_type=password)
    W->>O: Vérifie credentials
    O->>G: GpwRechercheUtilisateur
    G->>H: SELECT Utilisateur WHERE Login=?
    H-->>G: Profil + mot de passe haché
    G-->>O: Valide (sel + hash automatique)
    O-->>W: Access token (JWT) + Refresh token
    W-->>B: Set-Cookie: access_token (HttpOnly, Secure, SameSite=Strict)

    Note over B: Toutes les requêtes suivantes<br/>portent le token JWT

    B->>W: GET /api/operations (Authorization: Bearer ...)
    W->>O: Vérifie token + scope
    O-->>W: Token valide, profil=COMMUNAUTAIRE
    W->>H: SELECT Operations WHERE IDCommunaute=? (scope filtré)
    H-->>W: Données
    W-->>B: JSON
```

---

## Flux de saisie d'opération (avec validation côté serveur)

```mermaid
sequenceDiagram
    actor U as Utilisateur<br/>(COMMUNAUTAIRE)
    participant P as PAGE_SaisieOperation
    participant API as REST /api/operations
    participant SVC as Operations.wls
    participant H as HFSQL

    U->>P: Remplit le formulaire
    P->>P: Validation client (formats, obligatoires)
    P->>API: POST /api/operations<br/>{date, compte, montant, type, idPeriode}

    API->>SVC: ValiderOperation(op)
    SVC->>SVC: dbgVérifie* sur les invariants
    SVC->>H: SELECT Période WHERE IDPériode=?
    H-->>SVC: Période (statut, dates)

    alt Période fermée
        SVC-->>API: Erreur 422 "Période non modifiable"
        API-->>P: Affiche erreur
    else Période ouverte
        SVC->>SVC: ConvertirEnEUR(montant, dateOp)
        SVC->>H: BEGIN TRANSACTION
        SVC->>H: INSERT Operation
        SVC->>H: UPDATE Période.Total
        SVC->>H: COMMIT
        SVC-->>API: 201 Created + ressource
        API-->>P: Succès + redirige liste
    end
```

---

## Modèle de données (HFSQL — partagé avec le desktop)

```mermaid
erDiagram
    COMMUNAUTE {
        string IDCommunaute PK
        string Nom
        string Province
        string Adresse "RGPD"
        string Telephone "RGPD"
        decimal Latitude "OpenStreetMap"
        decimal Longitude "OpenStreetMap"
        string Statut
    }
    UTILISATEUR {
        string IDUtilisateur PK
        string Login
        string MotDePasse "type Mot de passe HFSQL"
        string Email "RGPD"
        string Profil
        string IDCommunaute FK
        bool DoubleAuth
    }
    EXERCICE {
        string IDExercice PK
        int Annee
        date DateOuverture
        date DateCloture
        string Statut
        string IDCommunaute FK
    }
    PERIODE {
        string IDPeriode PK
        string Trimestre
        date DateDebut
        date DateFin
        string Statut "Ouvert/Soumis/Validé/Rejeté"
        date DateSoumission
        string ObservationProvincial
        string IDExercice FK
    }
    OPERATION {
        string IDOperation PK
        date DateOperation
        string NumCompte FK
        string Libelle "indexé sémantique 2026"
        decimal MontantFCFA
        decimal MontantEUR
        decimal TauxApplique
        string TypeOperation "Recette/Dépense"
        string PieceJointe "URL S3 ou blob"
        string IDPeriode FK
        string IDUtilisateurSaisie FK
    }
    COMPTE_TRESORERIE {
        string NumCompte PK
        string Libelle "indexé sémantique"
        string TypeCompte
        string Classe
    }
    TAUX_CHANGE {
        string IDTaux PK
        date DateTaux
        decimal TauxEURFCFA
        string Source
    }
    AUDIT_LOG {
        string IDLog PK
        datetime Horodatage
        string Action
        string IDUtilisateur FK
        string Cible
        string Details "JSON"
    }

    COMMUNAUTE ||--o{ UTILISATEUR : "a"
    COMMUNAUTE ||--o{ EXERCICE : "possède"
    EXERCICE ||--o{ PERIODE : "contient"
    PERIODE ||--o{ OPERATION : "enregistre"
    COMPTE_TRESORERIE ||--o{ OPERATION : "catégorise"
    UTILISATEUR ||--o{ OPERATION : "saisit"
    UTILISATEUR ||--o{ AUDIT_LOG : "génère"
```

**Nouveauté 2026 :** les colonnes `Libelle` de `OPERATION` et `COMPTE_TRESORERIE` sont marquées **recherche sémantique** pour permettre une recherche intelligente (« virement carburant » trouve « essence véhicule »).

---

## Modules fonctionnels web

```mermaid
graph LR
    subgraph PUBLIC["Pages publiques"]
        LOGIN[Login / OAuth]
        FORGOT[Mot de passe oublié]
    end

    subgraph COMMUN["Espace Communautaire"]
        TDB[Tableau de bord]
        SAI[Saisie opération]
        LST[Liste opérations<br/>+ filtres + TCD]
        SOUM[Soumettre période]
        RPT_C[Mes rapports]
    end

    subgraph PROV["Espace Provincial"]
        PROV_TDB[TDB provincial]
        PROV_LIST[Périodes soumises]
        PROV_CTRL[Contrôle + observations]
        PROV_RPT[Rapport annuel provincial]
    end

    subgraph ADMIN["Espace Admin"]
        ADM_COMMU[Communautés]
        ADM_USER[Utilisateurs]
        ADM_EXE[Exercices fiscaux]
        ADM_TX[Taux de change]
        ADM_IMP[Imports Excel]
        ADM_AUDIT[Journal d'audit]
    end

    LOGIN --> TDB
    LOGIN --> PROV_TDB
    LOGIN --> ADM_COMMU
```

---

## Stratégie de déploiement — Cluster WEBDEV 2026

```mermaid
graph TB
    subgraph EXT["Extérieur"]
        USERS[Utilisateurs Internet]
    end

    subgraph FRONT["Frontend (Load Balancer)"]
        LB[NGINX / HAProxy<br/>TLS termination]
    end

    subgraph CLUSTER["Cluster WEBDEV 2026"]
        APP1[Serveur App #1<br/>Linux Docker]
        APP2[Serveur App #2<br/>Linux Docker]
        APP3[Serveur App #3<br/>Linux Docker]
    end

    subgraph DB["Bases HFSQL"]
        PRIMARY[(HFSQL Primary)]
        SPARE[(HFSQL Spare<br/>Réplication continue)]
    end

    subgraph BACKUP["Sauvegarde"]
        S3[Stockage objet<br/>Sauvegardes chaudes quotidiennes]
    end

    USERS --> LB
    LB --> APP1
    LB --> APP2
    LB --> APP3
    APP1 --> PRIMARY
    APP2 --> PRIMARY
    APP3 --> PRIMARY
    PRIMARY -.réplication.-> SPARE
    PRIMARY -.sauvegarde.-> S3
```

**Avantages du Cluster WEBDEV 2026 :**
- Haute disponibilité (un nœud peut tomber)
- Scalabilité horizontale (ajout de nœuds à chaud)
- Bascule automatique vers HFSQL Spare si Primary défaille

---

## Coexistence avec l'application desktop

```mermaid
graph TB
    subgraph EXISTANT["Existant"]
        DESKTOP[App Desktop WinDev<br/>Communautés sur site]
    end

    subgraph NOUVEAU["Nouveau"]
        WEB[Webapp WEBDEV<br/>Accès Internet]
        MOBILE[App Mobile<br/>WEBDEV responsive]
    end

    subgraph PARTAGE["Partagé"]
        HFSQL_SHARED[(HFSQL Client/Serveur<br/>UNIQUE base de données)]
        METIER_SHARED[Couche Métier WLangage<br/>Composants WinDev partagés]
    end

    DESKTOP --> METIER_SHARED
    WEB --> METIER_SHARED
    MOBILE --> METIER_SHARED
    METIER_SHARED --> HFSQL_SHARED
```

Les communautés sur site (avec connexion intermittente) gardent l'app desktop. Les utilisateurs nomades et le superviseur provincial utilisent la webapp. **Pas de duplication des données ni du code métier.**
