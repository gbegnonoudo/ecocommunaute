// =====================================================================
// PROCÉDURES GLOBALES — COMPTES DE TRÉSORERIE
// =====================================================================

PROCÉDURE ControlerCompteTresorerie(nIDCompteTresorerie est un entier sur 8 octets) : booléen

SI nIDCompteTresorerie <= 0 ALORS
	RENVOYER Faux
FIN

SI PAS HLitRecherchePremier(compte_tresorerie, IDcompte_tresorerie, nIDCompteTresorerie) ALORS
	RENVOYER Faux
FIN

SI compte_tresorerie.StatutCompteTresorerie <> "ACTIF" ALORS
	RENVOYER Faux
FIN

SI compte_tresorerie.IDplan_compte <= 0 ALORS
	RENVOYER Faux
FIN

RENVOYER Vrai


PROCÉDURE CalculerSoldeCompteTresorerie(nIDCompteTresorerie est un entier sur 8 octets, nIDPeriode est un entier sur 8 octets) : monétaire

mSolde est un monétaire = 0

SI PAS HLitRecherchePremier(compte_tresorerie, IDcompte_tresorerie, nIDCompteTresorerie) ALORS
	RENVOYER 0
FIN

mSolde = compte_tresorerie.SoldeInitialCompteTresorerie

POUR TOUT ligne_operation AVEC IDcompte_tresorerie = nIDCompteTresorerie
	SI nIDPeriode > 0 ET ligne_operation.IDperiode <> nIDPeriode ALORS
		CONTINUER
	FIN
	mSolde += ligne_operation.MontantDebitDevise
	mSolde -= ligne_operation.MontantCreditDevise
FIN

RENVOYER mSolde


PROCÉDURE AlerterSoldeCompteTresorerie(nIDCompteTresorerie est un entier sur 8 octets, nIDPeriode est un entier sur 8 octets)

mSolde est un monétaire
mSolde = CalculerSoldeCompteTresorerie(nIDCompteTresorerie, nIDPeriode)

SI mSolde = 0 ALORS
	Info("Attention : le solde de ce compte de trésorerie est nul.")
	RETOUR
FIN

SI mSolde < 0 ALORS
	Info("Attention : le solde de ce compte de trésorerie est négatif.")
	RETOUR
FIN
