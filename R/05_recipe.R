# ==============================================================================
    # 05_recipe.R
    # Projet : Prédiction des ventes pharmaceutiques
    # Objectif : Définir la variable cible et préparer les variables explicatives
# ==============================================================================

source("R/04_split_temporel.R")

# ---------------------------------------------
  # Définition de la recette de prétraitement
# ------------------------------------------

recette_ml <- recipe(
  analgesiques_antipyretiques_anilides ~ ., data = train_data) |>
  # La date sert à organiser la série temporelle,
  # mais ne sera pas directement utilisée comme variable numérique par le modèle.
  update_role(date, new_role = "id") |>
  # Transformation des variables catégorielles en variables numériques
  # utilisables par les algorithmes de Machine Learning.
  step_dummy(all_nominal_predictors()) |>
  # Suppression éventuelle des variables sans variance.
  step_zv(all_predictors())

#recette_ml

# -------------------------------------------------------------
  # Préparation de la recette sur les données d'apprentissage
# -------------------------------------------------------------

recette_preparee <- prep(recette_ml,training = train_data)
#recette_preparee

# ------------------------------------------------
    # Vérification des données transformées
# ------------------------------------------------

train_prepare <- bake(recette_preparee,new_data = train_data)
#glimpse(train_prepare)