# PAGE_Administration — Espace admin

## Rôle

Espace réservé au profil **ADMIN**. Centralise la gestion des communautés, utilisateurs, exercices, taux de change, imports et consultation du journal d'audit.

## URL

`/admin` (scope `ADMIN` requis — vérifié OAuth + Groupware)

## Sous-pages

| Sous-page | URL | Action principale |
|---|---|---|
| `PAGE_AdminCommunautes` | `/admin/communautes` | CRUD communautés + carte OpenStreetMap |
| `PAGE_AdminUtilisateurs` | `/admin/utilisateurs` | CRUD utilisateurs + reset mot de passe |
| `PAGE_AdminExercices` | `/admin/exercices` | Création / clôture exercices fiscaux |
| `PAGE_AdminTauxChange` | `/admin/taux` | Mise à jour des taux FCFA/EUR |
| `PAGE_AdminImports` | `/admin/imports` | Import Excel : plan de comptes, notes |
| `PAGE_AdminAudit` | `/admin/audit` | Journal d'audit complet, exportable |

---

## PAGE_AdminCommunautes — Avec carte OpenStreetMap (nouveauté 2026)

```wl
PROCÉDURE PAGE_AdminCommunautes_OnInit()

VerifierScope("ADMIN")

// Chargement de la table des communautés
TableAfficheRéSultat(TBL_Communautes, Communautes_RecupererToutes())

// Carte OpenStreetMap (nouveauté 2026 — pas besoin de clé Google Maps)
CarteOSM_Communautes..TypeCarte = osmStandard
CarteOSM_Communautes..AfficheControlesZoom = Vrai

POUR TOUT comm DE Communautes_RecupererToutes()
    SI comm.Latitude <> 0 ET comm.Longitude <> 0 ALORS
        CarteAjoutemarker(CarteOSM_Communautes,
            comm.Latitude, comm.Longitude,
            comm.Nom,
            "/images/marker_communaute.svg")
    FIN
FIN

// Centre sur le barycentre des communautés
CarteCentrePosition(CarteOSM_Communautes, BarycentreCommunautes())
```

---

## PAGE_AdminUtilisateurs — Géré par OAuth Server (wdbaas)

```wl
PROCÉDURE BTN_CreerUtilisateur_OnClick()

clUser EST UN ClasseUtilisateur
clUser.Login = SAI_Login..Valeur
clUser.Email = SAI_Email..Valeur
clUser.Profil = COMBO_Profil..ValeurAffichée
clUser.IDCommunaute = COMBO_Communaute..Valeur
clUser.DoubleAuth = CHK_2FA..Valeur

// Mot de passe initial aléatoire — envoyé par email
sMotDePasseInitial EST UNE CHAÎNE = GenererMotDePasseFort(16)

// Création via OAuth Server (nouveauté 2026)
clResultat EST UN ClasseResultat = wdbaasCreeUtilisateur(
    clUser.Login,
    sMotDePasseInitial,
    Variant(Profil: clUser.Profil, IDCommunaute: clUser.IDCommunaute)
)

SI clResultat.Succes ALORS
    EnvoyerEmailBienvenue(clUser.Email, clUser.Login, sMotDePasseInitial)
    ToastAffiche("Utilisateur créé — email envoyé", ToastLong)
    AuditLog("USER_CREATE", clUser.Login)
    PageActualise()
SINON
    Erreur(clResultat.MessageErreur)
FIN
```

```wl
PROCÉDURE BTN_ReinitMotDePasse_OnClick(idUtilisateur EST UNE CHAÎNE)

SI OuiNon("Réinitialiser le mot de passe ? Un nouveau sera envoyé par email.") <> Oui ALORS
    RETOUR
FIN

sNouveauMDP EST UNE CHAÎNE = GenererMotDePasseFort(16)
wdbaasModifieUtilisateur(idUtilisateur, sNouveauMDP)

// Force expiration au premier login
wdbaasMarqueMotDePasseExpire(idUtilisateur)

EnvoyerEmailResetMDP(idUtilisateur, sNouveauMDP)
AuditLog("USER_RESET_PWD", idUtilisateur)
```

---

## PAGE_AdminTauxChange — Avec récupération automatique

```wl
PROCÉDURE BTN_RecupererTauxOfficiel_OnClick()

// Appel à l'API de la BCEAO (Banque Centrale des États de l'Afrique de l'Ouest)
// pour le taux EUR/FCFA officiel du jour

vRep EST UN VARIANT = HTTPRequête("https://api.bceao.int/taux/jour/EUR-XOF",
    "GET", "", "")

SI vRep.CodeStatut = 200 ALORS
    dTaux EST UN MONÉTAIRE = JSONVersDecimal(vRep.Contenu, "taux")
    SAI_Taux..Valeur = dTaux
    LBL_Source..Libellé = "Source : BCEAO API officielle"
SINON
    Erreur("Récupération impossible — saisir manuellement")
FIN
```

---

## PAGE_AdminImports — Avec recherche sémantique HFSQL

L'import d'un plan de comptes Excel utilise la **recherche sémantique HFSQL 2026** pour suggérer automatiquement la classification des comptes.

```wl
PROCÉDURE ImporterPlanComptes(cheminExcel EST UNE CHAÎNE)

// Lecture du fichier Excel via xlsxOuvre
xlsxFichier EST UN xlsxDocument = xlsxOuvre(cheminExcel)

POUR i = 2 _A_ xlsxNombreLigne(xlsxFichier, "Comptes")
    sNumCompte EST UNE CHAÎNE = xlsxDonnée(xlsxFichier, i, 1)
    sLibelle EST UNE CHAÎNE = xlsxDonnée(xlsxFichier, i, 2)

    // Nouveauté 2026 : suggestion via similarité sémantique
    sClasseSuggérée EST UNE CHAÎNE = SuggererClasseCompte(sLibelle)

    HRAZ(CompteTresorerie)
    CompteTresorerie.NumCompte = sNumCompte
    CompteTresorerie.Libelle = sLibelle
    CompteTresorerie.Classe = sClasseSuggérée
    HAjoute(CompteTresorerie)

    // Réindexe le vecteur sémantique
    HRecalculeEmbedding(CompteTresorerie, "Libelle")
FIN
```

---

## PAGE_AdminAudit — Journal d'audit complet

```wl
PROCÉDURE PAGE_AdminAudit_OnInit()

// Filtres avancés
COMBO_Action..ListeElement = "TOUS,LOGIN,LOGOUT,USER_CREATE,USER_DELETE,PERIODE_SOUMIS,PERIODE_VALIDE,PERIODE_REJETE,RAPPORT_GENERE,EXPORT_DATA"
SAI_DateDebut..Valeur = DateDuJour() - 30
SAI_DateFin..Valeur = DateDuJour()

ChargerLogs()


PROCÉDURE ChargerLogs()
    sFiltre EST UNE CHAÎNE = ConstruireFiltreSQL()

    // Pagination obligatoire (peut dépasser 100k entrées)
    tabLogs EST UN TABLEAU = AuditLog_Rechercher(sFiltre,
        TBL_Audit..PageEnCours,
        TBL_Audit..NombreLignePage)

    TableAfficheRéSultat(TBL_Audit, tabLogs)
FIN
```

```wl
PROCÉDURE BTN_ExporterAudit_OnClick()

// Export en CSV streaming (jusqu'à 1M lignes possibles)
PageRedirige(ChaîneConstruit("/api/audit/export?from=%1&to=%2&format=csv&streaming=true",
    SAI_DateDebut..Valeur, SAI_DateFin..Valeur))
```

---

## Sécurité globale de l'espace admin

- **Double authentification obligatoire** pour tous les comptes ADMIN
- IP whitelisting possible (config OAuth Server)
- Toutes les actions admin sont tracées dans `AUDIT_LOG`
- Confirmation systématique pour les actions destructives (suppression user, clôture exercice)
- Session admin avec timeout court (15 min d'inactivité)

## Tests automatisés

1. Connexion ADMIN sans 2FA → bloqué
2. Création utilisateur → email envoyé + entrée audit
3. Reset password → utilisateur doit changer au prochain login
4. Import Excel 1000 comptes → toutes les classes suggérées correctes à > 80 %
5. Export audit 50 000 entrées → streaming OK
6. Tentative d'accès admin par un user PROVINCIAL → 403 + entrée audit
