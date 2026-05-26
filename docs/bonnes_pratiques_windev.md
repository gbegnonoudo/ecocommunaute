# Bonnes pratiques WinDev 2025

Guide synthétique extrait du manuel officiel **WinDev 2025** (PC SOFT), adapté au contexte du projet EcoCommunauté.

---

## 1. Architecture du code

### 1.1 Séparer les couches (3-Tier / MVP)

WinDev 2025 supporte nativement les architectures 3-Tier, SOA, MVP et Microservices. Appliquer cette séparation dès le début du projet évite la dette technique.

- **Couche Présentation** : uniquement le code d'affichage et d'interaction dans les fenêtres
- **Couche Métier** : procédures globales organisées par domaine fonctionnel (ex : `Section04_Exercices_Periodes.wdg`)
- **Couche Données** : accès HFSQL centralisé, jamais de `HLit*` directement dans le code d'une fenêtre

L'éditeur de code de WinDev 2025 **identifie automatiquement** le code Métier, le code UI et le code Mixte pour aider à la séparation.

```wl
// ✅ BON : la fenêtre appelle une procédure métier
ValiderPeriode(gIDPeriode)

// ❌ MAUVAIS : accès direct à HFSQL dans le code fenêtre
Periode.Statut = "Validé"
Periode.Modifie()
```

### 1.2 Utiliser les composants pour réutiliser le code

Un composant encapsule du code, des fenêtres, des tables et des procédures. Il peut être partagé entre plusieurs applications (WINDEV, WEBDEV, WINDEVMobile).

- Créer un composant = 1 clic dans l'éditeur
- Le code source est **obfusqué** (protégé)
- Un composant testé garantit la qualité de toutes les applications qui l'utilisent

### 1.3 Utiliser les modèles de fenêtres (héritage UI)

Définir une fenêtre modèle pour les éléments communs (bandeau, boutons standards, pied de page). Toutes les fenêtres héritent automatiquement des modifications du modèle.

- Modifier le modèle = modification propagée à toutes les fenêtres
- La **surcharge** permet d'adapter certains éléments sans rompre le lien avec le modèle
- Utiliser `Ctrl E` pour trouver et ouvrir n'importe quel élément partout dans le projet

### 1.4 Exploiter les patterns AAA (Architecture Automatique d'Application)

Créer un pattern AAA (template RAD personnalisé) garantit que tous les développeurs de l'équipe génèrent du code normalisé et conforme aux règles du projet.

---

## 2. Base de données HFSQL

### 2.1 Utiliser EcranVersFichier / FichierVersEcran

Ces ordres WLangage synchronisent automatiquement tous les champs d'une fenêtre avec la base de données, **sans risque d'oubli de colonne**.

```wl
// ✅ BON : synchronise TOUS les champs en une ligne
EcranVersFichier()
Operation.Ajoute()

// ❌ MAUVAIS : risque d'oublier un champ
Operation.Montant = SAI_Montant
Operation.DateOperation = SAI_Date
// ... (oubli possible d'autres colonnes)
Operation.Ajoute()
```

### 2.2 Toujours utiliser des requêtes paramétrées

Les requêtes paramétrées empêchent les attaques **SQL injection**, rendues impossibles côté serveur HFSQL.

```wl
// ✅ BON : requête paramétrée
REQ_ChercheOperation.ParamIDPeriode = gIDPeriode
HExécuteRequête(REQ_ChercheOperation)

// ❌ MAUVAIS : concaténation de chaîne
HExécuteRequêteSQL("SELECT * FROM Operation WHERE IDPeriode = '" + gIDPeriode + "'")
```

### 2.3 Ne jamais stocker les mots de passe en clair

Utiliser le type de rubrique **"Mot de passe"** de HFSQL : les mots de passe sont automatiquement **salés et hachés**. Même en cas de vol de la base, ils ne peuvent pas être reconstitués. Aucune programmation supplémentaire n'est nécessaire.

### 2.4 Chiffrer les tables sensibles

Activer le chiffrement **AES 256** sur les tables contenant des données financières ou personnelles.

```wl
// Connexion avec chiffrement AES 256
HOuvreConnexion("", "", "", "EcoCommunaute", hAccèsHFSQLCS, "AES256")
```

### 2.5 Gérer la synchronisation du schéma (SDD)

La technologie **SDD (Synchronisation Du schéma des Données)** de HFSQL met à jour automatiquement la structure des tables en production lors d'une nouvelle version. **Aucun script ALTER TABLE à écrire.**

### 2.6 Sauvegarder à chaud

Planifier des sauvegardes automatiques sans interruption de service via le Centre de Contrôle HFSQL.

```wl
// Déclenchement d'une sauvegarde par programmation
HSauvegardeBase("\\serveur\sauvegardes\", hSauvegardeComplète)
```

### 2.7 Gérer les accès concurrents

HFSQL gère automatiquement les conflits d'accès simultanés (une fenêtre s'affiche si 2 utilisateurs modifient la même ligne). Ne pas désactiver ce mécanisme.

---

## 3. Interface utilisateur (UI/UX)

### 3.1 Appliquer un gabarit (charte graphique)

Choisir un gabarit WinDev 2025 dès le début du projet. Tout champ ajouté hérite automatiquement du gabarit. Changer de gabarit = l'application entière change de look en 1 clic.

### 3.2 Utiliser les styles de champs

Définir des styles réutilisables pour chaque type de champ (saisie, libellé, table...). Ne pas modifier manuellement les attributs visuels de chaque champ individuellement.

### 3.3 Profiter des FAA (Fonctionnalités Automatiques de l'Application)

Les FAA sont activées par défaut et offrent gratuitement aux utilisateurs :
- Filtrage et tri des tables avec mémorisation
- Export Word/Excel/PDF depuis toute table
- Recherche dans les champs (Ctrl+F)
- Calculatrice sur les champs numériques
- Calendrier sur les champs date
- Notes repositionnables sur les fenêtres
- Correction orthographique

Ne désactiver une FAA que si elle est explicitement indésirable pour un champ précis.

### 3.4 Ancrer les champs pour l'adaptabilité

Utiliser les **ancrages** pour que les fenêtres s'adaptent automatiquement au redimensionnement et aux différentes résolutions d'écran.

---

## 4. Qualité du code

### 4.1 Lancer l'audit statique régulièrement

L'audit statique analyse le projet et produit un rapport sur :
- Le code mort (variables, fenêtres, messages inutilisés)
- Les dangers potentiels (éléments jamais réintégrés dans le GDS, modèles absents...)
- Les métriques de code (taux de commentaires, nombre de lignes par traitement)
- Les suggestions d'optimisation de performance

Lancer un audit avant chaque livraison.

### 4.2 Lancer l'audit dynamique en phase de test

L'audit dynamique surveille l'application **en cours d'exécution** et détecte :
- Fuites mémoire (requêtes non libérées)
- Images non trouvées
- Dépassements de capacité
- Utilisation de technologies obsolètes

Raccourci utilisateur en prod : `Ctrl + Alt + A` pour générer un rapport d'audit à distance.

### 4.3 Utiliser la programmation défensive

Les fonctions `dbgVérifie*` lèvent des erreurs explicites en mode test, sans impact en production.

```wl
dbgVérifieNonNull(gIDCommunaute, "IDCommunaute ne peut pas être null ici")
dbgVérifieEgalité(Période.Statut, "Ouvert", "La période doit être ouverte pour saisir")
```

### 4.4 Documenter le WHY, pas le WHAT

WinDev génère automatiquement un **dossier technique complet** (PDF, HTML) en 1 clic par rétro-analyse du projet. Inutile de commenter ce que le code fait ; commenter uniquement **pourquoi** un choix non évident a été fait.

### 4.5 Normaliser via les patterns de code

Utiliser l'outil **AAA (Architecture Automatique d'Application)** pour créer des patterns de génération RAD personnalisés. Chaque développeur génère alors du code conforme aux normes du projet automatiquement.

---

## 5. Sécurité

### 5.1 Gérer les droits via le Groupware Utilisateur

Le Groupware Utilisateur contrôle l'accès aux fenêtres, champs, boutons et états **sans une seule ligne de code**. Configurer via le logiciel Administrateur livré en standard.

Activer le Groupware dès le début du projet ; l'activer tardivement est plus coûteux.

### 5.2 Activer la double authentification

Le Groupware supporte la double authentification (code reçu par email ou SMS) pour les profils à accès sensibles.

### 5.3 Gérer les données RGPD

Pour chaque colonne de table contenant des données personnelles (nom, email, adresse...) :
1. Cocher la case **RGPD** dans la définition de la colonne dans l'analyse
2. Utiliser le rapport d'audit RGPD intégré pour obtenir une cartographie complète
3. Restreindre les exports FAA (Word/Excel/PDF) par mot de passe ou profil

### 5.4 Ne jamais passer de données utilisateur directement en SQL

Toujours utiliser des requêtes paramétrées ou les fonctions HLit* du WLangage (voir §2.2).

---

## 6. Gestion des versions (GDS/SCM)

### 6.1 Utiliser le GDS pour tout versionner

Le **GDS (Gestionnaire De Sources)** intégré versionne : code, fenêtres, états, requêtes, classes, images, analyses. Chaque modification est horodatée et identifiée par son auteur.

Ne jamais développer sans le GDS activé, même en solo.

### 6.2 Associer chaque réintégration à une tâche ou correction

Lors de la réintégration d'un élément dans le GDS, associer la modification à la tâche ou la correction correspondante dans le Centre de Contrôle ALM.

### 6.3 Utiliser les branches pour les versions parallèles

Les branches permettent de livrer des correctifs sur la version en production tout en développant la prochaine version, **sans coder deux fois**.

### 6.4 Compatibilité Git / GitHub

WinDev 2025 peut sauvegarder les projets au **format texte hybride YAML** compatible Git. Les fenêtres et états sont lisibles et diff-ables dans GitHub.

---

## 7. Tests automatisés

### 7.1 Créer des tests automatisés pour chaque traitement métier

WinDev 2025 intègre un outil de **tests automatisés** (enregistrement + rejeu). Créer des tests pour :
- Les traitements de saisie et validation des opérations
- Les calculs de rapports (totaux FCFA/EUR)
- Les transitions de statut des périodes

### 7.2 Intégrer les tests dans le cycle CI/CD

La **Fabrique Logicielle** (CI/CD) de WinDev automatise les builds, les tests et les déploiements. Configurer un pipeline pour que chaque modification déclenche un build + tests automatiques.

---

## 8. Déploiement

### 8.1 Utiliser le DMA (Déploiement et Mise à jour Automatisés)

Le DMA permet aux utilisateurs de recevoir automatiquement les mises à jour de l'application au démarrage (**Live Update**), sans intervention manuelle.

### 8.2 Générer le dossier technique avant chaque livraison

WinDev génère un **dossier technique complet** (fenêtres, code, analyse, règles...) en 1 clic. Ce dossier est toujours à jour car généré par rétro-analyse du projet. Le joindre à chaque livraison.

---

## 9. Performance

### 9.1 Utiliser l'Analyseur Temps Réel (ATR)

L'ATR affiche en temps réel un graphe de l'activité de l'application et détecte les lenteurs et blocages, y compris dans les threads.

### 9.2 Vérifier les index manquants

WinDev 2025 **détecte automatiquement les index manquants** lors de l'exécution de requêtes et propose de les créer pour optimiser les performances.

### 9.3 Activer la compression des trames réseau

Pour les accès distants au serveur HFSQL, activer la **compression des trames** réduit jusqu'à 95 % le volume de données transitant sur le réseau.

---

## Récapitulatif — Checklist projet

| # | Pratique | Priorité |
|---|---|---|
| 1 | Architecture 3-tiers respectée (pas de HLit* dans les fenêtres) | Critique |
| 2 | Requêtes toujours paramétrées (pas de concaténation SQL) | Critique |
| 3 | Mots de passe stockés via le type rubrique "Mot de passe" HFSQL | Critique |
| 4 | Groupware Utilisateur activé avec droits par profil | Critique |
| 5 | GDS activé et toutes les modifications versionées | Critique |
| 6 | EcranVersFichier utilisé pour les saisies | Haute |
| 7 | Chiffrement AES 256 sur les tables financières | Haute |
| 8 | Audit statique lancé avant chaque livraison | Haute |
| 9 | Gabarit et styles de champs appliqués uniformément | Haute |
| 10 | Tests automatisés pour les traitements métier critiques | Haute |
| 11 | FAA activées (ne pas désactiver sans raison) | Moyenne |
| 12 | Programmation défensive avec dbgVérifie* | Moyenne |
| 13 | DMA configuré pour les mises à jour automatiques | Moyenne |
| 14 | Compression de trames activée pour l'accès distant HFSQL | Moyenne |
| 15 | Dossier technique généré à chaque livraison | Basse |
