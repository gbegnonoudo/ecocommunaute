# API GraphQL — EcoCommunauté Web

**Nouveauté WEBDEV 2026** : support natif de GraphQL côté client et serveur via la famille `GraphQL*`.

## Pourquoi GraphQL en complément de REST ?

| Cas d'usage | Pourquoi GraphQL ? |
|---|---|
| Tableau de bord | 1 requête vs 5+ requêtes REST (recettes, dépenses, alertes, solde, dernières opérations) |
| Vue contrôle provincial | Champs à la carte (le superviseur veut les totaux + nb d'opérations + dates clés sans charger tout le détail) |
| Apps mobiles | Économie de bande passante (l'app demande exactement ce qu'elle affiche) |

REST reste utilisé pour les actions (POST/PUT/DELETE) et les exports streaming.

---

## Endpoint

```
POST /api/graphql
Authorization: Bearer <access_token>
Content-Type: application/json
```

---

## Schéma

```graphql
# ========================================================================
# Scalars
# ========================================================================
scalar Date
scalar DateTime
scalar Decimal

# ========================================================================
# Enums
# ========================================================================
enum Profil {
  ADMIN
  PROVINCIAL
  COMMUNAUTAIRE
}

enum StatutPeriode {
  Ouvert
  Soumis
  Valide
  Rejete
}

enum TypeOperation {
  Recette
  Depense
}

enum FormatRapport {
  PDF
  XLSX
  CSV
}

# ========================================================================
# Types
# ========================================================================
type Utilisateur {
  id: ID!
  login: String!
  email: String!
  profil: Profil!
  communaute: Communaute
  doubleAuth: Boolean!
  dernierLogin: DateTime
}

type Communaute {
  id: ID!
  nom: String!
  province: String!
  adresse: String
  telephone: String
  latitude: Decimal
  longitude: Decimal
  statut: String!
  exerciceCourant: Exercice
}

type Exercice {
  id: ID!
  annee: Int!
  statut: String!
  communaute: Communaute!
  periodes: [Periode!]!
}

type Periode {
  id: ID!
  trimestre: String!
  statut: StatutPeriode!
  dateDebut: Date!
  dateFin: Date!
  dateSoumission: DateTime
  observationProvincial: String
  exercice: Exercice!

  # Totaux dénormalisés
  totalRecettesFCFA: Decimal!
  totalDepensesFCFA: Decimal!
  totalRecettesEUR: Decimal!
  totalDepensesEUR: Decimal!
  nbOperations: Int!

  # Relations
  operations(limit: Int = 20, offset: Int = 0): [Operation!]!
}

type Operation {
  id: ID!
  dateOperation: Date!
  numCompte: String!
  libelle: String!
  typeOperation: TypeOperation!
  montantFCFA: Decimal!
  montantEUR: Decimal!
  tauxApplique: Decimal!
  pieceJointe: String
  periode: Periode!
  utilisateurSaisie: Utilisateur!
  compte: CompteTresorerie!
}

type CompteTresorerie {
  numCompte: ID!
  libelle: String!
  typeCompte: String!
  classe: String!
}

type TauxChange {
  id: ID!
  dateTaux: Date!
  tauxEURFCFA: Decimal!
  source: String!
}

type Alerte {
  niveau: String!     # info | warning | critical
  message: String!
  lien: String
}

type PointSolde {
  date: Date!
  solde: Decimal!
}

type Totaux {
  recettesFCFA: Decimal!
  depensesFCFA: Decimal!
  recettesEUR: Decimal!
  depensesEUR: Decimal!
  nbOperations: Int!
}

# ========================================================================
# Queries
# ========================================================================
type Query {
  # --- Authentification / utilisateur courant ---
  utilisateurCourant: Utilisateur!

  # --- Communautés ---
  communaute(id: ID!): Communaute
  communautes(province: String, limit: Int, offset: Int): [Communaute!]!

  # --- Exercices / Périodes ---
  periodeEnCours(idCommunaute: ID!): Periode
  periode(id: ID!): Periode
  periodesSoumises(province: String): [Periode!]!

  # --- Opérations ---
  operations(
    idPeriode: ID!
    type: TypeOperation
    compte: String
    recherche: String  # Recherche sémantique HFSQL 2026
    limit: Int = 50
    offset: Int = 0
  ): [Operation!]!

  dernieresOperations(idCommunaute: ID!, limite: Int = 10): [Operation!]!

  # --- Tableau de bord (cas typique GraphQL) ---
  soldeQuotidien(idCommunaute: ID!, joursPasses: Int = 90): [PointSolde!]!
  alertes(idCommunaute: ID!): [Alerte!]!

  # --- Comptes ---
  comptesTresorerie(typeCompte: String): [CompteTresorerie!]!

  # --- Taux de change ---
  tauxJour: TauxChange!
  tauxHistorique(dateDebut: Date!, dateFin: Date!): [TauxChange!]!
}

# ========================================================================
# Mutations (utilisées pour les actions complexes — sinon REST)
# ========================================================================
type Mutation {
  # --- Périodes ---
  soumettrePeriode(idPeriode: ID!): MutationResult!
  validerPeriode(idPeriode: ID!, observation: String): MutationResult!
  rejeterPeriode(idPeriode: ID!, motif: String!): MutationResult!

  # --- Opérations ---
  creerOperation(input: OperationInput!): Operation!
  modifierOperation(id: ID!, input: OperationInput!): Operation!
  supprimerOperation(id: ID!): MutationResult!
}

input OperationInput {
  dateOperation: Date!
  numCompte: String!
  libelle: String!
  typeOperation: TypeOperation!
  montantFCFA: Decimal!
  idPeriode: ID!
  pieceJointe: String
}

type MutationResult {
  succes: Boolean!
  message: String
  idCreee: ID
}

# ========================================================================
# Subscriptions (via WebSocket — pour le superviseur temps réel)
# ========================================================================
type Subscription {
  nouvellePeriodeSoumise(province: String!): Periode!
  nouvelleOperation(idPeriode: ID!): Operation!
}
```

---

## Exemple d'usage — Page TableauDeBord

**1 seule requête** pour tout le dashboard :

```graphql
query DashboardCommunaute($idCommunaute: ID!) {
  periodeEnCours(idCommunaute: $idCommunaute) {
    id
    trimestre
    statut
    dateDebut
    dateFin
    totalRecettesFCFA
    totalDepensesFCFA
    totalRecettesEUR
    totalDepensesEUR
  }
  soldeQuotidien(idCommunaute: $idCommunaute, joursPasses: 90) {
    date
    solde
  }
  dernieresOperations(idCommunaute: $idCommunaute, limite: 10) {
    id
    dateOperation
    libelle
    montantFCFA
    typeOperation
    compte {
      numCompte
      libelle
    }
  }
  alertes(idCommunaute: $idCommunaute) {
    niveau
    message
    lien
  }
}
```

**Variables**
```json
{ "idCommunaute": "uuid-de-la-comm" }
```

---

## Code WLangage côté serveur — Résolveur GraphQL

Exemple de résolveur pour la query `periodeEnCours` :

```wl
// procedures/GraphQLResolvers.wls

PROCÉDURE Resolver_periodeEnCours(parent, args, context) : ClassePeriode

clUser EST UN ClasseUtilisateur = context.utilisateur

// Vérification sécurité côté serveur
SI clUser.Profil = "COMMUNAUTAIRE" ET args.idCommunaute <> clUser.IDCommunaute ALORS
    GraphQLLeveErreur("Accès refusé", "FORBIDDEN")
    RETOUR
FIN

RENVOYER Periodes_RecupererPeriodeEnCours(args.idCommunaute)
```

---

## Sécurité GraphQL

- **Toutes les queries** vérifient le scope OAuth via le middleware
- **Depth limiting** : max 5 niveaux de profondeur pour empêcher les requêtes circulaires
- **Query cost analysis** : chaque champ a un coût ; au-delà de 1000, la requête est rejetée
- **Rate limiting** : 100 requêtes/min/utilisateur
- **Introspection désactivée** en production (le schéma n'est pas exposé)

---

## Outils

- L'environnement WEBDEV 2026 fournit un éditeur GraphQL Playground intégré
- L'introspection du schéma est utilisée pour générer les types côté client (WEBDEV ou Mobile)
