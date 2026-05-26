# PAGE_ListeOperations — Liste filtrable des opérations

## Rôle

Permet de consulter, filtrer, exporter et drill-down sur toutes les opérations d'une période. Profils autorisés : **COMMUNAUTAIRE** (sa communauté), **PROVINCIAL** (toutes les communautés de sa province), **ADMIN** (tout).

## URL

`/operations?periode={id}&type={Recette|Dépense}&compte={num}`

## Layout

```
┌──────────────────────────────────────────────────────────┐
│  Opérations — T2 2026 — Communauté X                     │
├──────────────────────────────────────────────────────────┤
│  Filtres : [Type ▼] [Compte ▼] [Période ▼] [Recherche]  │
│            [TCD]  [Exporter ▼]  [+ Nouvelle opération]   │
├──────────────────────────────────────────────────────────┤
│  Table fichier — 247 opérations                          │
│  Date ▼ | Compte | Libellé          | Mt FCFA | Type    │
│  ───────────────────────────────────────────────────────│
│  2026-05-26 | 5300 | Achat carburant | 125 000 | Dép    │
│  2026-05-25 | 7000 | Don famille X   |  50 000 | Rec    │
│  ...                                                     │
├──────────────────────────────────────────────────────────┤
│  Pagination : ← 1 2 3 ... 25 →     250 par page  ▼      │
└──────────────────────────────────────────────────────────┘
```

## Nouveautés WEBDEV 2026 utilisées

### 1. TCD (Tableau Croisé Dynamique) — nouveauté Web

Bouton `[TCD]` qui affiche un TCD pivotable directement dans le navigateur. L'utilisateur peut :
- Inverser lignes/colonnes
- Plier/déplier les sous-niveaux
- Exporter le TCD en Excel
- Comparer 2 périodes

```wl
PROCÉDURE BTN_AfficherTCD_OnClick()

// Calcul asynchrone (nouveauté 2026 — tcdCalculeToutAsynchrone)
tcdOperations..AlimentationAsynchrone = Vrai
tcdOperations..Ligne = "NumCompte"
tcdOperations..Colonne = "Trimestre"
tcdOperations..Valeur = "MontantFCFA"
tcdOperations..Agrégation = tcdSomme
tcdCalculeToutAsynchrone(tcdOperations)
```

### 2. Recherche sémantique HFSQL

```wl
PROCÉDURE SAI_Recherche_OnSortie()

SI SAI_Recherche..Valeur <> "" ALORS
    // "carburant essence" → trouve "achat gasoil", "plein voiture", etc.
    tabResultats EST UN TABLEAU = RechercheSémantique(
        Operation,
        "Libelle",
        SAI_Recherche..Valeur,
        20  // Top 20 résultats
    )
    TableAfficheRéSultat(TBL_Operations, tabResultats)
FIN
```

### 3. Streaming Chunk pour les exports volumineux

```wl
PROCÉDURE BTN_ExporterExcel_OnClick()

// Si > 5000 lignes, on streame le fichier au lieu de tout charger en mémoire
SI NombreOperationsCourant() > 5000 ALORS
    PageRedirige("/api/operations/export?format=xlsx&streaming=true")
SINON
    // Export classique
    cheminFichier EST UNE CHAÎNE = ExporterListeOperations("xlsx")
    PageRedirige(cheminFichier)
FIN
```

## Code — Initialisation

```wl
PROCÉDURE PAGE_ListeOperations_OnInit()

VerifierAuthentifie()
gUtilisateur EST UN ClasseUtilisateur = RecupererUtilisateurConnecte()

// Filtre selon le profil — TOUJOURS côté serveur
SELON gUtilisateur.Profil
    CAS "COMMUNAUTAIRE"
        gFiltreCommunaute = gUtilisateur.IDCommunaute  // Forcé
        COMBO_Communaute..Visible = Faux  // Pas de choix possible

    CAS "PROVINCIAL"
        COMBO_Communaute..ListeFichier = Communautes_RecupererParProvince(gUtilisateur.Province)
        COMBO_Communaute..Visible = Vrai

    CAS "ADMIN"
        COMBO_Communaute..ListeFichier = Communautes_RecupererToutes()
        COMBO_Communaute..Visible = Vrai
FIN

// Charge la période par défaut (celle en cours)
COMBO_Periode..Valeur = Periodes_RecupererPeriodeEnCoursID()

ChargerOperations()
```

## Code — Chargement des opérations (avec pagination)

```wl
PROCÉDURE ChargerOperations()

iPage EST UN ENTIER = TBL_Operations..PageEnCours
iTaillePage EST UN ENTIER = TBL_Operations..NombreLignePage

// Appel REST paginé
sURL EST UNE CHAÎNE = ChaîneConstruit("/api/operations?periode=%1&page=%2&limit=%3",
    COMBO_Periode..Valeur, iPage, iTaillePage)

SI gFiltreCommunaute <> "" ALORS
    sURL += "&communaute=" + gFiltreCommunaute
FIN

vReponse EST UN VARIANT = HTTPRequête(sURL, "GET", "", AvecTokenAuth())

SI vReponse.CodeStatut = 200 ALORS
    clResultat EST UN ClasseListeOperationsPaginée = JSONVersListeOperations(vReponse.Contenu)
    TableAfficheRéSultat(TBL_Operations, clResultat.Items)
    TBL_Operations..NombreTotalLigne = clResultat.Total
    LBL_Total..Libellé = ChaîneConstruit("%1 opérations", clResultat.Total)
FIN
```

## Performance

- Pagination serveur (jamais charger > 250 lignes en mémoire client)
- Cache 30 s sur les filtres fréquents (compte, type)
- Index HFSQL sur `(IDPeriode, DateOperation)` obligatoire
- TCD calculé asynchrone (le bouton reste responsive)

## Tests automatisés

1. Liste paginée — page 2 affiche les 250 suivantes
2. Filtre par compte → moins de résultats
3. Recherche "carburant" → trouve "essence", "gasoil"
4. Export XLSX 100 lignes → fichier généré < 2 s
5. Export XLSX 10 000 lignes → streaming → pas d'OOM
6. Profil COMMUNAUTAIRE ne peut pas voir une autre communauté (test sécurité)
