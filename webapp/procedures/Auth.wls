// ===========================================================================
// Auth.wls — Procédures d'authentification et d'autorisation
// EcoCommunauté Web (WEBDEV 2026)
//
// Utilise :
//   - OAuth Server WEBDEV intégré (nouveauté 2026)
//   - Groupware Utilisateur WEBDEV (BaaS mode)
//   - Famille de fonctions wdbaas (nouveauté 2026)
// ===========================================================================

// ---------------------------------------------------------------------------
// AuthentifierUtilisateur
// Authentifie un utilisateur via login/mot de passe.
// Retourne un objet contenant les tokens OAuth ou une erreur typée.
// ---------------------------------------------------------------------------
PROCÉDURE AuthentifierUtilisateur(sLogin EST UNE CHAÎNE, sMotDePasse EST UNE CHAÎNE) : ClasseLoginResultat

clRes EST UN ClasseLoginResultat
clRes.Statut = "ECHEC"

// Throttling — vérifier les tentatives récentes
SI EstThrottle(sLogin) ALORS
    clRes.Statut = "BLOQUE"
    clRes.Message = "Trop de tentatives — réessayez dans 15 minutes"
    AuditLog("LOGIN_BLOCKED_THROTTLE", sLogin)
    RENVOYER clRes
FIN

// Appel au OAuth Server WEBDEV intégré
vTokenRes EST UN VARIANT = wdbaasObtientToken(sLogin, sMotDePasse, "communaute_scope")

SI vTokenRes.error <> "" ALORS
    EnregistrerTentativeEchouee(sLogin)
    AuditLog("LOGIN_FAIL", sLogin)
    RENVOYER clRes  // Statut = ECHEC
FIN

// Récupère le profil de l'utilisateur
vUserInfo EST UN VARIANT = wdbaasInformationsUtilisateur(vTokenRes.access_token)

clUser EST UN ClasseUtilisateur
clUser.IDUtilisateur = vUserInfo.sub
clUser.Login = vUserInfo.preferred_username
clUser.Profil = vUserInfo.profil
clUser.IDCommunaute = vUserInfo.id_communaute
clUser.DoubleAuth = vUserInfo.double_auth

// Vérifie si compte bloqué
SI vUserInfo.bloque ALORS
    clRes.Statut = "BLOQUE"
    RENVOYER clRes
FIN

// 2FA requis ?
SI clUser.DoubleAuth ALORS
    clRes.Statut = "2FA_REQUIS"
    clRes.IDSession2FA = CreerSession2FA(clUser.IDUtilisateur)
    EnvoyerCode2FA(clUser.IDUtilisateur)
    RENVOYER clRes
FIN

// Login OK direct
clRes.Statut = "OK"
clRes.AccessToken = vTokenRes.access_token
clRes.RefreshToken = vTokenRes.refresh_token
clRes.Profil = clUser.Profil
AuditLog("LOGIN_OK", sLogin)
RENVOYER clRes

// ---------------------------------------------------------------------------
// ValiderCode2FA
// Vérifie le code TOTP saisi par l'utilisateur après le step 1.
// ---------------------------------------------------------------------------
PROCÉDURE ValiderCode2FA(idSession EST UNE CHAÎNE, sCode EST UNE CHAÎNE) : ClasseLoginResultat

clRes EST UN ClasseLoginResultat
clRes.Statut = "ECHEC"

// Récupère la session 2FA
HRAZ(Session2FA)
HLitRecherchePremier(Session2FA, IDSession, idSession)

SI PAS HTrouve(Session2FA) ALORS
    clRes.Message = "Session expirée"
    RENVOYER clRes
FIN

// Vérifie expiration (5 min max)
SI Session2FA.DateCreation + 300 < HeureSys() ALORS
    HSupprime(Session2FA)
    clRes.Message = "Code expiré"
    RENVOYER clRes
FIN

// Validation TOTP
SI PAS VerifierTOTP(Session2FA.IDUtilisateur, sCode) ALORS
    Session2FA.NbEssais ++
    SI Session2FA.NbEssais >= 3 ALORS
        HSupprime(Session2FA)
        clRes.Message = "Trop de tentatives — recommencez la connexion"
    SINON
        HModifie(Session2FA)
        clRes.Message = "Code invalide"
    FIN
    RENVOYER clRes
FIN

// Code OK — émet le token
vTokenRes EST UN VARIANT = wdbaasEmetToken(Session2FA.IDUtilisateur, "2fa_validated")

vUserInfo EST UN VARIANT = wdbaasInformationsUtilisateur(vTokenRes.access_token)

clRes.Statut = "OK"
clRes.AccessToken = vTokenRes.access_token
clRes.RefreshToken = vTokenRes.refresh_token
clRes.Profil = vUserInfo.profil

HSupprime(Session2FA)
AuditLog("LOGIN_2FA_OK", vUserInfo.preferred_username)
RENVOYER clRes

// ---------------------------------------------------------------------------
// VerifierScope
// Lève une erreur HTTP 403 si l'utilisateur connecté n'a pas le scope requis.
// À appeler en début de chaque procédure sensible côté serveur.
// ---------------------------------------------------------------------------
PROCÉDURE VerifierScope(sScopeRequis EST UNE CHAÎNE)

sToken EST UNE CHAÎNE = HTTPRéponseEntêteLit("Authorization")
sToken = Remplace(sToken, "Bearer ", "")

vUserInfo EST UN VARIANT = wdbaasInformationsUtilisateur(sToken)

SI vUserInfo.error <> "" ALORS
    HTTPRéponse(401, "Token invalide")
    PoursuivreActionAnnule()
    RETOUR
FIN

// Vérifie le scope
tabScopes EST UN TABLEAU = ChaîneVersTableau(vUserInfo.scopes, ",")
SI PAS TableauContient(tabScopes, sScopeRequis) ALORS  // nouveauté 2026
    HTTPRéponse(403, "Accès refusé")
    AuditLog("ACCESS_DENIED", vUserInfo.preferred_username,
        ChaîneConstruit("Scope %1 requis", sScopeRequis))
    PoursuivreActionAnnule()
    RETOUR
FIN

// Stocke l'utilisateur courant pour la procédure appelante
gUtilisateurCourant = vUserInfo

// ---------------------------------------------------------------------------
// RecupererUtilisateurConnecte
// Renvoie l'utilisateur connecté (depuis le token JWT en cours).
// ---------------------------------------------------------------------------
PROCÉDURE RecupererUtilisateurConnecte() : ClasseUtilisateur

SI gUtilisateurCourant = Null ALORS
    sToken EST UNE CHAÎNE = HTTPRéponseEntêteLit("Authorization")
    sToken = Remplace(sToken, "Bearer ", "")
    gUtilisateurCourant = wdbaasInformationsUtilisateur(sToken)
FIN

clUser EST UN ClasseUtilisateur
clUser.IDUtilisateur = gUtilisateurCourant.sub
clUser.Login = gUtilisateurCourant.preferred_username
clUser.Profil = gUtilisateurCourant.profil
clUser.IDCommunaute = gUtilisateurCourant.id_communaute
clUser.Province = gUtilisateurCourant.province

RENVOYER clUser

// ---------------------------------------------------------------------------
// Deconnecter
// Révoque le token courant.
// ---------------------------------------------------------------------------
PROCÉDURE Deconnecter()

sToken EST UNE CHAÎNE = HTTPRéponseEntêteLit("Authorization")
sToken = Remplace(sToken, "Bearer ", "")

wdbaasRevoqueToken(sToken)

clUser EST UN ClasseUtilisateur = RecupererUtilisateurConnecte()
AuditLog("LOGOUT", clUser.Login)

// ---------------------------------------------------------------------------
// AuditLog
// Trace une action dans la table AUDIT_LOG.
// Toujours appeler pour les actions de sécurité.
// ---------------------------------------------------------------------------
PROCÉDURE AuditLog(sAction EST UNE CHAÎNE, sCible EST UNE CHAÎNE,
                    sDetails EST UNE CHAÎNE = "")

HRAZ(AuditLog)
AuditLog.IDLog = GenererUUID()
AuditLog.Horodatage = MaintenantSys()
AuditLog.Action = sAction
AuditLog.IDUtilisateur = SI gUtilisateurCourant <> Null ALORS gUtilisateurCourant.sub SINON ""
AuditLog.Cible = sCible
AuditLog.Details = sDetails
AuditLog.IPSource = HTTPRéponseEntêteLit("X-Forwarded-For")
AuditLog.UserAgent = HTTPRéponseEntêteLit("User-Agent")

HAjoute(AuditLog)

// ---------------------------------------------------------------------------
// EstThrottle
// Vérifie si l'utilisateur a dépassé 5 tentatives en 15 min.
// ---------------------------------------------------------------------------
PROCÉDURE EstThrottle(sLogin EST UNE CHAÎNE) : BOOLÉEN

iNbEchec EST UN ENTIER = HNbEnreg(TentativeLogin,
    "Login = '" + sLogin + "' AND DateTentative > '" +
    DateHeureVersChaîne(MaintenantSys() - 900) + "' AND Succes = Faux")

RENVOYER (iNbEchec >= 5)
