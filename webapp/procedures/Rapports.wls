// ===========================================================================
// Rapports.wls — Génération de rapports comptables
// EcoCommunauté Web (WEBDEV 2026)
//
// Supporte :
//   - Génération synchrone (rapports courts)
//   - Génération asynchrone via jobs (rapports volumineux)
//   - Streaming HTTP Chunk (nouveauté 2026) pour gros exports
//   - Signature numérique par carte à puce (nouveauté 2026)
// ===========================================================================

// ---------------------------------------------------------------------------
// Rapports_GenererTrimestriel
// Génère un rapport trimestriel communautaire (PDF ou Excel).
// Synchrone : la génération prend < 5 s pour un trimestre.
// ---------------------------------------------------------------------------
PROCÉDURE Rapports_GenererTrimestriel(clParams EST UN ClasseParametresRapport) : ClasseRapportGenere

clRes EST UN ClasseRapportGenere
clUser EST UN ClasseUtilisateur = RecupererUtilisateurConnecte()

// --- AUTORISATION ---
clPeriode EST UN ClassePeriode = Periodes_Recuperer(clParams.IDPeriode)
clExercice EST UN ClasseExercice = Exercices_Recuperer(clPeriode.IDExercice)

SI clUser.Profil = "COMMUNAUTAIRE" ET clExercice.IDCommunaute <> clUser.IDCommunaute ALORS
    clRes.Erreur = "Accès refusé"
    AuditLog("REPORT_DENIED", clUser.Login, clParams.IDPeriode)
    RENVOYER clRes
FIN

// --- COLLECTE DES DONNÉES ---
tabOperations EST UN TABLEAU = Operations_Lister(
    Création(IDPeriode: clParams.IDPeriode), 1, 9999).Items

clTotaux EST UN ClasseTotauxPeriode = CalculerTotauxPeriode(clParams.IDPeriode)

// --- GÉNÉRATION ---
sCheminFichier EST UNE CHAÎNE

SELON clParams.Format
    CAS "pdf"
        sCheminFichier = GenererPDF(clPeriode, tabOperations, clTotaux, clParams)

        // Signature numérique par carte à puce (nouveauté 2026)
        SI clParams.IDCertificatSignature <> 0 ALORS
            SignerPDFAvecCertificat(sCheminFichier, clParams.IDCertificatSignature)
        FIN

    CAS "xlsx"
        sCheminFichier = GenererExcel(clPeriode, tabOperations, clTotaux, clParams)

    CAS AUTRE
        clRes.Erreur = "Format non supporté"
        RENVOYER clRes
FIN

// --- URL DE TÉLÉCHARGEMENT TEMPORAIRE ---
sToken EST UNE CHAÎNE = GenererTokenTelechargement(sCheminFichier, 900)  // 15 min
clRes.URL = ChaîneConstruit("/api/rapports/telecharger/%1", sToken)
clRes.NomFichier = ExtraitNomFichier(sCheminFichier)
clRes.TailleOctets = fTaille(sCheminFichier)

AuditLog("REPORT_GENERATED", clUser.Login,
    ChaîneConstruit("Type=%1 Periode=%2", clParams.Type, clParams.IDPeriode))

RENVOYER clRes

// ---------------------------------------------------------------------------
// Rapports_LancerJobAnnuelProvincial
// Lance un job asynchrone pour le rapport annuel provincial.
// Le rapport peut prendre plusieurs minutes pour 50+ communautés.
// ---------------------------------------------------------------------------
PROCÉDURE Rapports_LancerJobAnnuelProvincial(idExercice EST UNE CHAÎNE,
                                              sProvince EST UNE CHAÎNE) : ClasseJob

clUser EST UN ClasseUtilisateur = RecupererUtilisateurConnecte()
VerifierScope("PROVINCIAL")

// Crée le job en base
HRAZ(Job)
Job.IDJob = GenererUUID()
Job.Type = "RAPPORT_ANNUEL_PROVINCIAL"
Job.Parametres = ChaîneConstruit("""{"idExercice":"%1","province":"%2"}""",
    idExercice, sProvince)
Job.Statut = "EN_ATTENTE"
Job.IDUtilisateur = clUser.IDUtilisateur
Job.DateCreation = MaintenantSys()
Job.Progression = 0
HAjoute(Job)

// Lance le traitement asynchrone (nouveauté 2026 : HExécuteProcédureAsynchrone)
HExécuteProcédureAsynchrone(TraiterJobRapportAnnuel, Job.IDJob)

clJob EST UN ClasseJob
clJob.IDJob = Job.IDJob
clJob.Statut = "EN_ATTENTE"

AuditLog("REPORT_JOB_CREATED", clUser.Login, Job.IDJob)
RENVOYER clJob

// ---------------------------------------------------------------------------
// TraiterJobRapportAnnuel (procédure asynchrone)
// Génère le rapport annuel provincial en streaming.
// ---------------------------------------------------------------------------
PROCÉDURE PRIVÉE TraiterJobRapportAnnuel(idJob EST UNE CHAÎNE)

HRAZ(Job)
HLitRecherchePremier(Job, IDJob, idJob)
Job.Statut = "EN_COURS"
Job.DateDebut = MaintenantSys()
HModifie(Job)

vParams EST UN VARIANT = JSONVersVariant(Job.Parametres)
sIDExercice EST UNE CHAÎNE = vParams.idExercice
sProvince EST UNE CHAÎNE = vParams.province

// Liste des communautés
tabComm EST UN TABLEAU = Communautes_RecupererParProvince(sProvince)
iNbComm EST UN ENTIER = TableauOccurrence(tabComm)

// Génère un PDF maître + un sous-PDF par communauté
sCheminMaster EST UNE CHAÎNE = ChaîneConstruit("/tmp/rapport_annuel_%1_%2.pdf",
    sProvince, sIDExercice)

iPDF EST UN PDF = pdfCrée(sCheminMaster)

POUR i = 1 _A_ iNbComm
    clComm EST UN ClasseCommunaute = tabComm[i]
    bufSousPDF EST UN BUFFER = GenererSousPDFCommunaute(clComm, sIDExercice)
    pdfAjoute(iPDF, bufSousPDF)

    // Mise à jour de la progression
    Job.Progression = (i * 100) / iNbComm
    HModifie(Job)
FIN

pdfFerme(iPDF)

Job.Statut = "TERMINE"
Job.DateFin = MaintenantSys()
Job.URLResultat = ChaîneConstruit("/api/rapports/telecharger/%1",
    GenererTokenTelechargement(sCheminMaster, 3600))
HModifie(Job)

// ---------------------------------------------------------------------------
// Rapports_StreamerExportCSV
// Streaming Chunk pour un export CSV de millions de lignes.
// ---------------------------------------------------------------------------
PROCÉDURE Rapports_StreamerExportCSV(clFiltre EST UN ClasseFiltreOperations)

clUser EST UN ClasseUtilisateur = RecupererUtilisateurConnecte()
VerifierAccesExport(clFiltre)

HTTPRéponseEntête("Content-Type", "text/csv; charset=utf-8")
HTTPRéponseEntête("Content-Disposition", "attachment; filename=operations.csv")
HTTPRéponseEntête("Transfer-Encoding", "chunked")

// Entête CSV
HTTPRéponseStream("Date,Compte,Libellé,Type,Montant FCFA,Montant EUR" + RC)

// Requête streamée HFSQL (pas de chargement en mémoire complet)
sSQL EST UNE CHAÎNE = ConstruireRequeteOperationsExport(clFiltre)
HExécuteRequêteSQL(REQ_ExportOp, sSQL)

iCompteur EST UN ENTIER = 0
POUR TOUT REQ_ExportOp
    sLigne EST UNE CHAÎNE = ChaîneConstruit("%1,%2,""%3"",%4,%5,%6" + RC,
        REQ_ExportOp.DateOperation,
        REQ_ExportOp.NumCompte,
        Remplace(REQ_ExportOp.Libelle, """", """"""),
        REQ_ExportOp.TypeOperation,
        REQ_ExportOp.MontantFCFA,
        REQ_ExportOp.MontantEUR)

    HTTPRéponseStream(sLigne)
    iCompteur ++

    // Flush tous les 1000 lignes
    SI iCompteur MOD 1000 = 0 ALORS
        HTTPRéponseFlush()
    FIN
FIN

HTTPRéponseFinStream()
AuditLog("EXPORT_CSV", clUser.Login, ChaîneConstruit("%1 lignes", iCompteur))

// ---------------------------------------------------------------------------
// SignerPDFAvecCertificat (nouveauté 2026)
// Signe un PDF avec un certificat de carte à puce. La clé privée ne quitte jamais la carte.
// ---------------------------------------------------------------------------
PROCÉDURE PRIVÉE SignerPDFAvecCertificat(sChemin EST UNE CHAÎNE, idCertificat EST UN ENTIER)

tabCertificats EST UN TABLEAU = CertificatListe()

clCert EST UN Certificat = tabCertificats[idCertificat]

// Vérifie la validité
SI clCert.DateExpiration < DateDuJour() ALORS
    Erreur("Certificat expiré")
    RETOUR
FIN

// La signature est effectuée DANS la carte à puce (jamais exposée)
PDFSigne(sChemin, clCert,
    ChaîneConstruit("Signé par %1 - %2", clCert.Sujet, DateDuJour()))
