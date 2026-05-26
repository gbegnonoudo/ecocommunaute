# API REST — EcoCommunauté Web

Spécification OpenAPI 3.x du back-end REST exposé par le Serveur d'Application WEBDEV 2026.

> **Nouveauté 2026** : OpenAPI 3.x supporte désormais les héritages d'objets et les tableaux complexes. Le swagger est généré automatiquement à partir du code WLangage.

---

## Base URL

```
https://api.ecocommunaute.org/v1
```

## Authentification

Toutes les requêtes (sauf `/auth/*`) requièrent un header :

```
Authorization: Bearer <access_token>
```

Le token est obtenu via le **OAuth Server WEBDEV 2026** intégré.

---

## Endpoints

### Authentification

#### `POST /auth/login`
Authentifie un utilisateur et retourne les tokens OAuth.

**Request body**
```json
{
  "login": "string",
  "password": "string"
}
```

**Response 200**
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIs...",
  "refresh_token": "eyJhbGciOiJIUzI1NiIs...",
  "token_type": "Bearer",
  "expires_in": 3600,
  "profil": "COMMUNAUTAIRE",
  "requires_2fa": false
}
```

**Response 401** — Login échoué
**Response 423** — Compte bloqué
**Response 429** — Throttling

#### `POST /auth/2fa/verify`
Valide le code TOTP de double authentification.

```json
{
  "session_id": "uuid",
  "code": "123456"
}
```

#### `POST /auth/refresh`
Renouvelle l'access_token via le refresh_token.

#### `POST /auth/logout`
Révoque le token courant.

---

### Opérations

#### `GET /operations`

**Query parameters**

| Param | Type | Description |
|---|---|---|
| `periode` | string | UUID de la période (obligatoire) |
| `type` | enum | `Recette` ou `Dépense` |
| `compte` | string | Numéro de compte |
| `recherche` | string | Recherche sémantique sur le libellé |
| `dateDebut` | date | ISO 8601 |
| `dateFin` | date | ISO 8601 |
| `page` | int | Défaut 1 |
| `limit` | int | Défaut 50, max 250 |

**Response 200**
```json
{
  "items": [
    {
      "id": "uuid",
      "dateOperation": "2026-05-26",
      "numCompte": "5300",
      "libelle": "Achat carburant",
      "typeOperation": "Dépense",
      "montantFCFA": 125000,
      "montantEUR": 190.68,
      "tauxApplique": 655.957,
      "idPeriode": "uuid",
      "idUtilisateurSaisie": "uuid"
    }
  ],
  "page": 1,
  "limit": 50,
  "total": 247
}
```

#### `POST /operations`

**Request body**
```json
{
  "dateOperation": "2026-05-26",
  "numCompte": "5300",
  "libelle": "Achat carburant",
  "typeOperation": "Dépense",
  "montantFCFA": 125000,
  "idPeriode": "uuid",
  "pieceJointe": "uuid-stockage"
}
```

**Response 201** — Opération créée
**Response 422** — Validation métier échouée (période fermée, montant invalide…)

#### `PUT /operations/{id}`
Modifie une opération (uniquement si période ouverte).

#### `DELETE /operations/{id}`
Supprime une opération (uniquement si période ouverte).

---

### Périodes

#### `GET /periodes/courante?communaute={id}`
Retourne la période en cours pour une communauté.

#### `GET /periodes/{id}`
Détail d'une période avec totaux.

```json
{
  "id": "uuid",
  "trimestre": "T2 2026",
  "statut": "Ouvert",
  "dateDebut": "2026-04-01",
  "dateFin": "2026-06-30",
  "totaux": {
    "recettesFCFA": 1250000,
    "depensesFCFA": 980000,
    "recettesEUR": 1905.74,
    "depensesEUR": 1494.06,
    "nbOperations": 47
  }
}
```

#### `POST /periodes/{id}/soumettre`
La communauté soumet sa période.

**Response 200** — Statut passe à `Soumis`
**Response 422** — Pas d'opération, ou période déjà soumise

#### `POST /periodes/{id}/valider`
Le provincial valide.

```json
{
  "observation": "OK, conforme"
}
```

#### `POST /periodes/{id}/rejeter`
Le provincial rejette.

```json
{
  "motif": "Pièce justificative manquante pour l'op #12"
}
```

---

### Rapports

#### `POST /rapports/generer`
Génère un rapport synchrone (< 30 s).

```json
{
  "type": "trimestriel|annuel_communaute|annuel_provincial",
  "idPeriode": "uuid",
  "idExercice": "uuid",
  "format": "pdf|xlsx",
  "devise": "FCFA|EUR|both",
  "inclureGraphiques": true,
  "inclurePiecesJointes": false,
  "idCertificatSignature": 0
}
```

**Response 200**
```json
{
  "url": "/api/rapports/telecharger/<token>",
  "nomFichier": "rapport_T2_2026.pdf",
  "tailleOctets": 245678
}
```

#### `POST /rapports/job`
Lance un rapport asynchrone pour les gros volumes.

**Response 202**
```json
{
  "idJob": "uuid",
  "statut": "EN_ATTENTE",
  "urlSuivi": "/api/rapports/job/<idJob>/status"
}
```

#### `GET /rapports/job/{id}/status`
Polling du statut d'un job.

```json
{
  "idJob": "uuid",
  "statut": "EN_COURS|TERMINE|ECHEC",
  "progression": 67,
  "urlResultat": "...",
  "messageErreur": null
}
```

#### `GET /rapports/telecharger/{token}`
Télécharge le rapport via un token signé temporaire (15 min ou 1 h).

#### `GET /operations/export?format=csv&streaming=true`
Export streaming Chunk (nouveauté 2026) pour des exports > 5000 lignes.

---

### Communautés (ADMIN)

#### `GET /communautes`
Liste paginée des communautés.

#### `GET /communautes/{id}`
Détail incluant la position GPS pour OpenStreetMap.

#### `POST /communautes`
Créer une communauté (ADMIN uniquement).

```json
{
  "nom": "Communauté Saint-Pierre",
  "province": "Ouest",
  "adresse": "BP 1234, Bafoussam",
  "telephone": "+237 ...",
  "latitude": 5.4781,
  "longitude": 10.4173
}
```

#### `PUT /communautes/{id}`
Modifier.

#### `DELETE /communautes/{id}`
Désactiver (soft delete — ne supprime pas les données comptables).

---

### Utilisateurs (ADMIN)

#### `GET /utilisateurs`
Liste paginée. Filtre par profil et communauté.

#### `POST /utilisateurs`
Créer un utilisateur via le OAuth Server WEBDEV (nouveauté `wdbaas` 2026).

```json
{
  "login": "marie.dupont",
  "email": "marie.dupont@diocese.org",
  "profil": "COMMUNAUTAIRE",
  "idCommunaute": "uuid",
  "doubleAuth": true
}
```

Le mot de passe initial est généré et envoyé par email.

#### `PUT /utilisateurs/{id}/reset-password`
Force la réinitialisation du mot de passe.

#### `POST /utilisateurs/{id}/desactiver`
Bloque le compte sans le supprimer.

---

### Taux de change

#### `GET /taux/courant`
Taux EUR/FCFA du jour.

#### `GET /taux/historique?from=...&to=...`
Historique sur une période.

#### `POST /taux`
Enregistrer un nouveau taux (ADMIN). Possibilité de récupération auto depuis l'API BCEAO.

---

### Audit

#### `GET /audit`
Journal d'audit paginé avec filtres. **ADMIN uniquement.**

#### `GET /audit/export?from=...&to=...&format=csv&streaming=true`
Export streaming du journal.

---

## Codes HTTP utilisés

| Code | Signification |
|---|---|
| `200` | OK (lecture, action réussie) |
| `201` | Créé |
| `202` | Accepté (job async lancé) |
| `400` | Requête invalide (JSON mal formé, etc.) |
| `401` | Non authentifié |
| `403` | Authentifié mais sans le scope requis |
| `404` | Ressource introuvable |
| `409` | Conflit (ex : doublon) |
| `422` | Validation métier échouée |
| `423` | Compte verrouillé |
| `429` | Trop de requêtes (throttling) |
| `500` | Erreur serveur |
| `503` | Maintenance en cours |

## Format d'erreur uniforme

```json
{
  "error": {
    "code": "PERIODE_FERMEE",
    "message": "La période est fermée — modification impossible",
    "details": {
      "idPeriode": "uuid",
      "statutCourant": "Validé"
    },
    "timestamp": "2026-05-27T14:23:00Z",
    "traceId": "req-12345"
  }
}
```
