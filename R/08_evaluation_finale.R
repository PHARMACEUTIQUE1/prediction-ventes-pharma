# ==============================================================================
# 08_evaluation_finale.R
# Projet : Prédiction des ventes pharmaceutiques
# Objectif : Évaluer le modèle sélectionné sur le jeu de test final
# ==============================================================================

source("R/07_tuning.R")

            # ===========================================
                      # 1. MODÈLE RETENU
            # ===========================================

# La régression linéaire a obtenu la meilleure RMSE moyenne lors de la validation croisée temporelle.
# Elle est donc sélectionnée AVANT toute consultation du jeu de test.
# Le jeu test_data représente les 20 % de données les plus récentes et n'a encore jamais été utilisé pour entraîner ou sélectionner le modèle.

            # ================================================
                # 2. ENTRAÎNEMENT SUR L'ENSEMBLE DU TRAIN
            # ================================================

# Maintenant que le modèle est sélectionné, on l'entraîne sur toutesles données disponibles dans train_data.

modele_lm_final <- fit(workflow_lm,data = train_data)

            # ====================================================
                  # 3. PRÉDICTIONS SUR LE TEST FINAL
            # ====================================================

predictions_test_lm <- predict(modele_lm_final,new_data = test_data) |>
  bind_cols(test_data |>
      select(date,analgesiques_antipyretiques_anilides))

# ============================================
# 4. PERFORMANCES SUR LE TEST FINAL
# =============================================

metriques_test_lm <- predictions_test_lm |>
  metrics(truth = analgesiques_antipyretiques_anilides,estimate = .pred)
metriques_test_lm

# MAE = 9.49 → erreur moyenne d'environ 9,5 unités de vente.
# RMSE = 12,4 → les grosses erreurs restent autour de 12,4 unités.
# R² = 0.392 → le modèle explique environ 39,2 % de la variabilité sur le test final.