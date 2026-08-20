# Prédiction des ventes pharmaceutiques

<p align="center">
  <strong>
    Machine Learning · Séries temporelles · R · tidymodels · API REST · Docker · CI/CD · Monitoring
  </strong>
</p>

<p align="center">
  <a href="https://pharmaceutique1.github.io/prediction-ventes-pharma/">
    <img
      src="https://img.shields.io/badge/RAPPORT%20INTERACTIF-CONSULTER-00A6A6?style=for-the-badge&logo=github"
      alt="Consulter le rapport interactif"
    />
  </a>

  <a href="https://prediction-ventes-pharma.onrender.com/health">
    <img
      src="https://img.shields.io/badge/API-EN%20LIGNE-2E7D32?style=for-the-badge&logo=render"
      alt="API en ligne"
    />
  </a>
</p>

<p align="center">
  <a href="https://github.com/PHARMACEUTIQUE1/prediction-ventes-pharma/actions">
    <img
      src="https://img.shields.io/badge/CI%2FCD-GitHub%20Actions-2088FF?style=flat-square&logo=githubactions&logoColor=white"
      alt="GitHub Actions"
    />
  </a>

  <img
    src="https://img.shields.io/badge/R-4.3.3-276DC3?style=flat-square&logo=r&logoColor=white"
    alt="R"
  />

  <img
    src="https://img.shields.io/badge/Docker-Containerized-2496ED?style=flat-square&logo=docker&logoColor=white"
    alt="Docker"
  />

  <img
    src="https://img.shields.io/badge/MLOps-Monitoring%20%26%20Drift-purple?style=flat-square"
    alt="MLOps"
  />
</p>

---

## Présentation

Ce projet développe une chaîne complète de **Machine Learning et MLOps pour la prédiction de ventes pharmaceutiques à partir de séries temporelles**.

L'objectif n'est pas uniquement d'entraîner un modèle prédictif dans RStudio.

Le projet couvre l'ensemble du cycle de vie :

```text
Données
   ↓
Préparation
   ↓
Analyse exploratoire
   ↓
Feature engineering
   ↓
Validation temporelle
   ↓
Comparaison des modèles
   ↓
Optimisation
   ↓
Évaluation hors échantillon
   ↓
API REST
   ↓
Sécurité
   ↓
Docker
   ↓
CI/CD
   ↓
Cloud
   ↓
Monitoring / Data Drift
```

Le résultat est une solution capable de :

- analyser les dynamiques historiques des ventes ;
- produire des prévisions ;
- comparer plusieurs familles de modèles ;
- sélectionner le modèle selon sa capacité de généralisation ;
- exposer la prédiction via une API REST ;
- fonctionner dans un conteneur Docker ;
- être déployée automatiquement ;
- surveiller les données reçues en production ;
- détecter des dérives statistiques.

---

# Rapport interactif

Le rapport analytique complet est publié avec **GitHub Pages**.

<p align="center">
  <a href="https://pharmaceutique1.github.io/prediction-ventes-pharma/">
    <img
      src="https://img.shields.io/badge/OUVRIR%20LE%20RAPPORT-Analyse%20complète-00A6A6?style=for-the-badge"
      alt="Ouvrir le rapport"
    />
  </a>
</p>

### Accès direct

**https://pharmaceutique1.github.io/prediction-ventes-pharma/**

Le rapport présente notamment :

- la problématique métier ;
- la structure temporelle des données ;
- l'évolution historique des ventes ;
- la saisonnalité ;
- les corrélations ;
- le test de stationnarité ADF ;
- la construction des variables temporelles ;
- la validation croisée temporelle ;
- la comparaison des modèles ;
- le tuning des hyperparamètres ;
- l'évaluation finale ;
- l'analyse des résidus ;
- l'industrialisation ;
- l'API REST ;
- Docker ;
- la CI/CD ;
- le monitoring ;
- la détection du data drift.

Le rapport est généré automatiquement par **GitHub Actions** et déployé sur **GitHub Pages**.

---

# Problématique métier

Les ventes pharmaceutiques peuvent évoluer sous l'effet de nombreux phénomènes :

- saisonnalité ;
- tendances de consommation ;
- comportement récent des ventes ;
- effets calendaires ;
- variations ponctuelles de la demande.

La question principale du projet est :

> **Dans quelle mesure l'historique des ventes et les caractéristiques temporelles permettent-ils de prédire les ventes pharmaceutiques futures ?**

Une meilleure anticipation des ventes peut contribuer à :

- améliorer la planification ;
- anticiper les variations de demande ;
- accompagner le pilotage opérationnel ;
- identifier plus rapidement certaines évolutions de consommation ;
- fournir une aide quantitative à la décision.

---

# Données

Le projet utilise des données historiques quotidiennes de ventes pharmaceutiques.

Le fichier source principal est :

```text
data/raw/salesdaily.csv
```

Les catégories disponibles comprennent notamment :

| Variable d'origine | Interprétation |
|---|---|
| M01AB | Anti-inflammatoires dérivés de l'acide acétique |
| M01AE | Anti-inflammatoires dérivés de l'acide propionique |
| N02BA | Analgésiques / antipyrétiques salicylés |
| N02BE | Analgésiques / antipyrétiques anilides |
| N05B | Anxiolytiques |
| N05C | Hypnotiques et sédatifs |
| R03 | Médicaments des voies respiratoires |
| R06 | Antihistaminiques systémiques |

Dans la version actuelle du pipeline, la cible principale étudiée est :

```text
analgesiques_antipyretiques_anilides
```

Une extension naturelle du projet consiste à automatiser l'entraînement d'un modèle distinct pour chaque famille de médicaments.

---

# Feature engineering

La modélisation exploite plusieurs familles de variables temporelles.

## Variables calendaires

```text
annee
mois
jour_mois
semaine_annee
trimestre
jour_semaine
weekend
debut_mois
fin_mois
tendance
```

## Retards temporels

```text
ventes_lag_1
ventes_lag_7
ventes_lag_14
ventes_lag_30
```

Ils représentent respectivement les ventes observées :

- la veille ;
- une semaine auparavant ;
- deux semaines auparavant ;
- environ un mois auparavant.

## Variables de dynamique

```text
moyenne_mobile_7j
moyenne_mobile_30j
variation_7j
ecart_moyennes_mobiles
volatilite_7j
```

Ces variables permettent de représenter :

- le niveau récent des ventes ;
- la tendance court terme ;
- la tendance moyen terme ;
- les accélérations ou ralentissements ;
- la volatilité récente.

---

# Stratégie de validation

Une séparation aléatoire classique n'est pas adaptée à une série temporelle.

Le projet utilise donc une séparation **chronologique** :

```text
Historique
│
├────────────────────── 80 % ──────────────────────┐
│                                                  │
▼                                                  │
Apprentissage                                      │
│                                                  │
├── fenêtre temporelle 1 → validation future       │
├── fenêtre temporelle 2 → validation future       │
├── fenêtre temporelle 3 → validation future       │
└── ...                                            │
                                                   │
                              20 % les plus récents
                                                   │
                                                   ▼
                                             TEST FINAL
```

Le jeu de test final reste isolé pendant la sélection du modèle.

Cette approche limite le risque de fuite d'information entre le passé et le futur.

---

# Modèles évalués

Trois familles de modèles ont été comparées.

## Régression linéaire

Utilisée comme **benchmark** :

- simple ;
- interprétable ;
- rapide ;
- robuste ;
- adaptée comme niveau de référence.

## Random Forest

Permet de représenter :

- des relations non linéaires ;
- des interactions entre variables ;
- des structures plus complexes.

Les hyperparamètres `mtry` et `min_n` font l'objet d'une optimisation.

## XGBoost

Modèle de gradient boosting dans lequel les arbres sont construits successivement afin de corriger progressivement les erreurs précédentes.

Les paramètres optimisés comprennent notamment :

```text
trees
tree_depth
learn_rate
min_n
```

---

# Sélection du modèle

La sélection du modèle repose principalement sur la **RMSE obtenue en validation croisée temporelle**.

Les métriques utilisées sont :

| Métrique | Utilité |
|---|---|
| MAE | Erreur absolue moyenne |
| RMSE | Erreur quadratique moyenne, plus sensible aux fortes erreurs |
| R² | Part de variabilité expliquée |

Dans la configuration actuellement industrialisée, le modèle retenu est une :

**Régression linéaire**

La décision est fondée sur la capacité de généralisation observée et non sur la sophistication algorithmique.

Les valeurs détaillées et actualisées sont disponibles dans le :

**[rapport interactif](https://pharmaceutique1.github.io/prediction-ventes-pharma/)**.

---

# API de prédiction

Le modèle est exposé via une API REST développée avec **Plumber**.

### URL du service

```text
https://prediction-ventes-pharma.onrender.com
```

---

## Vérification du service

Endpoint :

```text
GET /health
```

Test :

```bash
curl https://prediction-ventes-pharma.onrender.com/health
```

Accès navigateur :

**https://prediction-ventes-pharma.onrender.com/health**

---

## Obtenir une prédiction

Endpoint :

```text
POST /predict
```

URL :

```text
https://prediction-ventes-pharma.onrender.com/predict
```

L'endpoint est protégé par une clé API transmise dans le header :

```text
X-API-Key
```

La clé réelle n'est jamais enregistrée dans le dépôt GitHub.

---

## Exemple de requête

```bash
curl -X POST \
  https://prediction-ventes-pharma.onrender.com/predict \
  -H "Content-Type: application/json" \
  -H "X-API-Key: VOTRE_CLE_API" \
  -d '{
    "date": "2026-08-20",
    "annee": 2026,
    "mois": 8,
    "jour_mois": 20,
    "semaine_annee": 34,
    "trimestre": 3,
    "jour_semaine": "jeudi",
    "weekend": 0,
    "tendance": 1,
    "debut_mois": 0,
    "fin_mois": 0,
    "ventes_lag_1": 20,
    "ventes_lag_7": 22,
    "ventes_lag_14": 21,
    "ventes_lag_30": 19,
    "moyenne_mobile_7j": 21,
    "moyenne_mobile_30j": 20,
    "variation_7j": 1,
    "ecart_moyennes_mobiles": 1,
    "volatilite_7j": 2
  }'
```

Exemple de réponse :

```json
{
  "status": ["success"],
  "code": [200],
  "prediction": [23.7751]
}
```

> La valeur `VOTRE_CLE_API` est volontairement fictive.  
> Aucune clé privée ne doit être publiée dans GitHub.

---

# Sécurité de l'API

L'API intègre plusieurs protections.

## Authentification

L'accès à `/predict` nécessite :

```text
X-API-Key
```

La clé est injectée via une variable d'environnement.

Elle n'est pas présente dans :

- le code source ;
- Dockerfile ;
- GitHub ;
- README ;
- rapport public.

## Gestion des erreurs

L'API peut notamment retourner :

| Code | Signification |
|---|---|
| 200 | Prédiction réussie |
| 400 | Requête invalide |
| 401 | Authentification refusée |
| 413 | Requête trop volumineuse |

Les messages publics restent volontairement génériques afin de limiter l'exposition d'informations techniques internes.

---

# Docker

Le service est conteneurisé avec Docker.

L'image contient notamment :

```text
R
↓
Dépendances
↓
Modèle entraîné
↓
API Plumber
↓
Monitoring
```

Cette approche améliore :

- la reproductibilité ;
- la portabilité ;
- la cohérence entre développement et production.

---

# CI/CD

Le projet utilise **GitHub Actions**.

Deux chaînes principales sont automatisées.

## Pipeline application

```text
Push sur main
      ↓
Checkout
      ↓
Build Docker
      ↓
Authentification Docker Hub
      ↓
Publication de l'image
      ↓
Déploiement
```

## Pipeline rapport

```text
Déclenchement automatique
      ↓
Installation de R
      ↓
Restauration / cache des dépendances
      ↓
Exécution du pipeline analytique
      ↓
Génération du R Markdown
      ↓
Création de index.html
      ↓
Déploiement GitHub Pages
```

Le rapport peut également être lancé manuellement avec :

```text
GitHub
→ Actions
→ Build and Publish Report
→ Run workflow
```

---

# GitHub Pages

Le rapport est automatiquement déployé sur :

```text
https://pharmaceutique1.github.io/prediction-ventes-pharma/
```

La publication repose sur :

```text
actions/configure-pages
actions/upload-pages-artifact
actions/deploy-pages
```

Le site généré utilise :

```text
docs/index.html
```

comme page principale.

---

# Monitoring

Un modèle en production ne doit pas être considéré comme définitivement stable.

Le projet intègre donc un module de monitoring dans :

```text
R/13_monitoring_drift.R
```

Les contrôles portent notamment sur :

- comportement de l'API ;
- distributions des variables ;
- qualité des données reçues ;
- distribution des prédictions ;
- valeurs hors plages connues ;
- valeurs manquantes ;
- catégories inconnues ;
- dérive statistique.

---

# Data Drift

Le **Population Stability Index — PSI** est utilisé comme indicateur principal de stabilité des distributions.

Les règles opérationnelles du projet sont :

```text
PSI < 0.10
→ OK

0.10 ≤ PSI < 0.25
→ A_SURVEILLER

PSI ≥ 0.25
→ DRIFT_DETECTE
```

Le PSI n'est pas interprété seul.

Il est complété par d'autres indicateurs tels que :

- déplacement de moyenne ;
- valeurs hors plage ;
- qualité des données ;
- dérive des prédictions ;
- comportement technique de l'API.

Un drift ne provoque pas automatiquement un réentraînement.

Il constitue un signal nécessitant une investigation.

---

# Architecture technique

```text
┌────────────────────────────────────────────┐
│           DONNÉES HISTORIQUES              │
└─────────────────────┬──────────────────────┘
                      │
                      ▼
┌────────────────────────────────────────────┐
│          PRÉPARATION DES DONNÉES           │
└─────────────────────┬──────────────────────┘
                      │
                      ▼
┌────────────────────────────────────────────┐
│            FEATURE ENGINEERING             │
│                                            │
│  Lags · Moyennes mobiles · Tendance        │
│  Variation · Volatilité · Calendrier       │
└─────────────────────┬──────────────────────┘
                      │
                      ▼
┌────────────────────────────────────────────┐
│        VALIDATION CROISÉE TEMPORELLE       │
└─────────────────────┬──────────────────────┘
                      │
                      ▼
┌────────────────────────────────────────────┐
│           COMPARAISON MODÈLES              │
│                                            │
│  Linear Regression                         │
│  Random Forest                             │
│  XGBoost                                   │
└─────────────────────┬──────────────────────┘
                      │
                      ▼
┌────────────────────────────────────────────┐
│             MODÈLE FINAL                   │
│           Régression linéaire              │
└─────────────────────┬──────────────────────┘
                      │
                      ▼
┌────────────────────────────────────────────┐
│               API PLUMBER                  │
│                                            │
│        GET /health · POST /predict         │
└─────────────────────┬──────────────────────┘
                      │
                      ▼
┌────────────────────────────────────────────┐
│                 SÉCURITÉ                   │
│                                            │
│     API Key · Validation · Erreurs         │
└─────────────────────┬──────────────────────┘
                      │
                      ▼
┌────────────────────────────────────────────┐
│                  DOCKER                    │
└─────────────────────┬──────────────────────┘
                      │
                      ▼
┌────────────────────────────────────────────┐
│            GITHUB ACTIONS CI/CD            │
└─────────────────────┬──────────────────────┘
                      │
              ┌───────┴────────┐
              │                │
              ▼                ▼
        Docker Hub        GitHub Pages
              │                │
              ▼                ▼
           Render        Rapport public
              │
              ▼
       API de production
              │
              ▼
┌────────────────────────────────────────────┐
│            MONITORING / DRIFT              │
└────────────────────────────────────────────┘
```

---

# Organisation du projet

```text
prediction-ventes-pharma/
│
├── .github/
│   └── workflows/
│       ├── docker-ci.yml
│       └── report-pages.yml
│
├── api/
│   └── plumber.R
│
├── data/
│   ├── raw/
│   ├── interim/
│   └── processed/
│
├── docker/
│   └── Dockerfile
│
├── docs/
│   └── index.html
│
├── models/
│   ├── modele_ventes_pharma_lm.rds
│   └── monitoring_reference.rds
│
├── outputs/
│   ├── figures/
│   ├── logs/
│   ├── metrics/
│   └── monitoring/
│
├── R/
│   ├── 00_packages.R
│   ├── 01_configuration.R
│   ├── 02_preparation_donnees.R
│   ├── 03_feature_engineering.R
│   ├── 04_split_temporel.R
│   ├── 05_recipe.R
│   ├── 06_modeles.R
│   ├── 07_tuning.R
│   ├── 08_evaluation_finale.R
│   ├── 09_sauvegarde_modele.R
│   ├── 10_test_rechargement.R
│   ├── 11_fonction_prediction.R
│   ├── 12_logs_api.R
│   └── 13_monitoring_drift.R
│
├── reports/
│   └── rapport_final_prediction_ventes_pharma.Rmd
│
├── tests/
│
├── .gitignore
├── renv.lock
├── README.md
└── prediction-ventes-pharma.Rproj
```

---

# Technologies

| Domaine | Technologie |
|---|---|
| Langage | R |
| Data manipulation | tidyverse |
| Machine Learning | tidymodels |
| Régression | parsnip / lm |
| Random Forest | ranger |
| Gradient Boosting | xgboost |
| Validation | rsample |
| Métriques | yardstick |
| API | Plumber |
| Tests | testthat |
| Conteneurisation | Docker |
| CI/CD | GitHub Actions |
| Registry | Docker Hub |
| Cloud | Render |
| Rapport | R Markdown |
| Publication | GitHub Pages |
| Monitoring | R + PSI |
| Environnement | renv |
| Versionnement | Git / GitHub |

---

# Reproductibilité

Le projet utilise :

```text
renv
```

afin de gérer les dépendances R.

Pour restaurer l'environnement :

```r
renv::restore()
```

Le fichier de référence est :

```text
renv.lock
```

La conteneurisation Docker fournit une seconde couche de reproductibilité pour l'environnement de production.

---

# Exécution locale

## 1. Cloner le dépôt

```bash
git clone https://github.com/PHARMACEUTIQUE1/prediction-ventes-pharma.git
```

Puis :

```bash
cd prediction-ventes-pharma
```

## 2. Restaurer les packages R

Dans R :

```r
install.packages("renv")
renv::restore()
```

## 3. Exécuter le pipeline

Les différentes étapes sont organisées dans le dossier :

```text
R/
```

Le pipeline final d'évaluation peut être lancé depuis :

```r
source("R/08_evaluation_finale.R")
```

---

# Générer le rapport localement

Depuis R :

```r
rmarkdown::render(
  "reports/rapport_final_prediction_ventes_pharma.Rmd"
)
```

Le rapport public est également généré automatiquement par GitHub Actions.

---

# Limites actuelles

Le projet constitue une chaîne MLOps complète, mais plusieurs axes restent ouverts.

## Cible unique

La version actuelle industrialise principalement la prédiction de :

```text
analgesiques_antipyretiques_anilides
```

Une évolution prévue consiste à construire automatiquement un modèle pour chaque famille thérapeutique.

## Variables métier

Les performances pourraient être enrichies avec :

- prix ;
- promotions ;
- disponibilité ;
- ruptures ;
- événements sanitaires ;
- météo ;
- vacances ;
- données épidémiologiques ;
- caractéristiques géographiques ou commerciales.

## Modélisation

Des extensions pourraient explorer :

- modèles autorégressifs ;
- modèles hybrides séries temporelles / Machine Learning ;
- autres méthodes de boosting ;
- ensembles de modèles ;
- prévisions multi-horizons.

Toute nouvelle méthode ne serait retenue que si elle améliore de manière stable la performance en validation temporelle.

---

# Roadmap

Les principales évolutions possibles sont :

- [x] Préparation des données
- [x] Analyse exploratoire
- [x] Feature engineering
- [x] Validation temporelle
- [x] Régression linéaire
- [x] Random Forest
- [x] XGBoost
- [x] Tuning
- [x] Évaluation hors échantillon
- [x] API REST
- [x] Sécurité API
- [x] Tests
- [x] Docker
- [x] Docker Hub
- [x] CI/CD
- [x] Déploiement Render
- [x] Monitoring
- [x] Data Drift
- [x] Rapport R Markdown
- [x] GitHub Pages
- [x] Publication automatique du rapport
- [ ] Généralisation multi-médicaments
- [ ] Interface publique de démonstration du modèle
- [ ] Stratégie automatisée de réentraînement

---

# Accès rapide

| Ressource | Lien |
|---|---|
| Rapport interactif | [Ouvrir](https://pharmaceutique1.github.io/prediction-ventes-pharma/) |
| API | [Service Render](https://prediction-ventes-pharma.onrender.com) |
| Health check | [Vérifier l'API](https://prediction-ventes-pharma.onrender.com/health) |
| Code source | [GitHub](https://github.com/PHARMACEUTIQUE1/prediction-ventes-pharma) |
| GitHub Actions | [Workflows](https://github.com/PHARMACEUTIQUE1/prediction-ventes-pharma/actions) |

---

# Auteur

**Isaac Ama**

Data Analyst / Data Scientist

Compétences mobilisées dans ce projet :

```text
R
Machine Learning
Statistiques
Séries temporelles
tidymodels
API REST
Docker
CI/CD
GitHub Actions
MLOps
Monitoring
Data Drift
```

---

<p align="center">
  <a href="https://pharmaceutique1.github.io/prediction-ventes-pharma/">
    <img
      src="https://img.shields.io/badge/CONSULTER%20LE%20PROJET-RAPPORT%20INTERACTIF-00A6A6?style=for-the-badge"
      alt="Rapport interactif"
    />
  </a>
</p>

<p align="center">
  <strong>
    Données → Machine Learning → API → Docker → CI/CD → Cloud → Monitoring
  </strong>
</p>
