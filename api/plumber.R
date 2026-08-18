# ==============================================================================
# API Plumber - Prédiction des ventes pharmaceutiques
# ==============================================================================


# ------------------------------------------------------------------------------
# 1. Initialisation du projet
# ------------------------------------------------------------------------------

# Lorsque Plumber lit ce fichier depuis le dossier api/,
# ".." correspond à la racine du projet.
PROJECT_ROOT <- normalizePath("..",winslash="/",mustWork=TRUE)
setwd(PROJECT_ROOT)
source("R/11_fonction_prediction.R")
source("R/12_logs_api.R")

# ------------------------------------------------------------------------------
# 2. Sécurité : récupération de la clé API
# ------------------------------------------------------------------------------

API_KEY <- Sys.getenv("API_KEY")
if(API_KEY==""){
  stop("La variable d'environnement API_KEY est absente.")
}

# ==============================================================================
# 3. ENDPOINT DE SANTÉ
# ==============================================================================
#* Vérifie que l'API fonctionne
#* @get /health
#* @serializer json
function(){
  list(
    status="ok",
    service="prediction-ventes-pharma")
}

# ==============================================================================
# 4. ENDPOINT DE PRÉDICTION
# ==============================================================================

# Codes HTTP utilisés :
# 200 : prédiction réalisée avec succès
# 400 : données envoyées invalides
# 401 : clé API absente ou invalide
# 500 : erreur serveur inattendue

#* Prédit les ventes pharmaceutiques
#* @param body:object Données nécessaires à la prédiction
#* @post /predict
#* @parser json
#* @serializer json
function(req,res,body){
  # Taille maximale autorisée pour le corps de la requête : 100 Ko
  taille_max <- 100 * 1024
  
  if(!is.null(req$HTTP_CONTENT_LENGTH)){
    taille_requete <- suppressWarnings(as.numeric(req$HTTP_CONTENT_LENGTH))
    
    if(!is.na(taille_requete) && taille_requete > taille_max){
      res$status <- 413
      
      return(list(
        status="error",
        code=413,
        message="Requête trop volumineuse."
      ))
    }
  }
  
  # Heure de début de la requête.
  debut <- Sys.time()
  # ------------------------------------------------------------------------------
  # Vérification de l'authentification
  # ------------------------------------------------------------------------------
  
  cle_recue <- req$HTTP_X_API_KEY
  if(is.null(cle_recue) || !identical(cle_recue,API_KEY)){
    res$status <- 401
    duree_ms <- as.numeric(difftime(Sys.time(),debut,units="secs"))*1000
    journaliser_api(
      endpoint="/predict",
      statut="error",
      code=401,
      duree_ms=duree_ms)
    return(list(
      status="error",
      code=401,
      message="Clé API absente ou invalide."))
    
  }
  
  
  # ------------------------------------------------------------------------------
  # Traitement de la requête
  # ------------------------------------------------------------------------------
  
  resultat <- tryCatch({
    # Vérification de la présence du JSON.
    if(missing(body) || is.null(body)){
      stop("Le corps JSON de la requête est obligatoire.")
    }
    
    # Conversion du JSON reçu en data.frame.
    donnees <- as.data.frame(body,stringsAsFactors=FALSE)
    # Conversion explicite de la date.
    if("date" %in% names(donnees)){
      donnees$date <- as.Date(donnees$date)
    }
    # Appel de la fonction métier de prédiction.
    prediction <- predire_ventes(donnees)
    
    
    # ------------------------------------------------------------------------------
    # Succès : HTTP 200
    # ------------------------------------------------------------------------------
    
    res$status <- 200
    duree_ms <- as.numeric(difftime(Sys.time(),debut,units="secs"))*1000
    journaliser_api(
      endpoint="/predict",
      statut="success",
      code=200,
      duree_ms=duree_ms)
    
    list(status="success",code=200,
      prediction=as.numeric(prediction$.pred))
  },error=function(e){
    
    
    # ------------------------------------------------------------------------------
    # Erreur fonctionnelle : HTTP 400
    # ------------------------------------------------------------------------------
    
    res$status <- 400
    duree_ms <- as.numeric(difftime(Sys.time(),debut,units="secs"))*1000
    
    # IMPORTANT :
    # une erreur de log ne doit jamais remplacer l'erreur métier originale.
    try(
      journaliser_api(
        endpoint="/predict",
        statut="error",
        code=400,
        duree_ms=duree_ms),silent=TRUE)
    list(
      status="error",
      code=400,
      message="Données invalides ou erreur de prédiction.")
  })
  return(resultat)
}
# --------TESTER DANS LE BODY ----------
 # test_data |>
 #   slice(1) |>
 #   jsonlite::toJSON(
 #     dataframe = "rows",
 #     auto_unbox = TRUE,
 #     pretty = TRUE
 #   )