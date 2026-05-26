// ===========================================================================
// Periodes.wls — Workflow des périodes comptables
// EcoCommunauté Web (WEBDEV 2026)
//
// Machine à états :
//   Ouvert → Soumis → Validé      (chemin nominal)
//          ↘ Soumis → Rejeté → Ouvert  (boucle correction)
// ===========================================================================

// ---------------------------------------------------------------------------
// Periodes_Soumettre
// La communauté soumet sa période pour validation provincial.
// ---------------------------------------------------------------------------
PROCÉDURE Periodes_Soumettre(idPeriode EST UNE CHAÎNE) : ClasseResultat

clRes EST UN ClasseResultat
clUser EST UN ClasseUtilisateur = RecupererUtilisateurConnecte()

HRAZ(Periode)
SI PAS HLitRecherchePremier(Periode, IDPeriode, idPeriode) ALORS
    clRes.Message = "Période introuvable"
    RENVOYER clRes
FIN

SI Periode.Statut <> "Ouvert" ALORS
    clRes.Message = "Période déjà soumise ou clôturée"
    RENVOYER clRes
FIN

// Vérifie que la communauté correspond
clExercice EST UN ClasseExercice = Exercices_Recuperer(Periode.IDExercice)
SI clExercice.IDCommunaute <> clUser.IDCommunaute ALORS
    clRes.Message = "Accès refusé"
    AuditLog("PERIOD_SUBMIT_DENIED", clUser.Login, idPeriode)
    RENVOYER clRes
FIN

// Vérifie qu'il y a au moins une opération
SI HNbEnreg(Operation, "IDPeriode = '" + idPeriode + "'") = 0 ALORS
    clRes.Message = "Aucune opération saisie — impossible de soumettre"
    RENVOYER clRes
FIN

// Transition
Periode.Statut = "Soumis"
Periode.DateSoumission = MaintenantSys()
Periode.IDUtilisateurSoumission = clUser.IDUtilisateur
HModifie(Periode)

// Notifier le provincial par email
NotifierProvincialNouvelleSoumission(clExercice.IDCommunaute, idPeriode)

AuditLog("PERIOD_SUBMIT", clUser.Login, idPeriode)

clRes.Succes = Vrai
RENVOYER clRes

// ---------------------------------------------------------------------------
// Periodes_Valider
// Le provincial valide une période soumise.
// ---------------------------------------------------------------------------
PROCÉDURE Periodes_Valider(idPeriode EST UNE CHAÎNE,
                            sObservation EST UNE CHAÎNE = "") : ClasseResultat

clRes EST UN ClasseResultat
clUser EST UN ClasseUtilisateur = RecupererUtilisateurConnecte()

SI clUser.Profil <> "PROVINCIAL" ET clUser.Profil <> "ADMIN" ALORS
    clRes.Message = "Action réservée au provincial"
    RENVOYER clRes
FIN

HRAZ(Periode)
HLitRecherchePremier(Periode, IDPeriode, idPeriode)

SI Periode.Statut <> "Soumis" ALORS
    clRes.Message = "Seule une période 'Soumis' peut être validée"
    RENVOYER clRes
FIN

// Vérifie que la communauté est dans la province du provincial
clExercice EST UN ClasseExercice = Exercices_Recuperer(Periode.IDExercice)
clComm EST UN ClasseCommunaute = Communautes_Recuperer(clExercice.IDCommunaute)

SI clUser.Profil = "PROVINCIAL" ET clComm.Province <> clUser.Province ALORS
    clRes.Message = "Cette communauté n'est pas dans votre province"
    AuditLog("PERIOD_VALIDATE_DENIED", clUser.Login, idPeriode)
    RENVOYER clRes
FIN

HTransactionDébut()
QUAND EXCEPTION DANS
    Periode.Statut = "Validé"
    Periode.DateValidation = MaintenantSys()
    Periode.IDValidateur = clUser.IDUtilisateur
    Periode.ObservationProvincial = sObservation
    HModifie(Periode)

    HTransactionFin()

    NotifierCommunauteValidation(clComm.IDCommunaute, idPeriode, sObservation)
    AuditLog("PERIOD_VALIDATE", clUser.Login, idPeriode)

    clRes.Succes = Vrai
FAIRE
    HTransactionAnnule()
    clRes.Message = "Erreur : " + ExceptionInfo()
FIN

RENVOYER clRes

// ---------------------------------------------------------------------------
// Periodes_Rejeter
// Le provincial rejette une période (renvoyée à la communauté pour correction).
// ---------------------------------------------------------------------------
PROCÉDURE Periodes_Rejeter(idPeriode EST UNE CHAÎNE,
                            sMotifRejet EST UNE CHAÎNE) : ClasseResultat

clRes EST UN ClasseResultat

SI sMotifRejet = "" ALORS
    clRes.Message = "Motif de rejet obligatoire"
    RENVOYER clRes
FIN

clUser EST UN ClasseUtilisateur = RecupererUtilisateurConnecte()

HRAZ(Periode)
HLitRecherchePremier(Periode, IDPeriode, idPeriode)

SI Periode.Statut <> "Soumis" ALORS
    clRes.Message = "Seule une période 'Soumis' peut être rejetée"
    RENVOYER clRes
FIN

Periode.Statut = "Ouvert"  // Retour à Ouvert pour permettre les corrections
Periode.ObservationProvincial = sMotifRejet
Periode.DateRejet = MaintenantSys()
HModifie(Periode)

clExercice EST UN ClasseExercice = Exercices_Recuperer(Periode.IDExercice)
NotifierCommunauteRejet(clExercice.IDCommunaute, idPeriode, sMotifRejet)

AuditLog("PERIOD_REJECT", clUser.Login, idPeriode, sMotifRejet)

clRes.Succes = Vrai
RENVOYER clRes

// ---------------------------------------------------------------------------
// Periodes_RecupererPeriodeEnCours
// Renvoie la période ouverte de la communauté (ou crée la prochaine si besoin).
// ---------------------------------------------------------------------------
PROCÉDURE Periodes_RecupererPeriodeEnCours(idCommunaute EST UNE CHAÎNE) : ClassePeriode

clExerciceCourant EST UN ClasseExercice = Exercices_ExerciceCourant(idCommunaute)

HRAZ(Periode)
HExécuteRequêteSQL(REQ_PeriodeOuverte,
    "SELECT * FROM Periode WHERE IDExercice = {idExo} AND Statut = 'Ouvert' LIMIT 1",
    idExo = clExerciceCourant.IDExercice)

SI HEnDehors(REQ_PeriodeOuverte) ALORS
    // Aucune période ouverte — créer le trimestre courant
    RENVOYER Periodes_CreerProchainTrimestre(clExerciceCourant.IDExercice)
SINON
    RENVOYER PeriodeVersDTO(REQ_PeriodeOuverte)
FIN

// ---------------------------------------------------------------------------
// Periodes_MettreAJourTotaux
// Recalcule les totaux dénormalisés de la période (appelé après chaque op).
// ---------------------------------------------------------------------------
PROCÉDURE Periodes_MettreAJourTotaux(idPeriode EST UNE CHAÎNE)

HExécuteRequêteSQL(REQ_TotauxPeriode, [
    SELECT
        SUM(CASE WHEN TypeOperation='Recette' THEN MontantFCFA ELSE 0 END) AS TotalRecFCFA,
        SUM(CASE WHEN TypeOperation='Dépense' THEN MontantFCFA ELSE 0 END) AS TotalDepFCFA,
        SUM(CASE WHEN TypeOperation='Recette' THEN MontantEUR ELSE 0 END) AS TotalRecEUR,
        SUM(CASE WHEN TypeOperation='Dépense' THEN MontantEUR ELSE 0 END) AS TotalDepEUR,
        COUNT(*) AS NbOperations
    FROM Operation
    WHERE IDPeriode = {idPer}
], idPer = idPeriode)

HLitPremier(REQ_TotauxPeriode)

HRAZ(Periode)
HLitRecherchePremier(Periode, IDPeriode, idPeriode)
Periode.TotalRecettesFCFA = REQ_TotauxPeriode.TotalRecFCFA
Periode.TotalDepensesFCFA = REQ_TotauxPeriode.TotalDepFCFA
Periode.TotalRecettesEUR = REQ_TotauxPeriode.TotalRecEUR
Periode.TotalDepensesEUR = REQ_TotauxPeriode.TotalDepEUR
Periode.NbOperations = REQ_TotauxPeriode.NbOperations
HModifie(Periode)
