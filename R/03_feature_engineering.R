# ==============================================================================
          # 03_feature_engineering.R
          # Projet : Prédiction des ventes pharmaceutiques
          # Objectif : Créer les variables explicatives utiles à la modélisation
# ==============================================================================


# Chargement des scripts précédents
source("R/00_packages.R")
source("R/01_configuration.R")
source("R/02_preparation_donnees.R")


# Tri chronologique obligatoire
ventes_daily <- ventes_daily |>
  arrange(date)

# Variables explicatives temporelles générales

ventes_daily <- ventes_daily |>
  mutate(tendance = row_number(), # Position chronologique depuis le début de la série
    debut_mois = if_else(jour_mois <= 7, 1L, 0L),
    fin_mois = if_else(jour_mois >= 25, 1L, 0L)) # Indicateurs calendaires

# -------------------------------------------------------
      # Variables retardées : historique des ventes
# -------------------------------------------------------

ventes_daily <- ventes_daily |>
  mutate(ventes_lag_1 = lag(analgesiques_antipyretiques_anilides, 1),
         ventes_lag_7 = lag(analgesiques_antipyretiques_anilides, 7),
         ventes_lag_14 = lag(analgesiques_antipyretiques_anilides, 14),
         ventes_lag_30 = lag(analgesiques_antipyretiques_anilides, 30))

# -----------------------------------------
    # Moyennes mobiles des ventes
# -----------------------------------------

# Pour prédire le jour J, seules les ventes connues jusqu'à J-1 doivent être utilisées. La valeur du jour J est donc exclue.

ventes_daily <- ventes_daily |>
  mutate(
    # Moyenne des ventes de J-7 à J-1
    moyenne_mobile_7j = slider::slide_dbl(
      lag(analgesiques_antipyretiques_anilides, 1),
      mean, .before = 6, .complete = TRUE),
    # Moyenne des ventes de J-30 à J-1
    moyenne_mobile_30j = slider::slide_dbl(
      lag(analgesiques_antipyretiques_anilides, 1),
      mean, .before = 29, .complete = TRUE)
  )

# ventes_daily |>
#   select(date,analgesiques_antipyretiques_anilides,
#     ventes_lag_1,ventes_lag_7,
#     moyenne_mobile_7j,moyenne_mobile_30j) |>
#   head(35

# --------------------------------------------------------
             # Variation et volatilité des ventes
# --------------------------------------------------------

ventes_daily <- ventes_daily |>
         # les ventes récentes sont-elles plus fortes qu'il y a une semaine ?
  mutate(variation_7j = ventes_lag_1 - ventes_lag_7, # Évolution entre J-1 et J-7 
         # la tendance récente accélère-t-elle ou ralentit-elle ?
    ecart_moyennes_mobiles = moyenne_mobile_7j - moyenne_mobile_30j, # Écart entre la tendance courte et la tendance plus longue
    
    # Volatilité des 7 jours précédents : les ventes ont-elles été stables ou très variables récemment ?
    volatilite_7j = slider::slide_dbl(
      lag(analgesiques_antipyretiques_anilides, 1),
      sd, .before = 6, .complete = TRUE))

# ------------------------------------------------------------------------------
# Sélection des variables utiles à la modélisation
# ------------------------------------------------------------------------------

donnees_ml <- ventes_daily |>
  select(date,
        analgesiques_antipyretiques_anilides, # Variable cible
    # Variables calendaires
    annee,
    mois,
    jour_mois,
    semaine_annee,
    trimestre,
    jour_semaine,
    weekend,
    # Variables de tendance
    tendance,
    debut_mois,
    fin_mois,
    # Historique des ventes
    ventes_lag_1,
    ventes_lag_7,
    ventes_lag_14,
    ventes_lag_30,
    # Moyennes mobiles
    moyenne_mobile_7j,
    moyenne_mobile_30j,
    # Dynamique récente
    variation_7j,
    ecart_moyennes_mobiles,
    volatilite_7j)

# ---------------------------------------------------------
       # Suppression des lignes non exploitables
# ---------------------------------------------------------

# Les premières lignes contiennent naturellement des NA,
# car il n'existe pas encore assez d'historique pour calculer les lags et moyennes mobiles.

donnees_ml <- donnees_ml |>
  drop_na()

#dim(donnees_ml)
#glimpse(donnees_ml)