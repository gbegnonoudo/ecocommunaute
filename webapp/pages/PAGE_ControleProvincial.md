# PAGE_ControleProvincial — Contrôle et validation des périodes

## Rôle

Page principale du profil **PROVINCIAL**. Liste les périodes soumises par les communautés de sa province et permet de :
- Consulter le détail des opérations
- Ajouter des observations
- Valider ou rejeter la période

## URL

`/provincial/controle` (scope `PROVINCIAL` requis)

## Layout

```
┌──────────────────────────────────────────────────────────┐
│ Contrôle des périodes — Province : Ouest                 │
├──────────────────────────────────────────────────────────┤
│ Filtres : [Statut: Soumis ▼] [Trimestre ▼] [Recherche]  │
├──────────────────────────────────────────────────────────┤
│  Table des périodes à contrôler                          │
│  Comm. ▼ | Trim. | Soumis le | Recettes | Dépenses | ⚙  │
│  ─────────────────────────────────────────────────────── │
│  Comm A  | T1 26 | 2026-04-05| 1 250 000| 980 000  | 👁 │
│  Comm B  | T1 26 | 2026-04-07| 2 100 000| 1 870 000| 👁 │
│  ...                                                     │
└──────────────────────────────────────────────────────────┘

[Clic sur 👁]
┌──────────────────────────────────────────────────────────┐
│ Détail période — Comm A — T1 2026                        │
│                                                          │
│ [Onglet Opérations] [Onglet TCD] [Onglet Pièces]        │
│                                                          │
│ Table des opérations + filtres                           │
│                                                          │
│ Observation provincial :                                 │
│ ┌──────────────────────────────────────────────────────┐│
│ │ Saisir vos remarques...                              ││
│ └──────────────────────────────────────────────────────┘│
│                                                          │
│  [Rejeter] [Demander correction] [Valider]               │
└──────────────────────────────────────────────────────────┘
```

## Champs principaux

| Nom | Type | Description |
|---|---|---|
| `TBL_PeriodesSoumises` | Table fichier | Liste des périodes à contrôler |
| `ONGL_Detail` | Onglet (Operations / TCD / Pieces) | Détail de la période sélectionnée |
| `SAI_Observation` | Saisie RTF | Notes du superviseur |
| `BTN_Valider` | Bouton primaire vert | Action de validation |
| `BTN_Rejeter` | Bouton primaire rouge | Action de rejet |
| `BTN_DemanderCorrection` | Bouton secondaire | Renvoi à la communauté pour modification |

## Code — Chargement de la liste

```wl
PROCÉDURE PAGE_ControleProvincial_OnInit()

VerifierScope("PROVINCIAL")
gUtilisateur EST UN ClasseUtilisateur = RecupererUtilisateurConnecte()

// Une seule requête GraphQL pour la liste + les compteurs
sQuery EST UNE CHAÎNE = [
    query PeriodesAControler($province: String!) {
        periodesSoumises(province: $province) {
            id trimestre statut dateSoumission
            communaute { id nom }
            totaux { recettesFCFA depensesFCFA nbOperations }
        }
    }
]

vRes EST UN VARIANT = GraphQLExécuteRequête("/api/graphql", sQuery,
    ChaîneConstruit("""{"province":"%1"}""", gUtilisateur.Province))

TableAfficheRéSultat(TBL_PeriodesSoumises, vRes.data.periodesSoumises)
```

## Code — Validation d'une période

```wl
PROCÉDURE BTN_Valider_OnClick()

idPeriode EST UNE CHAÎNE = gPeriodeSelectionnee.ID

SI SAI_Observation..Valeur = "" ALORS
    SI OuiNon("Valider sans observation ?") <> Oui ALORS
        RETOUR
    FIN
FIN

// Confirmation forte
SI Dialogue("Confirmer la validation",
    "La période sera définitivement validée. Cette action est tracée.",
    "Valider|Annuler") <> 1 ALORS
    RETOUR
FIN

// Appel REST
clCorps EST UN ClasseValidationPeriode
clCorps.IDPeriode = idPeriode
clCorps.Observation = SAI_Observation..Valeur
clCorps.IDValidateur = gUtilisateur.IDUtilisateur

vRep EST UN VARIANT = HTTPRequête(
    ChaîneConstruit("/api/periodes/%1/valider", idPeriode),
    "POST",
    ObjetVersJSON(clCorps),
    AvecTokenAuth()
)

SI vRep.CodeStatut = 200 ALORS
    ToastAffiche("Période validée — notification envoyée à la communauté", ToastLong)
    RetirerPeriodeDeLaListe(idPeriode)

    // Envoi automatique d'un email (côté serveur, déjà déclenché par l'API)
SINON
    Erreur(JSONVersErreur(vRep.Contenu).Message)
FIN
```

## Code — Rejet d'une période

```wl
PROCÉDURE BTN_Rejeter_OnClick()

SI SAI_Observation..Valeur = "" ALORS
    Erreur("Une observation est obligatoire pour rejeter une période")
    RETOUR
FIN

// Workflow identique mais endpoint différent
clCorps.MotifRejet = SAI_Observation..Valeur

vRep EST UN VARIANT = HTTPRequête(
    ChaîneConstruit("/api/periodes/%1/rejeter", gPeriodeSelectionnee.ID),
    "POST",
    ObjetVersJSON(clCorps),
    AvecTokenAuth()
)

SI vRep.CodeStatut = 200 ALORS
    ToastAffiche("Période rejetée — la communauté peut à nouveau la modifier", ToastLong)
    RetirerPeriodeDeLaListe(gPeriodeSelectionnee.ID)
FIN
```

## Règles de sécurité

- Le provincial ne peut voir que les communautés de **sa province** (filtré côté serveur, pas seulement UI)
- Toute action de validation/rejet est **tracée dans AUDIT_LOG**
- L'observation est obligatoire en cas de rejet
- Le mot de passe peut être redemandé (2FA-like) pour valider une période > certain montant

## Tests automatisés

1. Provincial Province X ne voit pas les communautés de Province Y
2. Validation sans observation → confirmation demandée
3. Rejet sans observation → bloqué
4. Validation OK → notification envoyée à la communauté
5. Validation OK → période passe en statut "Validé" dans la base
6. Provincial bloqué → ne peut pas accéder à la page
