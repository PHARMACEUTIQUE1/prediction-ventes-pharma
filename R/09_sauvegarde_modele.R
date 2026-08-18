# ==============================================================================
# 09_sauvegarde_modele.R
# Projet : Prédiction des ventes pharmaceutiques
# Objectif :
# - Sauvegarder le modèle final validé
# - Construire et sauvegarder la référence de monitoring
# - Préparer la surveillance du drift en production
# ==============================================================================

source("R/08_evaluation_finale.R")
source("R/13_monitoring_drift.R")


# ==============================================================================
# 1. CRÉATION DU DOSSIER MODELS
# ==============================================================================

dir.create(
  DIR_MODELS,
  recursive=TRUE,
  showWarnings=FALSE
)


# ==============================================================================
# 2. SAUVEGARDE DU WORKFLOW FINAL
# ==============================================================================

# Le workflow final contient :
# - la recipe de prétraitement
# - les transformations des variables
# - le modèle de régression linéaire entraîné
#
# Le sauvegarder sous forme de workflow complet permet de garantir
# exactement les mêmes transformations en production que pendant
# l'entraînement.

CHEMIN_MODELE <- file.path(
  DIR_MODELS,
  "modele_ventes_pharma_lm.rds"
)

saveRDS(
  modele_lm_final,
  CHEMIN_MODELE
)

if(!file.exists(CHEMIN_MODELE)){
  stop("Échec de la sauvegarde du modèle final.")
}

message(
  "Modèle final sauvegardé : ",
  CHEMIN_MODELE
)


# ==============================================================================
# 3. PRÉPARATION DES DONNÉES DE RÉFÉRENCE DU MONITORING
# ==============================================================================

# IMPORTANT :
# La référence du drift est construite exclusivement à partir de train_data.
#
# Le jeu test_data reste un jeu indépendant destiné à l'évaluation finale.
# Il ne doit pas servir de population de référence du monitoring.
#
# train_data représente donc le comportement attendu des variables lorsque
# le modèle a été construit.

donnees_reference_monitoring <- train_data


# ==============================================================================
# 4. PRÉDICTIONS DE RÉFÉRENCE
# ==============================================================================

# On calcule également les prédictions du modèle sur train_data.
#
# Ces prédictions permettront ensuite de détecter un "prediction drift",
# c'est-à-dire une modification importante de la distribution des sorties
# du modèle en production.

predictions_reference_monitoring <- predict(
  modele_lm_final,
  new_data=donnees_reference_monitoring
)


# ==============================================================================
# 5. CONTRÔLE DES PRÉDICTIONS DE RÉFÉRENCE
# ==============================================================================

if(!".pred" %in% names(predictions_reference_monitoring)){
  stop("La colonne .pred est absente des prédictions de référence.")
}

if(
  nrow(predictions_reference_monitoring)!=
  nrow(donnees_reference_monitoring)
){
  stop("Incohérence entre le nombre d'observations de référence ",
    "et le nombre de prédictions.")
}


# ==============================================================================
# 6. CRÉATION DE LA RÉFÉRENCE DE MONITORING
# ==============================================================================

# La fonction creer_reference_monitoring() calcule notamment :
#
# - distributions des variables numériques
# - moyennes et médianes
# - écarts-types
# - quantiles
# - bornes min/max
# - taux de valeurs manquantes
# - modalités catégorielles
# - proportions des modalités
# - distribution des prédictions
#
# Cet objet servira de "baseline" pour comparer les futures données
# reçues par l'API.

reference_monitoring <- creer_reference_monitoring(
  donnees_reference=donnees_reference_monitoring,
  predictions_reference=predictions_reference_monitoring$.pred,
  version_modele="1.0")


# ==============================================================================
# 7. VÉRIFICATION DE LA RÉFÉRENCE
# ==============================================================================

CHEMIN_REFERENCE <- file.path(DIR_MODELS,"monitoring_reference.rds")
if(!file.exists(CHEMIN_REFERENCE)){
  stop("La référence de monitoring n'a pas été créée.")
}

message("Référence de monitoring sauvegardée : ",CHEMIN_REFERENCE)

# ==============================================================================
# 8. VALIDATION DU CONTENU DE LA RÉFÉRENCE
# ==============================================================================

reference_verification <- readRDS(CHEMIN_REFERENCE)
if(is.null(reference_verification$version_modele)){
  stop("La version du modèle est absente de la référence.")
}

if(is.null(reference_verification$nb_observations)){
  stop("Le nombre d'observations de référence est absent.")
}

if(is.null(reference_verification$variables_numeriques)){
  stop("La référence des variables numériques est absente.")
}

if(is.null(reference_verification$variables_categorielles)){
  stop("La référence des variables catégorielles est absente.")
}
message("Référence validée : ",reference_verification$nb_observations," observations.")

# ==============================================================================
# 9. INVENTAIRE DES ARTEFACTS DE PRODUCTION
# ==============================================================================

artefacts_production <- tibble::tibble(artefact=c("Modèle final","Référence monitoring"),
  fichier=c(CHEMIN_MODELE,CHEMIN_REFERENCE),
  existe=c(file.exists(CHEMIN_MODELE),file.exists(CHEMIN_REFERENCE)),
  taille_octets=c(
    file.info(CHEMIN_MODELE)$size,
    file.info(CHEMIN_REFERENCE)$size))
print(artefacts_production)


# ==============================================================================
# 10. CONTRÔLE FINAL
# ==============================================================================

if(!all(artefacts_production$existe)){
  stop("Un ou plusieurs artefacts de production sont absents.")
}
message("==============================================================")
message("Préparation des artefacts de production terminée avec succès.")
message("Modèle : ",CHEMIN_MODELE)
message("Monitoring : ",CHEMIN_REFERENCE)
message("==============================================================")