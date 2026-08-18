# ==============================================================================
    # 11_fonction_prediction.R
    # Projet : Prédiction des ventes pharmaceutiques
    # Objectif : Fournir une fonction unique et sécurisée pour les prédictions
# ==============================================================================

source("R/00_packages.R")
source("R/01_configuration.R")

# -------------------------------------------
      # Chargement du modèle entraîné
# -------------------------------------------

modele_production <- readRDS(file.path(DIR_MODELS, "modele_ventes_pharma_lm.rds"))


# ==============================================================================
# Validation et prédiction
# ==============================================================================

# ==============================================================================
# Fonction de prédiction sécurisée
# ==============================================================================

predire_ventes <- function(nouvelles_donnees){
  
  # Vérification du type d'entrée
  if(!is.data.frame(nouvelles_donnees)){
    stop("Les données fournies doivent être un data.frame.")
  }
  
  # Colonnes obligatoires
  colonnes_requises <- c(
    "date","annee","mois","jour_mois","semaine_annee","trimestre",
    "jour_semaine","weekend","tendance","debut_mois","fin_mois",
    "ventes_lag_1","ventes_lag_7","ventes_lag_14","ventes_lag_30",
    "moyenne_mobile_7j","moyenne_mobile_30j","variation_7j",
    "ecart_moyennes_mobiles","volatilite_7j"
  )
  
  # Vérification des colonnes manquantes
  colonnes_manquantes <- setdiff(colonnes_requises,names(nouvelles_donnees))
  
  if(length(colonnes_manquantes)>0){
    stop(
      paste(
        "Colonnes manquantes :",
        paste(colonnes_manquantes,collapse=", ")
      )
    )
  }
  
  # Conservation uniquement des colonnes nécessaires
  nouvelles_donnees <- nouvelles_donnees[,colonnes_requises]
  
  # Vérification des valeurs manquantes
  if(anyNA(nouvelles_donnees)){
    stop("Les données contiennent des valeurs manquantes.")
  }
  
  # Conversion et contrôle de la date
  nouvelles_donnees$date <- as.Date(nouvelles_donnees$date)
  
  if(anyNA(nouvelles_donnees$date)){
    stop("La variable date doit être une date valide.")
  }
  
  # Vérification du mois
  if(any(nouvelles_donnees$mois<1 | nouvelles_donnees$mois>12)){
    stop("La variable mois doit être comprise entre 1 et 12.")
  }
  
  # Vérification du jour du mois
  if(any(nouvelles_donnees$jour_mois<1 | nouvelles_donnees$jour_mois>31)){
    stop("La variable jour_mois doit être comprise entre 1 et 31.")
  }
  
  # Vérification du trimestre
  if(any(nouvelles_donnees$trimestre<1 | nouvelles_donnees$trimestre>4)){
    stop("La variable trimestre doit être comprise entre 1 et 4.")
  }
  
  # Vérification des variables binaires
  variables_binaires <- c("weekend","debut_mois","fin_mois")
  
  for(variable in variables_binaires){
    if(any(!nouvelles_donnees[[variable]] %in% c(0,1))){
      stop(paste(variable,"doit contenir uniquement 0 ou 1."))
    }
  }
  
  # Vérification du jour de semaine
  jours_valides <- c(
    "lundi","mardi","mercredi","jeudi",
    "vendredi","samedi","dimanche"
  )
  
  if(any(!nouvelles_donnees$jour_semaine %in% jours_valides)){
    stop("La variable jour_semaine contient une valeur invalide.")
  }
  
  # Vérification des variables de ventes
  variables_ventes <- c(
    "ventes_lag_1","ventes_lag_7","ventes_lag_14","ventes_lag_30",
    "moyenne_mobile_7j","moyenne_mobile_30j",
    "volatilite_7j"
  )
  
  if(any(nouvelles_donnees[variables_ventes]<0)){
    stop("Les variables historiques de ventes ne peuvent pas être négatives.")
  }
  
  # Prédiction
  prediction <- predict(
    modele_production,
    new_data=nouvelles_donnees
  )
  
  return(prediction)
}