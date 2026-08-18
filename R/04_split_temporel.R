# ==============================================================================
      # 04_split_temporel.R
      # Projet : Prédiction des ventes pharmaceutiques
      # Objectif : Séparer les données en apprentissage
      # et test sans fuite temporelle
# ==============================================================================
source("R/03_feature_engineering.R")

# Tri chronologique
donnees_ml <- donnees_ml |>
  arrange(date)

# --------------------------------------------------
  # Définition de la taille du jeu d'apprentissage
# --------------------------------------------------

# On conserve 80 % des observations les plus anciennes pour l'apprentissage
# et 20 % des observations les plus récentes pour le test.

n_train <- floor(nrow(donnees_ml) * PROP_TRAIN)

# -----------------------------------------
      # Création des jeux Train et Test
# -----------------------------------------
train_data <- donnees_ml |>
  slice(1:n_train)

test_data <- donnees_ml |>
  slice((n_train + 1):n())

# ------------------------------
       # Vérifications
# ------------------------------
dim(train_data)
dim(test_data)

range(train_data$date)
range(test_data$date)

# -------------------------------------
# Validation croisée temporelle
# -------------------------------------

# On crée plusieurs fenêtres temporelles successives.
# Le modèle apprend toujours sur le passé et valide sur une période future.

cv_temporelle <- sliding_period(
  train_data, index = date, period = "day",
  lookback = 365 * 2 - 1,  # environ 2 ans d'apprentissage
  assess_stop = 90,        # validation sur 90 jours
  step = 90)
#cv_temporelle
#nrow(cv_temporelle)
#cv_temporelle$splits[[1]]

#  +++++++++++++ INTERPREATION ++++++++++++++ #

# Analysis = 730 observations utilisées pour entraîner
# Assess   = 90 observations utilisées pour valider
# Total    = 1060 observations concernées par la structure du split


# Données complètes
# │
# ├── 80 % TRAIN
# │      │
# │      ├── Fold 1 → train / validation
# │      ├── Fold 2 → train / validation
# │      ├── ...
# │      └── Fold 10 → train / validation
# │
# └── 20 % TEST FINAL
#       ↑
# jamais touché pour l'instant


