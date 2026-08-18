# ==============================================================================
        # 07_tuning.R
        # Projet : Prédiction des ventes pharmaceutiques
        # Objectif : Optimiser les hyperparamètres des modèles de Machine Learning
# ==============================================================================
source("R/06_modeles.R")

                # ============================== #
                # 1. TUNING RANDOM FOREST
                # ============================== #

# Hyperparamètres à optimiser :

# mtry  : nombre de variables candidates testées à chaque séparation d'un arbre
# min_n : nombre minimal d'observations nécessaires dans un noeud
# trees reste fixé ici à 500 pour limiter le temps de calcul.

# ---------------------------------------------------
      # Définition du modèle Random Forest à tuner
# ---------------------------------------------------
modele_rf_tune <- rand_forest(
  trees = 500,
  mtry = tune(),
  min_n = tune()) |>
  set_engine("ranger") |>
  set_mode("regression")

# -------------------------------------------
          # Workflow de tuning
# -------------------------------------------
workflow_rf_tune <- workflow() |>
  add_recipe(recette_ml) |>
  add_model(modele_rf_tune)

# --------------------------------------------------
    # Définition d'une grille d'hyperparamètres
# --------------------------------------------------

# On teste plusieurs combinaisons de mtry et min_n.
grille_rf <- grid_regular(
  mtry(range = c(2L, 15L)),
  min_n(range = c(2L, 30L)),
  levels = 5)
grille_rf

# -----------------------------------------------------
      # Tuning avec validation croisée temporelle
# -----------------------------------------------------
resultats_tuning_rf <- tune_grid(workflow_rf_tune,
  resamples = cv_temporelle,
  grid = grille_rf,
  metrics = metriques_regression,
  control = control_grid(save_pred = TRUE))

# --------------------------------------
      # Résultats du tuning
# --------------------------------------
collect_metrics(resultats_tuning_rf)

    # ===================================================================
          # 2. SÉLECTION DES MEILLEURS HYPERPARAMÈTRES RANDOM FOREST
    # ===================================================================
# La RMSE est utilisée comme métrique principale de sélection. Plus elle est faible, meilleur est le modèle.
meilleurs_parametres_rf <- select_best(resultats_tuning_rf,metric = "rmse")
#meilleurs_parametres_rf


show_best(resultats_tuning_rf,metric = "rmse",n = 5)

# Le meilleur Random Forest est : mtry= 5, min_n = 30, RMSE  = 12.8

# ================================================
          # 3. FINALISATION DU RANDOM FOREST
# ================================================      
# Injection des meilleurs hyperparamètres dans le workflow
workflow_rf_final <- finalize_workflow(workflow_rf_tune,meilleurs_parametres_rf)
#workflow_rf_final



                  # ======================================= #
                            # 4. TUNING XGBOOST
                  # ======================================= #

# Hyperparamètres principaux :
# - trees      : nombre d'arbres successifs
# - tree_depth : profondeur maximale des arbres
# - learn_rate : vitesse d'apprentissage
# - min_n      : nombre minimum d'observations dans un noeud

modele_xgb_tune <- boost_tree(
  trees = tune(),
  tree_depth = tune(),
  learn_rate = tune(),
  min_n = tune()) |>
  set_engine("xgboost") |>
  set_mode("regression")

# -----------------------------------
      # Workflow XGBoost à tuner
# -----------------------------------
workflow_xgb_tune <- workflow() |>
  add_recipe(recette_ml) |>
  add_model(modele_xgb_tune)


# ------------------------------------ #
        # Grille de recherche
# ------------------------------------ #
grille_xgb <- grid_space_filling(
  trees(range = c(300L, 1000L)),
  tree_depth(range = c(2L, 8L)),
  learn_rate(range = c(-3, -1)),
  min_n(range = c(2L, 30L)),
  size = 20)
grille_xgb


# --------------------------------------------------------------
        # Tuning XGBoost avec validation croisée temporelle
# --------------------------------------------------------------
resultats_tuning_xgb <- tune_grid(workflow_xgb_tune,
  resamples = cv_temporelle,
  grid = grille_xgb,
  metrics = metriques_regression,
  control = control_grid(save_pred = TRUE))

show_best(resultats_tuning_xgb,metric = "rmse",n = 5)
#Les meilleures configurations tournent autour de :
# trees      ≈ 300–600
# tree_depth ≈ 3–7
# learn_rate ≈ 0.003–0.009
# min_n      ≈ 18–28
# RMSE       ≈ 12.8


# =========================================================
      # 5. SÉLECTION DES MEILLEURS HYPERPARAMÈTRES XGBOOST
# =========================================================
meilleurs_parametres_xgb <- select_best(resultats_tuning_xgb,metric = "rmse")
meilleurs_parametres_xgb

# ==========================================================
        # 6. FINALISATION DU WORKFLOW XGBOOST
# ==========================================================
workflow_xgb_final <- finalize_workflow(workflow_xgb_tune,meilleurs_parametres_xgb)
workflow_xgb_final


# ======================================================= #
       # 7. COMPARAISON DES MODÈLES APRÈS TUNING
# ======================================================= #

# Récupération des meilleures performances obtenues en validation croisée temporelle pour Random Forest et XGBoost.

meilleure_rmse_rf <- show_best(resultats_tuning_rf,metric = "rmse",n = 1)
meilleure_rmse_xgb <- show_best(resultats_tuning_xgb,metric = "rmse",n = 1)


# ----------------------------------------------
          # Tableau de comparaison
# ----------------------------------------------
comparaison_finale <- tibble(modele = c("Régression linéaire", "Random Forest optimisé","XGBoost optimisé"),
  rmse = c(resultats_metriques_lm |>
      filter(.metric == "rmse") |>
      pull(mean),
    meilleure_rmse_rf$mean,
    meilleure_rmse_xgb$mean))|>
  arrange(rmse)
comparaison_finale
#Régression linéaire     RMSE = 12.1   ← meilleur