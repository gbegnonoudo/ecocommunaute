// =====================================================================
// PROCÉDURES GLOBALES — OPÉRATIONS
// EcoCommunautés / WinDev 2025 / HFSQL
// =====================================================================

PROCÉDURE ControlerOperationEquilibree(nIDOperation est un entier sur 8 octets) : booléen

mDebit est un monétaire = 0
mCredit est un monétaire = 0

SI nIDOperation <= 0 ALORS
	RENVOYER Faux
FIN

POUR TOUT ligne_operation AVEC IDoperation = nIDOperation
	mDebit += ligne_operation.MontantDebitDevise
	mCredit += ligne_operation.MontantCreditDevise
FIN

SI mDebit <> mCredit ALORS
	RENVOYER Faux
FIN

RENVOYER Vrai


PROCÉDURE ControlerCompteSaisieOperation(nIDPlanCompte est un entier sur 8 octets) : booléen

SI nIDPlanCompte <= 0 ALORS
	RENVOYER Faux
FIN

SI PAS HLitRecherchePremier(plan_compte, IDplan_compte, nIDPlanCompte) ALORS
	RENVOYER Faux
FIN

SI plan_compte.EstSaisissableCompte = Faux ALORS
	RENVOYER Faux
FIN

SI plan_compte.StatutCompte <> "ACTIF" ALORS
	RENVOYER Faux
FIN

RENVOYER Vrai


PROCÉDURE PeutModifierOperation(nIDOperation est un entier sur 8 octets) : booléen

SI nIDOperation <= 0 ALORS
	RENVOYER Faux
FIN

SI PAS HLitRecherchePremier(operation, IDoperation, nIDOperation) ALORS
	RENVOYER Faux
FIN

RENVOYER PeutModifierOperationPeriode(operation.IDperiode)


PROCÉDURE AnnulerOperation(nIDOperation est un entier sur 8 octets, sObservation est une chaîne = "") : booléen

SI PAS PeutModifierOperation(nIDOperation) ALORS
	Info("Cette opération ne peut pas être annulée car la période n'est plus modifiable.")
	RENVOYER Faux
FIN

operation.StatutOperation = "ANNULEE"
operation.ObservationOperation = sObservation

SI PAS HModifie(operation) ALORS
	Erreur("Impossible d'annuler l'opération." + RC + HErreurInfo())
	RENVOYER Faux
FIN

RENVOYER Vrai


PROCÉDURE ControlerLignesOperationTable() : booléen

// Cette procédure sert de modèle pour une table mémoire de fenêtre.
// Adapter le nom des colonnes selon la table réelle TABLE_LignesSaisie.

mDebit est un monétaire = 0
mCredit est un monétaire = 0
nLigne est un entier

POUR nLigne = 1 _À_ TableOccurrence(TABLE_LignesSaisie)
	mDebit += TABLE_LignesSaisie[nLigne].COL_Debit
	mCredit += TABLE_LignesSaisie[nLigne].COL_Credit
FIN

SI mDebit <> mCredit ALORS
	Info("L'opération n'est pas équilibrée. Le total débit doit être égal au total crédit.")
	RENVOYER Faux
FIN

RENVOYER Vrai
