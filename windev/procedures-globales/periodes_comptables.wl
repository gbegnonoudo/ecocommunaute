// =====================================================================
// PROCÉDURES GLOBALES — PÉRIODES COMPTABLES
// EcoCommunautés / WinDev 2025 / HFSQL
// =====================================================================

PROCÉDURE PeutModifierOperationPeriode(nIDPeriode est un entier sur 8 octets) : booléen

SI nIDPeriode <= 0 ALORS
	RENVOYER Faux
FIN

SI PAS HLitRecherchePremier(PERIODE_COMPTABLE, IDperiode, nIDPeriode) ALORS
	RENVOYER Faux
FIN

SI PERIODE_COMPTABLE.StatutPeriode = gcSTATUT_PERIODE_OUVERTE ALORS
	RENVOYER Vrai
FIN

SI PERIODE_COMPTABLE.StatutPeriode = gcSTATUT_PERIODE_A_CORRIGER ALORS
	RENVOYER Vrai
FIN

RENVOYER Faux


PROCÉDURE PeutSoumettrePeriode(nIDPeriode est un entier sur 8 octets) : booléen

SI gsGroupeUtilisateur <> gcGROUPE_COMMUNAUTAIRE ALORS
	RENVOYER Faux
FIN

SI PAS HLitRecherchePremier(PERIODE_COMPTABLE, IDperiode, nIDPeriode) ALORS
	RENVOYER Faux
FIN

SI PERIODE_COMPTABLE.IDcommunaute <> gnIDCommunauteUtilisateur ALORS
	RENVOYER Faux
FIN

SI PERIODE_COMPTABLE.StatutPeriode = gcSTATUT_PERIODE_OUVERTE OU PERIODE_COMPTABLE.StatutPeriode = gcSTATUT_PERIODE_A_CORRIGER ALORS
	RENVOYER Vrai
FIN

RENVOYER Faux


PROCÉDURE PeutValiderProvince(nIDPeriode est un entier sur 8 octets) : booléen

SI gsGroupeUtilisateur <> gcGROUPE_ADMIN ET gsGroupeUtilisateur <> gcGROUPE_PROVINCIAL ALORS
	RENVOYER Faux
FIN

SI PAS HLitRecherchePremier(PERIODE_COMPTABLE, IDperiode, nIDPeriode) ALORS
	RENVOYER Faux
FIN

SI PERIODE_COMPTABLE.StatutPeriode = gcSTATUT_PERIODE_SOUMISE ALORS
	RENVOYER Vrai
FIN

RENVOYER Faux


PROCÉDURE PeutCloturerPeriode(nIDPeriode est un entier sur 8 octets) : booléen

SI gsGroupeUtilisateur <> gcGROUPE_ADMIN ET gsGroupeUtilisateur <> gcGROUPE_PROVINCIAL ALORS
	RENVOYER Faux
FIN

SI PAS HLitRecherchePremier(PERIODE_COMPTABLE, IDperiode, nIDPeriode) ALORS
	RENVOYER Faux
FIN

SI PERIODE_COMPTABLE.StatutPeriode = gcSTATUT_PERIODE_VALIDEE_PROVINCE ALORS
	RENVOYER Vrai
FIN

RENVOYER Faux


PROCÉDURE SoumettrePeriodeCommunaute(nIDPeriode est un entier sur 8 octets, sObservation est une chaîne = "") : booléen

SI PAS PeutSoumettrePeriode(nIDPeriode) ALORS
	Info("Cette période ne peut pas être soumise.")
	RENVOYER Faux
FIN

SI PAS ControlerPeriodeAvantSoumission(nIDPeriode) ALORS
	Info("La période contient encore des anomalies. Corrigez-les avant la soumission.")
	RENVOYER Faux
FIN

PERIODE_COMPTABLE.StatutPeriode = gcSTATUT_PERIODE_SOUMISE
PERIODE_COMPTABLE.DateSoumissionCommunaute = DateHeureSys()
PERIODE_COMPTABLE.IDUtilisateurSoumissionCommunaute = gnIDUtilisateur
PERIODE_COMPTABLE.ObservationSoumissionCommunaute = sObservation

SI PAS HModifie(PERIODE_COMPTABLE) ALORS
	Erreur("Impossible de soumettre la période." + RC + HErreurInfo())
	RENVOYER Faux
FIN

RENVOYER Vrai


PROCÉDURE RetournerPeriodeCorrection(nIDPeriode est un entier sur 8 octets, sObservation est une chaîne = "") : booléen

SI PAS PeutValiderProvince(nIDPeriode) ALORS
	Info("Cette période ne peut pas être retournée en correction.")
	RENVOYER Faux
FIN

PERIODE_COMPTABLE.StatutPeriode = gcSTATUT_PERIODE_A_CORRIGER
PERIODE_COMPTABLE.DateValidationProvince = DateHeureSys()
PERIODE_COMPTABLE.IDUtilisateurValidationProvince = gnIDUtilisateur
PERIODE_COMPTABLE.ObservationValidationProvince = sObservation

SI PAS HModifie(PERIODE_COMPTABLE) ALORS
	Erreur("Impossible de retourner la période en correction." + RC + HErreurInfo())
	RENVOYER Faux
FIN

RENVOYER Vrai


PROCÉDURE ValiderPeriodeProvince(nIDPeriode est un entier sur 8 octets, sObservation est une chaîne = "") : booléen

SI PAS PeutValiderProvince(nIDPeriode) ALORS
	Info("Cette période ne peut pas être validée par la Province.")
	RENVOYER Faux
FIN

PERIODE_COMPTABLE.StatutPeriode = gcSTATUT_PERIODE_VALIDEE_PROVINCE
PERIODE_COMPTABLE.DateValidationProvince = DateHeureSys()
PERIODE_COMPTABLE.IDUtilisateurValidationProvince = gnIDUtilisateur
PERIODE_COMPTABLE.ObservationValidationProvince = sObservation

SI PAS HModifie(PERIODE_COMPTABLE) ALORS
	Erreur("Impossible de valider la période." + RC + HErreurInfo())
	RENVOYER Faux
FIN

RENVOYER Vrai


PROCÉDURE CloturerPeriode(nIDPeriode est un entier sur 8 octets, sObservation est une chaîne = "") : booléen

SI PAS PeutCloturerPeriode(nIDPeriode) ALORS
	Info("Cette période ne peut pas être clôturée.")
	RENVOYER Faux
FIN

PERIODE_COMPTABLE.StatutPeriode = gcSTATUT_PERIODE_CLOTUREE
PERIODE_COMPTABLE.DateCloturePeriode = DateHeureSys()
PERIODE_COMPTABLE.IDUtilisateurCloturePeriode = gnIDUtilisateur
PERIODE_COMPTABLE.ObservationCloturePeriode = sObservation

SI PAS HModifie(PERIODE_COMPTABLE) ALORS
	Erreur("Impossible de clôturer la période." + RC + HErreurInfo())
	RENVOYER Faux
FIN

RENVOYER Vrai


PROCÉDURE ControlerPeriodeAvantSoumission(nIDPeriode est un entier sur 8 octets) : booléen

// Contrôle simple et volontairement clair :
// - La période existe.
// - Toutes les opérations de la période sont équilibrées.
// - Les comptes utilisés sont saisissables et actifs.

SI nIDPeriode <= 0 ALORS
	RENVOYER Faux
FIN

SI PAS HLitRecherchePremier(PERIODE_COMPTABLE, IDperiode, nIDPeriode) ALORS
	RENVOYER Faux
FIN

SI PAS ControlerOperationsEquilibreesPeriode(nIDPeriode) ALORS
	RENVOYER Faux
FIN

SI PAS ControlerComptesOperationsPeriode(nIDPeriode) ALORS
	RENVOYER Faux
FIN

RENVOYER Vrai


PROCÉDURE ControlerOperationsEquilibreesPeriode(nIDPeriode est un entier sur 8 octets) : booléen

nIDOperation est un entier sur 8 octets
mDebit est un monétaire
mCredit est un monétaire

POUR TOUT operation AVEC IDperiode = nIDPeriode
	nIDOperation = operation.IDoperation
	mDebit = 0
	mCredit = 0
	POUR TOUT ligne_operation AVEC IDoperation = nIDOperation
		mDebit += ligne_operation.MontantDebitDevise
		mCredit += ligne_operation.MontantCreditDevise
	FIN
	SI mDebit <> mCredit ALORS
		RENVOYER Faux
	FIN
FIN

RENVOYER Vrai


PROCÉDURE ControlerComptesOperationsPeriode(nIDPeriode est un entier sur 8 octets) : booléen

POUR TOUT operation AVEC IDperiode = nIDPeriode
	POUR TOUT ligne_operation AVEC IDoperation = operation.IDoperation
		SI PAS HLitRecherchePremier(plan_compte, IDplan_compte, ligne_operation.IDplan_compte) ALORS
			RENVOYER Faux
		FIN
		SI plan_compte.EstSaisissableCompte = Faux ALORS
			RENVOYER Faux
		FIN
		SI plan_compte.StatutCompte <> "ACTIF" ALORS
			RENVOYER Faux
		FIN
	FIN
FIN

RENVOYER Vrai
