# ==============================================================================
              # 09_sauvegarde_modele.R
              # Projet : Prédiction des ventes pharmaceutiques
              # Objectif : Sauvegarder le modèle final validé 
              # pour son utilisation en production
# ==============================================================================
source("R/08_evaluation_finale.R")

            # =================================================
            # 1. SAUVEGARDE DU WORKFLOW FINAL
            # =================================================

# On sauvegarde le workflow COMPLET :
# - la recipe de prétraitement
# - les transformations des variables
# - le modèle de régression linéaire entraîné

# Cela évite de devoir reconstruire manuellement le prétraitement lors des futures prédictions.

saveRDS(modele_lm_final,file = file.path(DIR_MODELS, "modele_ventes_pharma_lm.rds"))

# ================================================
# 2. VÉRIFICATION DE LA SAUVEGARDE
# ================================================
file.exists(file.path(DIR_MODELS, "modele_ventes_pharma_lm.rds"))