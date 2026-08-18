# ==============================================================================
# 06_modeles.R
# Projet : Prédiction des ventes pharmaceutiques
# Objectif :
#   - Diagnostiquer les relations entre variables explicatives
#   - Corriger la colinéarité pour la régression linéaire
#   - Construire le modèle benchmark
#   - Évaluer ses performances par validation croisée temporelle
# ==============================================================================

source("R/05_recipe.R")

# ==============================================================================
# 1. DIAGNOSTIC DES VARIABLES EXPLICATIVES
# ==============================================================================

# Le diagnostic est réalisé uniquement sur une partie des données
# d'apprentissage.
# Le jeu de test final reste totalement intact.

split_1 <- cv_temporelle$splits[[1]]
train_fold_1 <- analysis(split_1)

# ----------------------------------------
      # Sélection des variables numériques
# ----------------------------------------

train_fold_num <- train_fold_1 |>
  select(where(is.numeric))


# --------------------------------
    # Matrice de corrélation
# --------------------------------
matrice_cor <- cor(train_fold_num,use = "complete.obs")
# Affichage numérique
round(matrice_cor, 2)

# -----------------------------------------------
    # Visualisation de la matrice de corrélation
# -----------------------------------------------

#windows()
corrplot(
  matrice_cor,
  method = "color",
  type = "upper",
  order = "hclust",
  tl.cex = 0.45,      # Taille réduite des noms de variables
  tl.col = "black",
  addCoef.col = "black",
  number.cex = 0.35,
  mar = c(0, 0, 1, 0)
)
# -------------------------------------------------
    # Identification des corrélations très fortes
# -------------------------------------------------

# On recherche les couples de variables dont la corrélation absolue
# est supérieure à 0.90.

correlations_fortes <- which(abs(matrice_cor) > 0.90 &abs(matrice_cor) < 1,arr.ind = TRUE)
correlations_fortes

# ==============================================================================
# 2. RECETTE SPÉCIFIQUE À LA RÉGRESSION LINÉAIRE
# ==============================================================================
recette_lm <- recette_ml |>

# Suppression des variables déterministes / redondantes

# weekend est entièrement déductible de jour_semaine.
# variation_7j est exactement : ventes_lag_1 - ventes_lag_7
# ecart_moyennes_mobiles est exactement : moyenne_mobile_7j - moyenne_mobile_30j
# Les conserver simultanément crée de la colinéarité parfaite dans une régression linéaire.

step_rm(weekend,variation_7j,ecart_moyennes_mobiles) |>
  
# Suppression des dépendances linéaires restantes
step_lincomb(all_numeric_predictors()) |>
  
# Suppression des très fortes corrélations
step_corr(all_numeric_predictors(),threshold = 0.90)


# =================================================
      # 3. MODÈLE BENCHMARK : RÉGRESSION LINÉAIRE
# =================================================

# La régression linéaire constitue notre modèle de référence.

# Les modèles plus complexes, comme Random Forest ou XGBoost,
# devront apporter une amélioration par rapport à ce benchmark.

modele_lm <- linear_reg() |>
  set_engine("lm") |>
  set_mode("regression")
#modele_lm

# ============================================
    # 4. WORKFLOW : PRÉTRAITEMENT + MODÈLE
# ============================================

# Le workflow garantit que les mêmes transformations sont appliquées
# automatiquement dans chaque fold de validation croisée.

workflow_lm <- workflow() |>
  add_recipe(recette_lm) |>
  add_model(modele_lm)
workflow_lm

# =======================================
      # 5. MÉTRIQUES D'ÉVALUATION
# =======================================

# RMSE → pénalise davantage les grosses erreurs.
# MAE → erreur absolue moyenne exprimée dans l'unité des ventes.
# R² → proportion de la variabilité expliquée par le modèle.

metriques_regression <- metric_set(rmse,mae,rsq)

# =========================================
    # 6. VALIDATION CROISÉE TEMPORELLE
# =========================================

# Le modèle est évalué sur les folds temporels définis dans
# 04_split_temporel.R.

# Important :
# le jeu test_data n'est toujours PAS utilisé ici.

resultats_cv_lm <- fit_resamples(
  workflow_lm,
  resamples = cv_temporelle,
  metrics = metriques_regression,
  control = control_resamples(
    save_pred = TRUE))


# =============================
    # 7. RÉSULTATS DU MODÈLE
# =============================

resultats_metriques_lm <- collect_metrics(resultats_cv_lm)
resultats_metriques_lm

# ---------------------------------------
    # Interprétation du benchmark
# ---------------------------------------

# MAE  ≈ 9.19 unités : le modèle commet en moyenne une erreur absolue d'environ 9 unités de vente.
# RMSE ≈ 12.1 unités : les erreurs importantes sont davantage pénalisées.
# R²   ≈ 0.17 : le modèle linéaire explique environ 17 % de la variabilité des ventes.

# Ce modèle constitue notre benchmark.  Les modèles plus complexes devront améliorer ces performances.


            # ======================================== #
                        # 8. MODÈLE RANDOM FOREST
            # ======================================== #
# Random Forest permet de modéliser des relations non linéaires et des interactions entre variables explicatives.

modele_rf <- rand_forest(
  trees = 500) |>
  set_engine("ranger") |>
  set_mode("regression")


# --------------------------------------------
# Workflow Random Forest
# --------------------------------------------

workflow_rf <- workflow() |>
  add_recipe(recette_ml) |>
  add_model(modele_rf)

# ------------------------------------------------------
    # Validation croisée temporelle du Random Forest
# -----------------------------------------------------

resultats_cv_rf <- fit_resamples(workflow_rf,
  resamples = cv_temporelle,
  metrics = metriques_regression,
  control = control_resamples(save_pred = TRUE))


# -----------------------------------------------
              # Résultats
# -----------------------------------------------

resultats_metriques_rf <- collect_metrics(resultats_cv_rf)
resultats_metriques_rf
# le Random Forest explique légèrement plus de variance ( 18,4 %vs 17 %) ;
# mais il fait davantage d'erreurs ( MAEet RMSEplus élevée) ;
# donc il ne bat pas encore réellement notre benchmark linéaire.


            # ============================================== #
                       # 9. MODÈLE XGBOOST
            # ============================================== #

# XGBoost construit plusieurs arbres successifs. Chaque nouvel arbre cherche à corriger les erreurs des arbres précédents.

modele_xgb <- boost_tree(trees = 500,tree_depth = 6,
  learn_rate = 0.05,
  loss_reduction = 0,
  min_n = 10) |>
  set_engine("xgboost") |>
  set_mode("regression")


# ----------------------------------------------
          # Workflow XGBoost
# ----------------------------------------------

workflow_xgb <- workflow() |>
  add_recipe(recette_ml) |>
  add_model(modele_xgb)


# -----------------------------------------------
      # Validation croisée temporelle
# -----------------------------------------------

resultats_cv_xgb <- fit_resamples(workflow_xgb,
  resamples = cv_temporelle,
  metrics = metriques_regression,
  control = control_resamples(save_pred = TRUE))


# -------------------------------------------
    # Résultats XGBoost
# -------------------------------------------
resultats_metriques_xgb <- collect_metrics(resultats_cv_xgb)
resultats_metriques_xgb


                # ======================================== #
                # 10. COMPARAISON DES MODÈLES
                # ======================================== #

comparaison_modeles <- bind_rows(
  resultats_metriques_lm |>
    mutate(modele = "Régression linéaire"), resultats_metriques_rf |>
    mutate(modele = "Random Forest"), resultats_metriques_xgb |>
    mutate(modele = "XGBoost"))|>
  select(modele, .metric, mean,std_err)
comparaison_modeles