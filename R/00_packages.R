# =====================================================
# 00_packages.R
# Projet : Prédiction des ventes pharmaceutiques
# Objectif : Charger les packages nécessaires au projet
# ======================================================


# ------------------------------------------------------------------------------
# Manipulation et préparation des données
# ------------------------------------------------------------------------------

library(tidyverse)   # Manipulation de données, visualisation et transformation
library(janitor)     # Nettoyage des noms de colonnes et contrôles simples
library(lubridate)   # Manipulation des dates et périodes


# ------------------------------------------------------------------------------
# Machine Learning avec tidymodels
# ------------------------------------------------------------------------------

library(tidymodels)  # Ensemble d'outils pour preprocessing, modèles, validation croisée, tuning et évaluation


# ------------------------------------------------------------------------------
# Reproductibilité
# ------------------------------------------------------------------------------

set.seed(1234)       # Permet d'obtenir les mêmes résultats lors des opérations comportant une part aléatoire