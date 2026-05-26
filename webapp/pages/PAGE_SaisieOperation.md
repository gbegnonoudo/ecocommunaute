# PAGE_SaisieOperation — Saisie d'une opération comptable

## Rôle

Permet à un utilisateur **COMMUNAUTAIRE** de saisir une nouvelle opération comptable (recette ou dépense) sur la période en cours.

## URL

`/operation/nouvelle` ou `/operation/{id}` (modification)

## Champs

| Nom | Type WEBDEV | Validation |
|---|---|---|
| `SAI_Date` | Date avec mini-calendrier | Obligatoire, dans la période en cours |
| `COMBO_Compte` | Combo Popup avec filtre (nouveauté 2026) | Obligatoire, recherche sémantique HFSQL |
| `SAI_Libelle` | Saisie texte | Obligatoire, max 200 car |
| `RADIO_Type` | Boutons segmentés (nouveauté 241) | Recette / Dépense |
| `SAI_MontantFCFA` | Saisie monétaire avec mini-calculatrice | > 0 |
| `LBL_MontantEUR` | Libellé calculé | Affichage auto via taux du jour |
| `UPL_PieceJointe` | Upload fichier | PDF/JPG/PNG, max 5 Mo |
| `BTN_Enregistrer` | Bouton primaire | Submit |
| `BTN_EnregistrerEtNouveau` | Bouton secondaire | Submit + reset |
| `BTN_Annuler` | Bouton tertiaire | Retour liste |

## Code — Initialisation

```wl
PROCÉDURE PAGE_SaisieOperation_OnInit(idOperation EST UNE CHAÎNE = "")

gUtilisateur EST UN ClasseUtilisateur = RecupererUtilisateurConnecte()
VerifierScope("COMMUNAUTAIRE")

// Charge la période en cours (validation : il doit y en avoir une ouverte)
gPeriode EST UN ClassePeriode = Periodes_RecupererPeriodeEnCours(gUtilisateur.IDCommunaute)

SI gPeriode.Statut <> "Ouvert" ALORS
    ToastAffiche("Aucune période ouverte — soumission impossible", ToastLong)
    PageAffiche(PAGE_TableauDeBord)
    RETOUR
FIN

// Limite la saisie à la période
SAI_Date..ValeurMin = gPeriode.DateDebut
SAI_Date..ValeurMax = gPeriode.DateFin
SAI_Date..Valeur = DateDuJour()

// Combo Compte avec filtre sémantique (nouveauté 2026)
COMBO_Compte..ListeFichier = ComptesTresorerie_RecupererListe()
COMBO_Compte..RechercheSémantique = Vrai  // Permet "carburant" → trouve "essence"

// Affiche le taux de change du jour
LBL_TauxJour..Libellé = ChaîneConstruit("Taux du %1 : 1 EUR = %2 FCFA",
    DateDuJour(), TauxChange_RecupererTauxJour())

// Mode modification ?
SI idOperation <> "" ALORS
    ChargerOperationExistante(idOperation)
FIN
```

## Code — Calcul automatique EUR

```wl
PROCÉDURE SAI_MontantFCFA_OnSortie()

SI SAI_MontantFCFA..Valeur > 0 ALORS
    dTaux EST UN MONÉTAIRE = TauxChange_RecupererTaux(SAI_Date..Valeur)
    LBL_MontantEUR..Libellé = ChaîneConstruit("≈ %1 EUR", SAI_MontantFCFA..Valeur / dTaux)
SINON
    LBL_MontantEUR..Libellé = ""
FIN
```

## Code — Enregistrement

```wl
PROCÉDURE BTN_Enregistrer_OnClick()

// Construction de l'objet opération (MVP)
opNouvelle EST UN ClasseOperation
opNouvelle.DateOperation = SAI_Date..Valeur
opNouvelle.NumCompte = COMBO_Compte..ValeurAffichée
opNouvelle.Libelle = SAI_Libelle..Valeur
opNouvelle.TypeOperation = SI RADIO_Type..Valeur = 1 ALORS "Recette" SINON "Dépense"
opNouvelle.MontantFCFA = SAI_MontantFCFA..Valeur
opNouvelle.IDPeriode = gPeriode.ID
opNouvelle.IDUtilisateurSaisie = gUtilisateur.IDUtilisateur

// Upload de la pièce jointe si présente
SI UPL_PieceJointe..NombreFichier > 0 ALORS
    opNouvelle.PieceJointe = UploadFichierVersStockage(UPL_PieceJointe)
FIN

// Appel REST (POST avec validation côté serveur)
vReponse EST UN VARIANT = HTTPEnvoieAsynchrone(   // Nouveauté 2026 : appel async
    "POST",
    "/api/operations",
    OperationVersJSON(opNouvelle),
    AvecTokenAuth()
)

vReponse.OnTermine = ProcedureCallback

PROCÉDURE INTERNE ProcedureCallback(reponse)
    SI reponse.CodeStatut = 201 ALORS
        ToastAffiche("Opération enregistrée", ToastCourt, vaCentre, hbBas)
        PageAffiche(PAGE_ListeOperations)
    SINON
        clErreur EST UN ClasseErreur = JSONVersErreur(reponse.Contenu)
        Erreur("Erreur : " + clErreur.Message)
    FIN
FIN
```

## FAA actives (par défaut WEBDEV 2026)

- Calendrier sur `SAI_Date`
- Mini-calculatrice sur `SAI_MontantFCFA`
- Correction orthographique sur `SAI_Libelle`
- Mémorisation des derniers comptes saisis (Combo)
- Export Excel/PDF de la liste (sur la page suivante)

## Sécurité

- Tous les contrôles d'autorisation sont **doublés côté serveur** (le client n'est pas digne de confiance)
- Validation des montants : pas de débordement, pas de scientifique
- Pièce jointe : MIME check serveur, scan antivirus si dispo
- CSP active — l'upload ne peut envoyer qu'au domaine de l'app

## Tests automatisés

1. Saisie complète recette FCFA → enregistrée + conversion EUR correcte
2. Saisie sans compte → erreur de validation
3. Date hors période → blocage côté client + côté serveur
4. Montant négatif → erreur 422
5. Pièce jointe 6 Mo → rejet
6. Pièce jointe `.exe` renommée `.pdf` → rejet (MIME check)
7. Soumission concurrente sur la même opération → conflit géré
