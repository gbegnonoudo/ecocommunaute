# PAGE_TableauDeBord — Tableau de bord communautaire

## Rôle

Page d'atterrissage pour le profil **COMMUNAUTAIRE**. Affiche en un coup d'œil l'état de la communauté connectée (période en cours, totaux, dernières opérations, alertes).

## URL

`/dashboard` (protégée — scope `COMMUNAUTAIRE` requis)

## Layout (Grille WEBDEV 2026)

Utilise le nouveau **champ Grille** (nouveauté 010) qui aligne les widgets sans positionnement au pixel et garantit l'adaptabilité.

```
┌────────────────────────────────────────────────────┐
│  [Logo]  EcoCommunauté Web    [Notif] [Menu user]  │
├────────────────────────────────────────────────────┤
│  ┌───────────┐ ┌───────────┐ ┌─────────────────┐  │
│  │ Période   │ │ Total     │ │ Total Dépenses  │  │
│  │ T2 2026   │ │ Recettes  │ │ FCFA / EUR      │  │
│  │ [Ouvert]  │ │ FCFA/EUR  │ │                 │  │
│  └───────────┘ └───────────┘ └─────────────────┘  │
│  ┌─────────────────────┐ ┌──────────────────────┐  │
│  │ Solde courant       │ │ Alertes              │  │
│  │ [Graphique ligne]   │ │ • Période à soumettre│  │
│  │                     │ │ • Taux de change MAJ │  │
│  └─────────────────────┘ └──────────────────────┘  │
│  ┌──────────────────────────────────────────────┐  │
│  │ Dernières opérations (Table)                 │  │
│  │ Date | Compte | Libellé | Montant | Type     │  │
│  │ ...                                          │  │
│  │                            [Voir toutes →]   │  │
│  └──────────────────────────────────────────────┘  │
├────────────────────────────────────────────────────┤
│   [Saisir une opération]  [Soumettre la période]   │
└────────────────────────────────────────────────────┘
```

## Champs principaux

| Nom | Type | Source |
|---|---|---|
| `CEL_PeriodeEnCours` | Cellule | `Periodes.RecupererPeriodeEnCours()` |
| `LBL_TotalRecettes` | Libellé | Agrégation server-side |
| `LBL_TotalDepenses` | Libellé | Agrégation server-side |
| `GRP_SoldeCourant` | Graphe ligne | Évolution sur 90 jours |
| `RPT_Alertes` | Zone répétée | Liste dynamique des alertes |
| `TBL_DernieresOperations` | Table fichier | 10 dernières opérations |
| `BTN_SaisirOperation` | Bouton primaire | → `PAGE_SaisieOperation` |
| `BTN_SoumettrePeriode` | Bouton (visible si statut=Ouvert) | → Action serveur |

## Code WEBDEV — Initialisation de la page

```wl
PROCÉDURE PAGE_TableauDeBord_OnInit()

// Récupère l'utilisateur connecté (depuis le token JWT)
gUtilisateur EST UN ClasseUtilisateur = RecupererUtilisateurConnecte()

// Vérifie le scope (sécurité serveur)
SI gUtilisateur.Profil <> "COMMUNAUTAIRE" ALORS
    PageAffiche(PAGE_AccesRefuse)
    RETOUR
FIN

// Charge les données du tableau de bord (appel GraphQL pour 1 seule requête)
sQuery EST UNE CHAÎNE = [
    query DashboardCommunaute($idCommunaute: ID!) {
        periodeEnCours(idCommunaute: $idCommunaute) {
            id trimestre statut dateDebut dateFin
            totalRecettesFCFA totalDepensesFCFA
            totalRecettesEUR totalDepensesEUR
        }
        soldeQuotidien(idCommunaute: $idCommunaute, joursPasses: 90) {
            date solde
        }
        dernieresOperations(idCommunaute: $idCommunaute, limite: 10) {
            id dateOperation libelle compte montantFCFA typeOperation
        }
        alertes(idCommunaute: $idCommunaute) {
            niveau message lien
        }
    }
]

sVariables EST UNE CHAÎNE = ChaîneConstruit("""{"idCommunaute":"%1"}""", gUtilisateur.IDCommunaute)

// Nouveauté 2026 : appel GraphQL natif
vResultat EST UN VARIANT = GraphQLExécuteRequête("/api/graphql", sQuery, sVariables)

// Alimente les widgets
AfficherPeriode(vResultat.data.periodeEnCours)
AfficherSolde(vResultat.data.soldeQuotidien)
TableAfficheRéSultat(TBL_DernieresOperations, vResultat.data.dernieresOperations)
AfficherAlertes(vResultat.data.alertes)

// Bouton Soumettre visible seulement si période ouverte
BTN_SoumettrePeriode..Visible = (vResultat.data.periodeEnCours.statut = "Ouvert")
```

## Code — Soumettre la période

```wl
PROCÉDURE BTN_SoumettrePeriode_OnClick()

SI OuiNon("Soumettre la période au provincial ?<br>Aucune modification ne sera plus possible.") <> Oui ALORS
    RETOUR
FIN

clResultat EST UN ClasseResultat = SoumettrePeriode(gPeriodeEnCours.ID)

SI clResultat.Succes ALORS
    ToastAffiche("Période soumise — en attente de validation provincial", ToastLong, vaCentre, hbBas)
    PageActualise()
SINON
    Erreur("Échec : " + clResultat.Message)
FIN
```

## Performance

- Une seule requête GraphQL pour tout le dashboard (vs ~5 requêtes REST)
- Mise en cache 60 s côté serveur (les totaux ne changent pas instantanément)
- Pré-rendu des graphes côté serveur si > 1000 points

## Tests automatisés

1. Affichage initial — tous les widgets se chargent
2. Période fermée — bouton Soumettre masqué
3. Période ouverte — bouton Soumettre visible et fonctionnel
4. Aucune alerte → la zone est masquée
5. Communauté inexistante → page d'erreur
