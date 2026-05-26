// ===========================================================================
// Operations.wls — Procédures métier pour les opérations comptables
// EcoCommunauté Web (WEBDEV 2026)
//
// Architecture : couche métier appelée par les pages ET par les webservices
// Toutes les vérifications de scope/autorisation sont déléguées à Auth.wls
// ===========================================================================

// ---------------------------------------------------------------------------
// Operations_Ajouter
// Crée une nouvelle opération comptable après validation complète.
// Lève une exception métier si la période n'est pas modifiable.
// ---------------------------------------------------------------------------
PROCÉDURE Operations_Ajouter(clOp EST UN ClasseOperation) : ClasseResultat

clRes EST UN ClasseResultat
clRes.Succes = Faux

// --- VALIDATION MÉTIER ---
dbgVérifieNonNull(clOp.IDPeriode, "IDPeriode obligatoire")
dbgVérifie(clOp.MontantFCFA > 0, "Montant doit être > 0")
dbgVérifie(EnsembleContient({"Recette", "Dépense"}, clOp.TypeOperation),
    "TypeOperation invalide")

// Vérifie que la période existe et est ouverte
clPeriode EST UN ClassePeriode = Periodes_Recuperer(clOp.IDPeriode)
SI clPeriode = Null ALORS
    clRes.Message = "Période inexistante"
    RENVOYER clRes
FIN

SI clPeriode.Statut <> "Ouvert" ALORS
    clRes.Message = ChaîneConstruit("Période en statut '%1' — modification impossible",
        clPeriode.Statut)
    RENVOYER clRes
FIN

// Vérifie que la date est dans la période
SI clOp.DateOperation < clPeriode.DateDebut OU clOp.DateOperation > clPeriode.DateFin ALORS
    clRes.Message = "Date hors de la période"
    RENVOYER clRes
FIN

// Vérifie que l'utilisateur appartient à la bonne communauté
clUser EST UN ClasseUtilisateur = RecupererUtilisateurConnecte()
clExercice EST UN ClasseExercice = Exercices_Recuperer(clPeriode.IDExercice)

SI clUser.Profil = "COMMUNAUTAIRE" ET clExercice.IDCommunaute <> clUser.IDCommunaute ALORS
    clRes.Message = "Accès refusé sur cette communauté"
    AuditLog("UNAUTHORIZED_OP_ATTEMPT", clUser.Login,
        "Tentative sur " + clExercice.IDCommunaute)
    RENVOYER clRes
FIN

// --- CALCUL EUR ---
dTaux EST UN MONÉTAIRE = TauxChange_RecupererTaux(clOp.DateOperation)
clOp.MontantEUR = clOp.MontantFCFA / dTaux
clOp.TauxApplique = dTaux

// --- TRANSACTION ---
HTransactionDébut()

QUAND EXCEPTION DANS
    // Insertion de l'opération
    HRAZ(Operation)
    Operation.IDOperation = GenererUUID()
    Operation.DateOperation = clOp.DateOperation
    Operation.NumCompte = clOp.NumCompte
    Operation.Libelle = clOp.Libelle
    Operation.TypeOperation = clOp.TypeOperation
    Operation.MontantFCFA = clOp.MontantFCFA
    Operation.MontantEUR = clOp.MontantEUR
    Operation.TauxApplique = clOp.TauxApplique
    Operation.PieceJointe = clOp.PieceJointe
    Operation.IDPeriode = clOp.IDPeriode
    Operation.IDUtilisateurSaisie = clUser.IDUtilisateur
    HAjoute(Operation)

    // Mise à jour des totaux de la période (dénormalisé pour la perf)
    Periodes_MettreAJourTotaux(clOp.IDPeriode)

    // Recalcule le vecteur sémantique du libellé (nouveauté 2026)
    HRecalculeEmbedding(Operation, "Libelle")

    HTransactionFin()

    clRes.Succes = Vrai
    clRes.IDCreee = Operation.IDOperation

    AuditLog("OPERATION_CREATE", clUser.Login,
        ChaîneConstruit("ID=%1 Mt=%2 FCFA", Operation.IDOperation, clOp.MontantFCFA))

FAIRE
    HTransactionAnnule()
    clRes.Message = "Erreur transaction : " + ExceptionInfo()
    AuditLog("OPERATION_FAIL", clUser.Login, ExceptionInfo())
FIN

RENVOYER clRes

// ---------------------------------------------------------------------------
// Operations_Modifier
// Modifie une opération existante (uniquement si période ouverte).
// ---------------------------------------------------------------------------
PROCÉDURE Operations_Modifier(clOp EST UN ClasseOperation) : ClasseResultat

clRes EST UN ClasseResultat = ValiderModification(clOp.IDOperation)
SI PAS clRes.Succes ALORS RENVOYER clRes

HRAZ(Operation)
HLitRecherchePremier(Operation, IDOperation, clOp.IDOperation)

// Conserve les champs immuables
sIDSaisie EST UNE CHAÎNE = Operation.IDUtilisateurSaisie
sIDPeriode EST UNE CHAÎNE = Operation.IDPeriode

Operation.DateOperation = clOp.DateOperation
Operation.NumCompte = clOp.NumCompte
Operation.Libelle = clOp.Libelle
Operation.MontantFCFA = clOp.MontantFCFA
Operation.MontantEUR = clOp.MontantFCFA / TauxChange_RecupererTaux(clOp.DateOperation)
Operation.TypeOperation = clOp.TypeOperation

HModifie(Operation)
HRecalculeEmbedding(Operation, "Libelle")
Periodes_MettreAJourTotaux(sIDPeriode)

clUser EST UN ClasseUtilisateur = RecupererUtilisateurConnecte()
AuditLog("OPERATION_UPDATE", clUser.Login, clOp.IDOperation)

clRes.Succes = Vrai
RENVOYER clRes

// ---------------------------------------------------------------------------
// Operations_Supprimer
// Supprime une opération (uniquement si période ouverte).
// ---------------------------------------------------------------------------
PROCÉDURE Operations_Supprimer(idOperation EST UNE CHAÎNE) : ClasseResultat

clRes EST UN ClasseResultat = ValiderModification(idOperation)
SI PAS clRes.Succes ALORS RENVOYER clRes

HRAZ(Operation)
HLitRecherchePremier(Operation, IDOperation, idOperation)

sIDPeriode EST UNE CHAÎNE = Operation.IDPeriode
HSupprime(Operation)

Periodes_MettreAJourTotaux(sIDPeriode)

clUser EST UN ClasseUtilisateur = RecupererUtilisateurConnecte()
AuditLog("OPERATION_DELETE", clUser.Login, idOperation)

clRes.Succes = Vrai
RENVOYER clRes

// ---------------------------------------------------------------------------
// Operations_Lister
// Liste paginée des opérations selon filtres.
// Le filtre par communauté est FORCÉ pour les profils COMMUNAUTAIRE.
// ---------------------------------------------------------------------------
PROCÉDURE Operations_Lister(clFiltre EST UN ClasseFiltreOperations,
                             iPage EST UN ENTIER = 1,
                             iLimite EST UN ENTIER = 50) : ClasseListePaginee

clUser EST UN ClasseUtilisateur = RecupererUtilisateurConnecte()

// Filtre forcé selon le profil
SELON clUser.Profil
    CAS "COMMUNAUTAIRE"
        clFiltre.IDCommunaute = clUser.IDCommunaute  // override
    CAS "PROVINCIAL"
        clFiltre.Province = clUser.Province  // override
    CAS "ADMIN"
        // Pas de filtre forcé
FIN

// Construit la requête paramétrée (jamais de concaténation SQL — sécurité)
sRequete EST UNE CHAÎNE = ConstruireRequeteOperations(clFiltre)

REQ_Operations.ParamIDPeriode = clFiltre.IDPeriode
REQ_Operations.ParamIDCommunaute = clFiltre.IDCommunaute
REQ_Operations.ParamTypeOp = clFiltre.TypeOperation
REQ_Operations.ParamDateDebut = clFiltre.DateDebut
REQ_Operations.ParamDateFin = clFiltre.DateFin
REQ_Operations.ParamLimite = iLimite
REQ_Operations.ParamOffset = (iPage - 1) * iLimite

HExécuteRequête(REQ_Operations)

clRes EST UN ClasseListePaginee
clRes.Page = iPage
clRes.TaillePage = iLimite
clRes.Total = HNbEnreg(REQ_OperationsCount)

POUR TOUT REQ_Operations
    Ajoute(clRes.Items, OperationVersDTO(REQ_Operations))
FIN

RENVOYER clRes

// ---------------------------------------------------------------------------
// Operations_RechercherSemantique  (nouveauté 2026)
// Recherche les opérations dont le libellé est sémantiquement proche.
// ---------------------------------------------------------------------------
PROCÉDURE Operations_RechercherSemantique(sRequete EST UNE CHAÎNE,
                                          idPeriode EST UNE CHAÎNE,
                                          iTop EST UN ENTIER = 20) : TABLEAU

clUser EST UN ClasseUtilisateur = RecupererUtilisateurConnecte()

// Recherche sémantique HFSQL 2026
tabResultats EST UN TABLEAU = RechercheSémantique(
    Operation,                      // table
    "Libelle",                       // colonne indexée sémantique
    sRequete,                        // requête utilisateur
    iTop,                            // top N
    "IDPeriode = '" + idPeriode + "'"  // filtre additionnel
)

RENVOYER tabResultats

// ---------------------------------------------------------------------------
// Helpers privés
// ---------------------------------------------------------------------------
PROCÉDURE PRIVÉE ValiderModification(idOperation EST UNE CHAÎNE) : ClasseResultat

clRes EST UN ClasseResultat
clRes.Succes = Faux

HRAZ(Operation)
SI PAS HLitRecherchePremier(Operation, IDOperation, idOperation) ALORS
    clRes.Message = "Opération introuvable"
    RENVOYER clRes
FIN

clPeriode EST UN ClassePeriode = Periodes_Recuperer(Operation.IDPeriode)
SI clPeriode.Statut <> "Ouvert" ALORS
    clRes.Message = "Période fermée — modification impossible"
    RENVOYER clRes
FIN

clRes.Succes = Vrai
RENVOYER clRes
