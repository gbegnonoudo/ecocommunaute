PROCÉDURE InitialiserUtilisateurConnecte() : booléen

// =====================================================================
// Réinitialiser le contexte utilisateur
// =====================================================================

gnIDUtilisateur = 0
gsLoginUtilisateur = ""
gsNomUtilisateur = ""
gsPrenomUtilisateur = ""
gsGroupeUtilisateur = ""
gnIDCommunauteUtilisateur = 0

// =====================================================================
// Lire les informations Groupware
// =====================================================================

gsLoginUtilisateur = gpwUtilisateur

SI gsLoginUtilisateur = "" ALORS
	Info("Utilisateur non connecté.")
	RENVOYER Faux
FIN

// =====================================================================
// Rechercher l'utilisateur miroir
// =====================================================================

SI PAS HLitRecherchePremier(UTILISATEUR, LoginUtilisateur, gsLoginUtilisateur) ALORS
	Info("Utilisateur absent du fichier applicatif UTILISATEUR.")
	RENVOYER Faux
FIN

// =====================================================================
// Charger les informations utilisateur
// =====================================================================

gnIDUtilisateur = UTILISATEUR.IDUtilisateur
gsNomUtilisateur = UTILISATEUR.NomUtilisateur
gsPrenomUtilisateur = UTILISATEUR.PrenomUtilisateur
gsGroupeUtilisateur = UTILISATEUR.GroupeUtilisateurGPW
gnIDCommunauteUtilisateur = UTILISATEUR.IDCommunaute

SI UTILISATEUR.StatutUtilisateur <> "ACTIF" ALORS
	Info("Votre compte applicatif est désactivé.")
	RENVOYER Faux
FIN

RENVOYER Vrai
