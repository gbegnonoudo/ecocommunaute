# PAGE_Login — Authentification

## Rôle

Page d'entrée publique de l'application. Authentifie l'utilisateur via le **OAuth Server WEBDEV 2026** intégré et redirige vers le tableau de bord adapté au profil.

## URL

`/` (page d'accueil non authentifiée)

## Champs

| Nom | Type | Validation |
|---|---|---|
| `SAI_Login` | Saisie texte | Obligatoire, max 50 car, lowercase |
| `SAI_MotDePasse` | Saisie mot de passe (avec bouton "voir") | Obligatoire, min 12 car |
| `CHK_SeSouvenir` | Case à cocher | Optionnel |
| `LIEN_MotDePasseOublie` | Lien | → `/forgot-password` |
| `BTN_Connecter` | Bouton primaire | Déclenche l'auth |
| `SAI_Code2FA` | Saisie texte (affichée après step 1) | 6 chiffres si 2FA actif |

## Style

- Centré, max-width 420px, padding 32px
- Logo EcoCommunauté en haut
- Palette de couleurs du projet (nouveauté 2026 — utiliser la palette définie)
- Responsive : occupe 100 % en mobile

## Code WEBDEV (événements de la page)

### Clic sur BTN_Connecter

```wl
// PAGE_Login : Clic sur BTN_Connecter
PROCÉDURE BTN_Connecter_OnClick()

sLogin EST UNE CHAÎNE = SAI_Login..Valeur
sMotDePasse EST UNE CHAÎNE = SAI_MotDePasse..Valeur

// Validation client (côté navigateur)
SI sLogin = "" OU sMotDePasse = "" ALORS
    ToastAffiche("Login et mot de passe obligatoires", ToastCourt, vaCentre, hbBas)
    RETOUR
FIN

// Appel du webservice OAuth WEBDEV (nouveauté 2026)
clRésultat EST UN ClasseLoginRésultat = AuthentifierUtilisateur(sLogin, sMotDePasse)

SELON clRésultat.Statut
    CAS "OK"
        StockerToken(clRésultat.AccessToken, clRésultat.RefreshToken)
        PageAffiche(PageRedirectionParProfil(clRésultat.Profil))

    CAS "2FA_REQUIS"
        SAI_Code2FA..Visible = Vrai
        SAI_Code2FA..PriseFocus = Vrai
        gIDSession2FA = clRésultat.IDSession2FA

    CAS "ECHEC"
        ToastAffiche("Identifiants invalides", ToastLong, vaCentre, hbBas)
        AuditLog("LOGIN_FAIL", sLogin)

    CAS "BLOQUE"
        ToastAffiche("Compte bloqué — contactez l'administrateur", ToastLong, vaCentre, hbBas)
FIN
```

### Clic sur BTN_Connecter avec 2FA

```wl
SI SAI_Code2FA..Visible ET SAI_Code2FA..Valeur <> "" ALORS
    clRésultat = ValiderCode2FA(gIDSession2FA, SAI_Code2FA..Valeur)
    SI clRésultat.Statut = "OK" ALORS
        StockerToken(clRésultat.AccessToken, clRésultat.RefreshToken)
        PageAffiche(PageRedirectionParProfil(clRésultat.Profil))
    SINON
        ToastAffiche("Code invalide ou expiré", ToastLong)
    FIN
FIN
```

## Sécurité (bonnes pratiques 2026)

- **CSP active** au niveau projet — aucun script inline autorisé
- Cookie `access_token` en `HttpOnly`, `Secure`, `SameSite=Strict`
- Throttling : max 5 tentatives / 15 min par IP côté serveur
- Log d'audit obligatoire sur succès **et** échec
- Pas de message distinguant "login inconnu" vs "mot de passe faux" (anti-énumération)

## Tests automatisés à créer

1. Login OK avec profil COMMUNAUTAIRE → redirige vers `/dashboard`
2. Login OK avec profil PROVINCIAL → redirige vers `/provincial`
3. Login OK avec profil ADMIN → redirige vers `/admin`
4. Login échec → message générique
5. Compte avec 2FA actif → étape 2FA s'affiche
6. 6 tentatives échouées → throttling actif (HTTP 429)
