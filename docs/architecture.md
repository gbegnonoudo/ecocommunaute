# Architecture — EcoCommunauté

## Vue d'ensemble

L'application suit une architecture **3-tiers** avec séparation claire des responsabilités, conformément aux recommandations WinDev 2025.

---

## Diagramme d'architecture global

```mermaid
graph TB
    subgraph UI["Couche Présentation (Fenêtres .wdw)"]
        direction TB
        FTB[FEN_TableauDeBord]
        FADM[FEN_Admin]
        FCOM[FEN_Communautes]
        FEXO[FEN_Exercices]
        FPER[FEN_Periodes\nComptables]
        FSAI[FEN_Saisie\nOperation]
        FLST[FEN_Liste\nOperations]
        FRPT[FEN_Rapports\nTrimestriel/Annuel]
        FCTL[FEN_Controle\nPeriodeProvincial]
        FUSR[FEN_Utilisateurs]
        FTCH[FEN_TauxChange]
        FIMP[FEN_Importation\nFichierExcel]
    end

    subgraph BL["Couche Métier (Procédures globales .wdg)"]
        direction TB
        S00[Section00\nUtilitaires]
        S01[Section01\nInitialisation]
        S02[Section02\nUtilisateur Connecté]
        S03[Section03\nCommunautés]
        S04[Section04\nExercices & Périodes]
        S05[Section05\nContrôle Comptable]
        S06[Section06\nDocuments]
        S07[Section07\nTaux de Change]
        S08A[Section08\nImport Notes]
        S08B[Section08\nImport Plan Comptes]
        S09[Section09\nRapports]
    end

    subgraph DATA["Couche Données (HFSQL)"]
        direction LR
        ANA[EcoCommunaute.ana\nAnalyse / Schéma]
        WDD[EcoCommunaute.wdd\nDictionnaire des données]
        HFSQL[(HFSQL\nClient/Serveur)]
    end

    subgraph AUTH["Sécurité / Authentification"]
        GW[Groupware Utilisateur\nWinDev]
        ROLES["Rôles :\nADMIN | PROVINCIAL | COMMUNAUTAIRE"]
    end

    UI -->|"Appels procédures"| BL
    BL -->|"HLit* / EcranVersFichier\nRequêtes SQL"| DATA
    ANA --> HFSQL
    WDD --> ANA
    AUTH --> UI
    GW --> ROLES
```

---

## Flux fonctionnel principal

```mermaid
sequenceDiagram
    actor U as Utilisateur\n(COMMUNAUTAIRE)
    actor P as Superviseur\n(PROVINCIAL)
    participant App as EcoCommunauté
    participant BL as Couche Métier
    participant DB as HFSQL

    U->>App: Connexion (Groupware)
    App->>DB: Vérifie profil utilisateur
    DB-->>App: Profil COMMUNAUTAIRE

    U->>App: Ouvre période comptable
    App->>BL: Section04 — Ouvrir période
    BL->>DB: Créer enregistrement période

    U->>App: Saisit opérations
    App->>BL: Section05 — Contrôle comptable
    BL->>DB: EcranVersFichier → table Opérations

    U->>App: Soumet la période
    BL->>DB: Statut = "Soumis"

    P->>App: Consulte les périodes soumises
    App->>BL: Section05 — Contrôle provincial
    BL->>DB: Lecture opérations communauté

    P->>App: Valide ou rejette
    BL->>DB: Statut = "Validé" / "Rejeté"

    U->>App: Génère rapports
    App->>BL: Section09 — Rapports
    BL->>DB: Requêtes agrégation FCFA/EUR
    DB-->>App: Données rapport
    App-->>U: PDF / Export Excel
```

---

## Diagramme des modules fonctionnels

```mermaid
graph LR
    subgraph ADM["Administration"]
        A1[Communautés]
        A2[Utilisateurs]
        A3[Exercices fiscaux]
        A4[Taux de change]
    end

    subgraph CPT["Comptabilité"]
        C1[Périodes comptables]
        C2[Saisie opérations]
        C3[Comptes trésorerie]
        C4[Import plan de comptes]
        C5[Import notes]
    end

    subgraph CTL["Contrôle Provincial"]
        P1[Révision des périodes]
        P2[Validation / Rejet]
        P3[Observations]
    end

    subgraph RPT["Reporting"]
        R1[Rapport trimestriel\ncommunautaire]
        R2[Rapport annuel\ncommunautaire]
        R3[Rapport annuel\nprovincial]
        R4[Tableau de bord]
    end

    ADM --> CPT
    CPT --> CTL
    CTL --> RPT
    ADM --> RPT
```

---

## Modèle de données simplifié

```mermaid
erDiagram
    COMMUNAUTE {
        string IDCommunaute PK
        string Nom
        string Province
        string Statut
    }
    UTILISATEUR {
        string IDUtilisateur PK
        string Login
        string Profil
        string IDCommunaute FK
    }
    EXERCICE {
        string IDExercice PK
        int Annee
        string Statut
        string IDCommunaute FK
    }
    PERIODE {
        string IDPeriode PK
        string Trimestre
        string Statut
        date DateSoumission
        string IDExercice FK
    }
    OPERATION {
        string IDOperation PK
        date DateOperation
        string NumCompte
        decimal MontantFCFA
        decimal MontantEUR
        string TypeOperation
        string IDPeriode FK
    }
    COMPTE_TRESORERIE {
        string NumCompte PK
        string Libelle
        string TypeCompte
    }
    TAUX_CHANGE {
        string IDTaux PK
        date DateTaux
        decimal TauxEURFCFA
    }

    COMMUNAUTE ||--o{ UTILISATEUR : "a"
    COMMUNAUTE ||--o{ EXERCICE : "possède"
    EXERCICE ||--o{ PERIODE : "contient"
    PERIODE ||--o{ OPERATION : "enregistre"
    COMPTE_TRESORERIE ||--o{ OPERATION : "catégorise"
```

---

## Stratégie de migration vers WEBDEV

L'architecture 3-tiers adoptée dès maintenant facilite la migration future :

| Phase | Action | Effort |
|---|---|---|
| 1 | Extraire la couche métier en Webservices REST | Moyen |
| 2 | Convertir les fenêtres en pages WEBDEV via l'assistant | Faible |
| 3 | Héberger HFSQL en mode Cloud | Faible |
| 4 | Déployer en SaaS sur PCSCloud.net | Faible |

> WinDev 2025 fournit un assistant de passage WINDEV → WEBDEV qui analyse le code et génère un rapport des modifications à effectuer.
