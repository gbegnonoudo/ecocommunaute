// =====================================================================
// PROCÉDURES GLOBALES — RESSOURCES
// =====================================================================

PROCÉDURE LierRessourceAOperation(nIDRessource est un entier sur 8 octets, nIDOperation est un entier sur 8 octets) : booléen

SI nIDRessource <= 0 OU nIDOperation <= 0 ALORS
	RENVOYER Faux
FIN

SI PAS HLitRecherchePremier(ressource, IDressource, nIDRessource) ALORS
	RENVOYER Faux
FIN

SI PAS HLitRecherchePremier(operation, IDoperation, nIDOperation) ALORS
	RENVOYER Faux
FIN

ressource.IDoperation = nIDOperation

SI PAS HModifie(ressource) ALORS
	Erreur("Impossible de lier la ressource à l'opération." + RC + HErreurInfo())
	RENVOYER Faux
FIN

RENVOYER Vrai


PROCÉDURE PeutModifierRessourceOperation(nIDOperation est un entier sur 8 octets) : booléen

RENVOYER PeutModifierOperation(nIDOperation)
