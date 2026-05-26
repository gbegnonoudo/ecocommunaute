// =====================================================================
// PROCÉDURES GLOBALES — EXPORTS EXCEL
// =====================================================================

PROCÉDURE ExporterRapportExcel(nIDRapport est un entier sur 8 octets, sCheminModele est une chaîne, sCheminSortie est une chaîne) : booléen

// Cette procédure est un squelette stable.
// L'export réel sera connecté au champ Tableur WinDev 2025.

SI nIDRapport <= 0 ALORS
	RENVOYER Faux
FIN

SI PAS HLitRecherchePremier(rapport, IDrapport, nIDRapport) ALORS
	RENVOYER Faux
FIN

SI sCheminModele = "" OU sCheminSortie = "" ALORS
	Info("Le modèle Excel ou le fichier de sortie est manquant.")
	RENVOYER Faux
FIN

// Étapes prévues :
// 1. Charger le modèle dans un champ Tableur.
// 2. Lire mapping_rapport_excel.
// 3. Lire ligne_rapport.
// 4. Écrire les montants dans les cellules prévues.
// 5. Sauvegarder le fichier final.

RENVOYER Vrai
