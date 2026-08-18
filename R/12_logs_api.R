# ==============================================================================
# 12_logs_api.R
# Projet : Prédiction des ventes pharmaceutiques
# Objectif : Journaliser les appels à l'API dans un emplacement unique
# ==============================================================================

# Chemin absolu du dossier de logs calculé une seule fois au chargement.
DOSSIER_LOGS_API <- normalizePath(
  file.path(getwd(),"outputs","logs"),
  winslash="/",
  mustWork=FALSE)

journaliser_api <- function(endpoint,statut,code,duree_ms){
  tryCatch({
    # Création du dossier si nécessaire
    dir.create(DOSSIER_LOGS_API,
      recursive=TRUE,
      showWarnings=FALSE)
    
    # Fichier unique de journalisation
    fichier_log <- file.path(DOSSIER_LOGS_API,"api_logs.csv")
    # Ligne de log
    log <- data.frame(
      date_heure=format(Sys.time(),"%Y-%m-%d %H:%M:%S"),
      endpoint=endpoint,
      statut=statut,
      code=code,
      duree_ms=round(duree_ms,2),
      stringsAsFactors=FALSE)
    
    # Création ou alimentation du fichier
    if(!file.exists(fichier_log)){
      write.table(log,
        file=fichier_log,
        sep=",",
        row.names=FALSE,
        col.names=TRUE,
        append=FALSE)
    }else{
      write.table(log,
        file=fichier_log,
        sep=",",
        row.names=FALSE,
        col.names=FALSE,
        append=TRUE)
    }
    invisible(log)
  },error=function(e){
    warning(paste("Échec de journalisation API :",
        conditionMessage(e)))
    invisible(NULL)
  })
}