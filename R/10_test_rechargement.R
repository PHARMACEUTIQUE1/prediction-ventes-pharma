# ==============================================================================
# 10_test_rechargement.R
# Projet : Prédiction des ventes pharmaceutiques
# Objectif : Vérifier que le modèle sauvegardé peut être rechargé et utilisé
# ==============================================================================

source("R/00_packages.R")
source("R/01_configuration.R")
source("R/04_split_temporel.R")


# -----------------------------------
     # 1. Rechargement du modèle
# -----------------------------------
modele_charge <- readRDS(file.path(DIR_MODELS, "modele_ventes_pharma_lm.rds"))


# -----------------------------------------------------
           # 2. Test sur une observation jamais vue
# -----------------------------------------------------

nouvelle_observation <- test_data |>
  slice(1)


# --------------------------------------
     # 3. Prédiction
# -------------------------------------
prediction_test <- predict(modele_charge,new_data = nouvelle_observation)
prediction_test