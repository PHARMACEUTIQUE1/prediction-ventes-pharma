# =====================================================
# 00_packages.R
# Projet : Prédiction des ventes pharmaceutiques
# Objectif : Charger les packages nécessaires au projet
# =======================================y===============


# ------------------------------------------------------------------------------
# Manipulation et préparation des données
# ------------------------------------------------------------------------------

library(tidyverse)   # Manipulation de données, visualisation et transformation
library(janitor)     # Nettoyage des noms de colonnes et contrôles simples
library(tidyverse)   # Manipulation des dates et périodes
library(slider) 
#library(timetk)      # Outils pour séries temporelles et validation temporelle
library(tidymodels)  # Ensemble d'outils pour preprocessing, modèles, validation croisée, tuning et évaluation
library(corrplot)    # Visualisation des matrices de corrélation
library(ranger)
library(xgboost) 
library(plumber)
library(testthat)
library(httr2)
library(rlang)

# ------------------------------------------------------------------------------
# Reproductibilité
# ------------------------------------------------------------------------------

set.seed(1234)       # Permet d'obtenir les mêmes résultats lors des opérations comportant une part aléatoire