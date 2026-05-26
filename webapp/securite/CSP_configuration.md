# Configuration CSP — EcoCommunauté Web

> **Nouveauté WEBDEV 2026** (665) : activation native d'une **Content Security Policy** au niveau projet pour bloquer les attaques XSS.

---

## Pourquoi la CSP ?

La CSP (Content Security Policy) est une directive HTML5 qui indique au navigateur quelles sources sont autorisées pour le chargement et l'exécution des ressources (scripts, images, polices, frames…).

Sans CSP, un attaquant qui parvient à injecter un `<script>` dans une page peut :
- Voler les tokens d'authentification
- Faire des actions au nom de l'utilisateur
- Exfiltrer des données comptables

Avec CSP correctement configurée :
- Les scripts inline sont bloqués
- Seules les sources whitelistées peuvent charger du code
- Toute tentative d'injection est rejetée par le navigateur

---

## Activation dans WEBDEV 2026

### Via l'interface

```
Projet → Description → Onglet "Avancé" → "Activer CSP automatique"
```

L'IDE génère alors la balise `<meta http-equiv="Content-Security-Policy">` dans toutes les pages.

### Configuration recommandée pour EcoCommunauté

Édition manuelle pour finetuner (Onglet "Sécurité" → CSP) :

```http
Content-Security-Policy:
  default-src 'self';
  script-src 'self' 'nonce-{NONCE_DYNAMIQUE}';
  style-src 'self' 'unsafe-inline';
  img-src 'self' data: https://tile.openstreetmap.org;
  font-src 'self' data:;
  connect-src 'self' https://api.bceao.int wss://ecocommunaute.org;
  frame-src 'none';
  object-src 'none';
  base-uri 'self';
  form-action 'self';
  upgrade-insecure-requests;
  report-uri /api/csp-report
```

---

## Directives expliquées

| Directive | Valeur | Justification |
|---|---|---|
| `default-src 'self'` | Tout doit venir du domaine de l'app par défaut | Principe de sécurité par défaut |
| `script-src 'self' 'nonce-...'` | Scripts uniquement depuis l'app + nonce unique par page | Bloque l'injection JS, le nonce empêche le rejeu |
| `style-src 'self' 'unsafe-inline'` | CSS depuis l'app + inline (généré par WEBDEV) | WEBDEV génère des styles inline, requis |
| `img-src 'self' data: tile.openstreetmap.org` | Images de l'app + base64 + tuiles OSM | OSM est la nouvelle carto 2026 |
| `font-src 'self' data:` | Polices uniquement de l'app | Pas de Google Fonts (RGPD) |
| `connect-src 'self' api.bceao.int wss://...` | XHR/WebSocket vers l'app + API taux + WebSocket | Pour les taux de change officiels et les subscriptions GraphQL |
| `frame-src 'none'` | Pas d'iframes | Bloque le clickjacking |
| `object-src 'none'` | Pas de `<object>`, `<embed>` | Bloque les vieux plugins |
| `base-uri 'self'` | Pas de balise `<base>` modifiée | Bloque le détournement de chemins |
| `form-action 'self'` | Les forms POST uniquement vers l'app | Bloque l'exfiltration via form |
| `upgrade-insecure-requests` | Force le HTTPS | Pas de mixed content |
| `report-uri /api/csp-report` | Envoie les violations à un endpoint | Permet de monitorer les attaques |

---

## Code WLangage — Endpoint de reporting CSP

```wl
// webservices/REST_SecurityAPI.wws

PROCÉDURE WebService POST_CSPReport(bufCorps EST UN BUFFER)

// Le navigateur envoie un JSON avec les détails de la violation
vRapport EST UN VARIANT = JSONVersVariant(BufferVersChaîne(bufCorps))

HRAZ(CSPViolation)
CSPViolation.IDViolation = GenererUUID()
CSPViolation.Horodatage = MaintenantSys()
CSPViolation.URI = vRapport."csp-report"."document-uri"
CSPViolation.Directive = vRapport."csp-report"."violated-directive"
CSPViolation.SourceBloquee = vRapport."csp-report"."blocked-uri"
CSPViolation.IPSource = HTTPRéponseEntêteLit("X-Forwarded-For")
CSPViolation.UserAgent = HTTPRéponseEntêteLit("User-Agent")
HAjoute(CSPViolation)

// Alerte si plus de N violations en 5 min
SI HNbEnreg(CSPViolation,
    "Horodatage > '" + DateHeureVersChaîne(MaintenantSys() - 300) + "'") > 10 ALORS
    EnvoyerAlerteSecurite("Pic de violations CSP détecté")
FIN

HTTPRéponse(204)  // No content
```

---

## Procédure de déploiement

1. **Phase 1 — Audit** : déployer avec `Content-Security-Policy-Report-Only` pour collecter les violations sans bloquer
2. **Phase 2 — Ajustement** : ajuster les directives selon les violations légitimes
3. **Phase 3 — Application** : passer en `Content-Security-Policy` (bloquant)
4. **Phase 4 — Monitoring** : continuer à surveiller les rapports

---

## Tests à effectuer

| Test | Résultat attendu |
|---|---|
| Injecter `<script>alert(1)</script>` dans un champ libellé | Bloqué + violation reportée |
| Tenter de charger une image depuis evil.com | Bloquée |
| Tenter d'utiliser `eval()` dans la console | Bloqué (no `'unsafe-eval'`) |
| Form qui submit vers external.com | Bloqué (form-action 'self') |
| Iframe avec source externe | Bloqué |
| HTTP au lieu de HTTPS | Upgrade auto vers HTTPS |

---

## Outils de test

- **Mozilla Observatory** : `https://observatory.mozilla.org` — note A+ attendue
- **CSP Evaluator (Google)** : valide la syntaxe et détecte les faiblesses
- **DevTools navigateur** : onglet Console affiche les violations en développement
