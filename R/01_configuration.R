# ======================================================================
          # 01_configuration.R
          # Projet : Prédiction des ventes pharmaceutiques
          # Objectif : Centraliser les paramètres généraux du projet
# =========================================================================

# -------------------------------------
      # Chemins des dossiers
# -------------------------------------

DIR_RAW       <- "data/raw"
DIR_INTERIM   <- "data/interim"
DIR_PROCESSED <- "data/processed"
DIR_MODELS    <- "models"
DIR_FIGURES   <- "outputs/figures"
DIR_TABLES    <- "outputs/tables"
DIR_METRICS   <- "outputs/metrics"
DIR_LOGS <- "outputs/logs"


# ----------------------------------------
      # Paramètres de reproductibilité
# ----------------------------------------

SEED <- 1234
set.seed(SEED)


# ---------------------------------------------
      # Paramètres généraux de modélisation
# --------------------------------------------

# Proportion des données réservée à l'apprentissage
PROP_TRAIN <- 0.80


# ----------------------------------------------------
          # Contrôle des dossiers nécessaires
# ----------------------------------------------------

dirs <- c(
  DIR_RAW,DIR_INTERIM,DIR_PROCESSED,DIR_MODELS,
  DIR_FIGURES,DIR_TABLES,DIR_METRICS,DIR_LOGS
)

for (dir in dirs) {
  if (!dir.exists(dir)) {
    dir.create(dir, recursive = TRUE)
  }
}