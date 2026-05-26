# PAGE_Rapports — Génération de rapports

## Rôle

Génère les rapports comptables (trimestriels, annuels) en PDF ou Excel. Utilisable par les 3 profils avec scope adapté.

## URL

`/rapports?type={trimestriel|annuel}&periode={id}&format={pdf|xlsx}`

## Types de rapports

| Type | Profil | Périmètre |
|---|---|---|
| Rapport trimestriel communautaire | COMMUNAUTAIRE | Sa communauté, son trimestre |
| Rapport annuel communautaire | COMMUNAUTAIRE | Sa communauté, son exercice |
| Rapport annuel provincial | PROVINCIAL | Toutes les communautés de sa province |
| Rapport consolidé global | ADMIN | Tout |

## Layout

```
┌──────────────────────────────────────────────────────────┐
│ Génération de rapport                                    │
├──────────────────────────────────────────────────────────┤
│  Type :       [Trimestriel ▼]                            │
│  Période :    [T2 2026 ▼]                                │
│  Communauté : [Ma communauté (verrouillé)]               │
│  Format :     ⦿ PDF  ○ Excel                             │
│  Devise :     ⦿ FCFA  ○ EUR  ○ Les deux                  │
│  Inclure :    ☑ Détail opérations                        │
│               ☑ Graphiques                                │
│               ☑ Pièces justificatives                     │
│                                                          │
│  Signature :  [Sélectionner un certificat ▼]             │
│               (carte à puce / certificat eIDAS)          │
│                                                          │
│              [Générer]    [Aperçu]                       │
└──────────────────────────────────────────────────────────┘
```

## Nouveautés WEBDEV 2026

### Signature par carte à puce (nouveauté 254-256)

Le rapport PDF peut être signé numériquement avec un certificat présent sur une carte à puce (carte professionnelle, eIDAS). La clé privée ne quitte jamais la carte.

```wl
PROCÉDURE GenererRapportSigné(idCertificat EST UN ENTIER)

// Liste les certificats disponibles (y compris cartes à puce)
tabCertificats EST UN TABLEAU = CertificatListe()

clCert EST UN Certificat = tabCertificats[idCertificat]

// Génération du rapport
cheminPDF EST UNE CHAÎNE = GenererRapportPDF(...)

// Signature avec la carte à puce
PDFSigne(cheminPDF, clCert, "Provincial — Signature de contrôle")

// Le fichier est désormais signé eIDAS
```

### Streaming Chunk pour les gros rapports

Un rapport annuel provincial avec 50 communautés peut dépasser 50 Mo. WEBDEV 2026 supporte le streaming Chunk natif pour ne pas saturer la mémoire serveur.

```wl
PROCÉDURE ExporterRapportStreaming()

HTTPRéponseEntêteRépond("Content-Type", "application/pdf")
HTTPRéponseEntêteRépond("Content-Disposition", "attachment; filename=rapport_annuel.pdf")
HTTPRéponseStreaming(Vrai)  // Active le streaming Chunk

POUR TOUT comm DE Communautes_RecupererParProvince(gProvince)
    bufChunk EST UN BUFFER = GenererChunkRapport(comm)
    HTTPRéponseStreamingÉcrit(bufChunk)
FIN

HTTPRéponseStreamingTermine()
```

## Code — Génération synchrone (rapport trimestriel)

```wl
PROCÉDURE BTN_Generer_OnClick()

clParams EST UN ClasseParametresRapport
clParams.Type = COMBO_Type..ValeurAffichée
clParams.IDPeriode = COMBO_Periode..Valeur
clParams.Format = SI RADIO_Format..Valeur = 1 ALORS "pdf" SINON "xlsx"
clParams.Devise = COMBO_Devise..ValeurAffichée
clParams.InclureGraphiques = CHK_Graphiques..Valeur
clParams.IDCertificatSignature = COMBO_Certificat..Valeur

// Appel asynchrone pour ne pas bloquer l'UI
HTTPEnvoieAsynchrone(
    "POST",
    "/api/rapports/generer",
    ObjetVersJSON(clParams),
    AvecTokenAuth(),
    ProcedureCallback
)

ToastAffiche("Génération en cours...", ToastCourt)

PROCÉDURE INTERNE ProcedureCallback(reponse)
    SI reponse.CodeStatut = 200 ALORS
        // Le serveur a renvoyé l'URL de téléchargement
        clRes EST UN ClasseUrlTelechargement = JSONVersUrl(reponse.Contenu)
        PageRedirigeNouvelOnglet(clRes.URL)
    SINON
        Erreur("Génération échouée : " + reponse.Contenu)
    FIN
FIN
```

## Code — Génération asynchrone pour gros volumes (job)

```wl
// Pour le rapport annuel provincial, on utilise une file de jobs
PROCÉDURE BTN_GenererAnnuelProvincial_OnClick()

// Crée un job côté serveur
vRep EST UN VARIANT = HTTPRequête("/api/rapports/job", "POST",
    ObjetVersJSON(clParams), AvecTokenAuth())

idJob EST UNE CHAÎNE = JSONVersString(vRep.Contenu, "idJob")

// Affiche une barre de progression
JAUGE_Progression..Visible = Vrai
TIMER_Polling = TimerSys(2000, "VerifierJob", idJob)


PROCÉDURE VerifierJob(idJob)
    vStatut EST UN VARIANT = HTTPRequête(
        ChaîneConstruit("/api/rapports/job/%1/status", idJob),
        "GET", "", AvecTokenAuth())

    clStatut EST UN ClasseJobStatut = JSONVersJobStatut(vStatut.Contenu)
    JAUGE_Progression..Valeur = clStatut.Progression

    SI clStatut.Statut = "TERMINE" ALORS
        FinTimerSys(TIMER_Polling)
        PageRedirigeNouvelOnglet(clStatut.URLTelechargement)
    SINON SI clStatut.Statut = "ECHEC" ALORS
        FinTimerSys(TIMER_Polling)
        Erreur("Génération échouée : " + clStatut.MessageErreur)
    FIN
FIN
```

## Sécurité

- L'autorisation est vérifiée côté serveur (un COMMUNAUTAIRE ne peut pas demander un rapport global)
- Les rapports générés ne sont accessibles que via un **token signé à expiration courte** (15 min)
- Les rapports sont **chiffrés au repos** sur le serveur si stockés
- L'accès au rapport est tracé dans `AUDIT_LOG`

## Tests automatisés

1. Rapport trimestriel COMMUNAUTAIRE → PDF généré < 5 s
2. Rapport annuel provincial 50 communautés → streaming OK, pas d'OOM
3. Téléchargement avec token expiré → 403
4. Signature avec carte à puce → PDF vérifiable
5. Rapport sur exercice clos → autorisé
6. Rapport sur communauté non autorisée → 403
