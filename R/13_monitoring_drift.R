# ==============================================================================
# 13_monitoring_drift.R
# Monitoring de production et détection de drift
# Projet : Prédiction des ventes pharmaceutiques
# ==============================================================================

# ==============================================================================
# OBJECTIFS
# ==============================================================================
#
# Ce script assure :
#
# 1. La journalisation des prédictions réalisées en production.
# 2. Le monitoring technique de l'API.
# 3. Le contrôle qualité des données reçues.
# 4. La création d'une population de référence.
# 5. La détection du data drift.
# 6. La détection du prediction drift.
# 7. La détection des nouvelles modalités catégorielles.
# 8. La détection des valeurs hors plage d'apprentissage.
# 9. Le suivi de la dérive des valeurs manquantes.
# 10. L'évaluation des performances lorsque la valeur réelle devient disponible.
# 11. La génération d'un diagnostic global exploitable dans un reporting.
#
# IMPORTANT :
#
# Le monitoring ne doit jamais empêcher l'API de produire une prédiction.
# Toutes les fonctions appelées depuis l'API doivent donc pouvoir être
# encapsulées dans try(...,silent=TRUE).
#
# ==============================================================================


# ==============================================================================
# 1. CONFIGURATION GÉNÉRALE
# ==============================================================================

MONITORING_DIR <- file.path("outputs","monitoring")

MONITORING_PREDICTIONS_FILE <- file.path(
  MONITORING_DIR,
  "predictions.csv"
)

MONITORING_ALERTS_FILE <- file.path(
  MONITORING_DIR,
  "alertes_drift.csv"
)

MONITORING_DRIFT_FILE <- file.path(
  MONITORING_DIR,
  "drift_variables.csv"
)

MONITORING_API_FILE <- file.path(
  MONITORING_DIR,
  "kpi_api.csv"
)

MONITORING_PERFORMANCE_FILE <- file.path(
  MONITORING_DIR,
  "performance_reelle.csv"
)

MONITORING_REFERENCE_FILE <- file.path(
  "models",
  "monitoring_reference.rds"
)

MONITORING_LOG_API_FILE <- file.path(
  "outputs",
  "logs",
  "api_logs.csv"
)


# ==============================================================================
# 2. PARAMÈTRES DE SURVEILLANCE
# ==============================================================================

MONITORING_CONFIG <- list(
  
  # Nombre minimal d'observations de production avant calcul du drift
  min_observations=30,
  
  # Nombre de classes utilisées pour calculer le PSI numérique
  nb_bins_psi=10,
  
  # Stabilisation numérique du PSI
  epsilon_psi=1e-6,
  
  # Seuils projet du PSI
  psi_surveillance=0.10,
  psi_drift=0.25,
  
  # Écart standardisé de moyenne
  mean_shift_surveillance=0.50,
  mean_shift_drift=1.00,
  
  # Différence absolue du taux de valeurs manquantes
  missing_shift_surveillance=0.05,
  missing_shift_drift=0.10,
  
  # Part des observations hors plage de référence
  hors_plage_surveillance=0.02,
  hors_plage_drift=0.05,
  
  # Part de nouvelles modalités catégorielles
  modalites_inconnues_surveillance=0.01,
  modalites_inconnues_drift=0.05,
  
  # Latence API
  latence_p95_surveillance_ms=1000,
  latence_p95_critique_ms=3000,
  
  # Taux d'erreurs serveur
  taux_erreur_serveur_surveillance=0.01,
  taux_erreur_serveur_critique=0.05
)


# ==============================================================================
# 3. VARIABLES DU MODÈLE À SURVEILLER
# ==============================================================================

VARIABLES_NUMERIQUES_MONITORING <- c(
  "annee",
  "mois",
  "jour_mois",
  "semaine_annee",
  "trimestre",
  "weekend",
  "tendance",
  "debut_mois",
  "fin_mois",
  "ventes_lag_1",
  "ventes_lag_7",
  "ventes_lag_14",
  "ventes_lag_30",
  "moyenne_mobile_7j",
  "moyenne_mobile_30j",
  "variation_7j",
  "ecart_moyennes_mobiles",
  "volatilite_7j"
)

VARIABLES_CATEGORIELLES_MONITORING <- c(
  "jour_semaine"
)


# ==============================================================================
# 4. OUTILS INTERNES
# ==============================================================================

creer_dossiers_monitoring <- function(){
  
  dir.create(
    MONITORING_DIR,
    recursive=TRUE,
    showWarnings=FALSE
  )
  
  dir.create(
    dirname(MONITORING_REFERENCE_FILE),
    recursive=TRUE,
    showWarnings=FALSE
  )
  
  invisible(TRUE)
}


generer_request_id <- function(){
  
  timestamp <- format(
    Sys.time(),
    "%Y%m%d%H%M%OS6"
  )
  
  aleatoire <- paste(
    sample(c(0:9,letters),8,replace=TRUE),
    collapse=""
  )
  
  paste0(
    gsub("[^0-9]","",timestamp),
    "_",
    aleatoire
  )
}


normaliser_statut <- function(statut){
  
  niveaux <- c(
    "OK"=1L,
    "A_SURVEILLER"=2L,
    "DRIFT_DETECTE"=3L
  )
  
  if(!statut %in% names(niveaux)){
    return(NA_integer_)
  }
  
  unname(niveaux[statut])
}


statut_depuis_niveau <- function(niveau){
  
  if(is.na(niveau)){
    return(NA_character_)
  }
  
  if(niveau<=1){
    return("OK")
  }
  
  if(niveau==2){
    return("A_SURVEILLER")
  }
  
  "DRIFT_DETECTE"
}


statut_maximal <- function(statuts){
  
  statuts <- statuts[
    !is.na(statuts)
  ]
  
  if(length(statuts)==0){
    return(NA_character_)
  }
  
  niveaux <- vapply(
    statuts,
    normaliser_statut,
    integer(1)
  )
  
  statut_depuis_niveau(
    max(niveaux,na.rm=TRUE)
  )
}


calculer_quantile_securise <- function(x,p){
  
  x <- x[
    is.finite(x)
  ]
  
  if(length(x)==0){
    return(NA_real_)
  }
  
  as.numeric(
    stats::quantile(
      x,
      probs=p,
      na.rm=TRUE,
      names=FALSE,
      type=7
    )
  )
}


# ==============================================================================
# 5. JOURNALISATION DES PRÉDICTIONS
# ==============================================================================

journaliser_prediction <- function(
    donnees,
    prediction,
    request_id=NULL,
    modele_version="1.0"
){
  
  creer_dossiers_monitoring()
  
  if(is.null(request_id)){
    request_id <- generer_request_id()
  }
  
  donnees <- as.data.frame(
    donnees,
    stringsAsFactors=FALSE
  )
  
  if(nrow(donnees)==0){
    return(invisible(FALSE))
  }
  
  if(length(prediction)!=nrow(donnees)){
    stop("Le nombre de prédictions ne correspond pas au nombre d'observations.")
  }
  
  donnees$date_heure_prediction <- format(
    Sys.time(),
    "%Y-%m-%d %H:%M:%S",
    tz="UTC"
  )
  
  donnees$request_id <- request_id
  
  donnees$modele_version <- modele_version
  
  donnees$prediction <- as.numeric(
    prediction
  )
  
  # Ordre canonique des colonnes du monitoring
  colonnes_monitoring <- c(
    "date_heure_prediction",
    "request_id",
    "modele_version",
    "prediction",
    "date",
    "annee",
    "mois",
    "jour_mois",
    "semaine_annee",
    "trimestre",
    "jour_semaine",
    "weekend",
    "tendance",
    "debut_mois",
    "fin_mois",
    "ventes_lag_1",
    "ventes_lag_7",
    "ventes_lag_14",
    "ventes_lag_30",
    "moyenne_mobile_7j",
    "moyenne_mobile_30j",
    "variation_7j",
    "ecart_moyennes_mobiles",
    "volatilite_7j"
  )
  
  # Vérification des colonnes obligatoires
  colonnes_absentes <- setdiff(
    colonnes_monitoring,
    names(donnees)
  )
  
  if(length(colonnes_absentes)>0){
    stop(
      "Colonnes absentes pour le monitoring : ",
      paste(colonnes_absentes,collapse=", ")
    )
  }
  
  # Ordre strict et identique pour toutes les écritures
  donnees <- donnees |>
    dplyr::select(
      dplyr::all_of(colonnes_monitoring)
    )
  
  fichier_existe <- file.exists(
    MONITORING_PREDICTIONS_FILE
  )
  
  readr::write_csv(
    donnees,
    MONITORING_PREDICTIONS_FILE,
    append=fichier_existe,
    col_names=!fichier_existe
  )
  
  invisible(TRUE)
}


# ==============================================================================
# 6. LECTURE DES DONNÉES DE MONITORING
# ==============================================================================

lire_predictions_monitoring <- function(){
  
  if(!file.exists(MONITORING_PREDICTIONS_FILE)){
    return(tibble::tibble())
  }
  
  readr::read_csv(
    MONITORING_PREDICTIONS_FILE,
    show_col_types=FALSE
  )
}


lire_logs_api <- function(){
  
  if(!file.exists(MONITORING_LOG_API_FILE)){
    return(tibble::tibble())
  }
  
  readr::read_csv(
    MONITORING_LOG_API_FILE,
    show_col_types=FALSE
  )
}


# ==============================================================================
# 7. CRÉATION DE LA POPULATION DE RÉFÉRENCE
# ==============================================================================

creer_reference_monitoring <- function(
    donnees_reference,
    predictions_reference=NULL,
    version_modele="1.0"
){
  
  creer_dossiers_monitoring()
  
  donnees_reference <- as.data.frame(
    donnees_reference,
    stringsAsFactors=FALSE
  )
  
  variables_numeriques <- intersect(
    VARIABLES_NUMERIQUES_MONITORING,
    names(donnees_reference)
  )
  
  variables_categorielles <- intersect(
    VARIABLES_CATEGORIELLES_MONITORING,
    names(donnees_reference)
  )
  
  
  # ------------------------------------------------------------------------------
  # Référence numérique
  # ------------------------------------------------------------------------------
  
  reference_numerique <- lapply(
    variables_numeriques,
    function(variable){
      
      x <- suppressWarnings(
        as.numeric(donnees_reference[[variable]])
      )
      
      x_non_na <- x[
        is.finite(x)
      ]
      
      if(length(x_non_na)==0){
        return(NULL)
      }
      
      ecart_type <- stats::sd(
        x_non_na,
        na.rm=TRUE
      )
      
      quantiles <- unique(
        as.numeric(
          stats::quantile(
            x_non_na,
            probs=seq(0,1,length.out=MONITORING_CONFIG$nb_bins_psi+1),
            na.rm=TRUE,
            names=FALSE,
            type=7
          )
        )
      )
      
      list(
        variable=variable,
        n=length(x_non_na),
        moyenne=mean(x_non_na,na.rm=TRUE),
        mediane=stats::median(x_non_na,na.rm=TRUE),
        ecart_type=ecart_type,
        q01=calculer_quantile_securise(x_non_na,0.01),
        q05=calculer_quantile_securise(x_non_na,0.05),
        q25=calculer_quantile_securise(x_non_na,0.25),
        q75=calculer_quantile_securise(x_non_na,0.75),
        q95=calculer_quantile_securise(x_non_na,0.95),
        q99=calculer_quantile_securise(x_non_na,0.99),
        minimum=min(x_non_na,na.rm=TRUE),
        maximum=max(x_non_na,na.rm=TRUE),
        taux_na=mean(is.na(x)),
        quantiles_psi=quantiles
      )
    }
  )
  
  names(reference_numerique) <- variables_numeriques
  
  
  # ------------------------------------------------------------------------------
  # Référence catégorielle
  # ------------------------------------------------------------------------------
  
  reference_categorielle <- lapply(
    variables_categorielles,
    function(variable){
      
      x <- as.character(
        donnees_reference[[variable]]
      )
      
      x_normalise <- ifelse(
        is.na(x),
        "__NA__",
        x
      )
      
      frequences <- prop.table(
        table(x_normalise)
      )
      
      list(
        variable=variable,
        n=length(x),
        modalites=names(frequences),
        proportions=as.numeric(frequences),
        taux_na=mean(is.na(x))
      )
    }
  )
  
  names(reference_categorielle) <- variables_categorielles
  
  
  # ------------------------------------------------------------------------------
  # Distribution de référence des prédictions
  # ------------------------------------------------------------------------------
  
  reference_prediction <- NULL
  
  if(!is.null(predictions_reference)){
    
    predictions_reference <- as.numeric(
      predictions_reference
    )
    
    predictions_reference <- predictions_reference[
      is.finite(predictions_reference)
    ]
    
    if(length(predictions_reference)>0){
      
      reference_prediction <- list(
        n=length(predictions_reference),
        moyenne=mean(predictions_reference),
        mediane=stats::median(predictions_reference),
        ecart_type=stats::sd(predictions_reference),
        minimum=min(predictions_reference),
        maximum=max(predictions_reference),
        quantiles_psi=unique(
          as.numeric(
            stats::quantile(
              predictions_reference,
              probs=seq(0,1,length.out=MONITORING_CONFIG$nb_bins_psi+1),
              na.rm=TRUE,
              names=FALSE,
              type=7
            )
          )
        )
      )
    }
  }
  
  
  # ------------------------------------------------------------------------------
  # Objet final
  # ------------------------------------------------------------------------------
  
  reference <- list(
    date_creation=Sys.time(),
    version_modele=version_modele,
    nb_observations=nrow(donnees_reference),
    variables_numeriques=reference_numerique,
    variables_categorielles=reference_categorielle,
    prediction=reference_prediction
  )
  
  saveRDS(
    reference,
    MONITORING_REFERENCE_FILE
  )
  
  message(
    "Référence de monitoring créée : ",
    MONITORING_REFERENCE_FILE
  )
  
  invisible(reference)
}


# ==============================================================================
# 8. CHARGEMENT DE LA RÉFÉRENCE
# ==============================================================================

charger_reference_monitoring <- function(){
  
  if(!file.exists(MONITORING_REFERENCE_FILE)){
    stop(
      "La référence de monitoring est absente : ",
      MONITORING_REFERENCE_FILE
    )
  }
  
  readRDS(
    MONITORING_REFERENCE_FILE
  )
}


# ==============================================================================
# 9. CALCUL DU PSI NUMÉRIQUE
# ==============================================================================

calculer_psi_numerique <- function(
    x_production,
    reference_variable
){
  
  x_production <- suppressWarnings(
    as.numeric(x_production)
  )
  
  x_production <- x_production[
    is.finite(x_production)
  ]
  
  if(length(x_production)==0){
    return(NA_real_)
  }
  
  breaks <- reference_variable$quantiles_psi
  
  if(length(breaks)<2){
    return(NA_real_)
  }
  
  breaks[1] <- -Inf
  breaks[length(breaks)] <- Inf
  
  breaks <- unique(
    breaks
  )
  
  if(length(breaks)<2){
    return(NA_real_)
  }
  
  # Distribution de référence reconstruite à partir des quantiles
  nb_classes <- length(breaks)-1
  
  proportion_reference <- rep(
    1/nb_classes,
    nb_classes
  )
  
  classes_production <- cut(
    x_production,
    breaks=breaks,
    include.lowest=TRUE,
    right=TRUE
  )
  
  effectifs_production <- table(
    factor(
      classes_production,
      levels=levels(classes_production)
    )
  )
  
  proportion_production <- as.numeric(
    effectifs_production
  )
  
  proportion_production <- proportion_production/
    sum(proportion_production)
  
  epsilon <- MONITORING_CONFIG$epsilon_psi
  
  proportion_reference <- pmax(
    proportion_reference,
    epsilon
  )
  
  proportion_production <- pmax(
    proportion_production,
    epsilon
  )
  
  sum(
    (proportion_production-proportion_reference)*
      log(proportion_production/proportion_reference)
  )
}


# ==============================================================================
# 10. CALCUL DU PSI CATÉGORIEL
# ==============================================================================

calculer_psi_categoriel <- function(
    x_production,
    reference_variable
){
  
  x_production <- as.character(
    x_production
  )
  
  x_production <- ifelse(
    is.na(x_production),
    "__NA__",
    x_production
  )
  
  modalites_reference <- reference_variable$modalites
  
  modalites <- union(
    modalites_reference,
    unique(x_production)
  )
  
  proportion_reference <- setNames(
    rep(0,length(modalites)),
    modalites
  )
  
  proportion_reference[
    modalites_reference
  ] <- reference_variable$proportions
  
  table_production <- prop.table(
    table(x_production)
  )
  
  proportion_production <- setNames(
    rep(0,length(modalites)),
    modalites
  )
  
  proportion_production[
    names(table_production)
  ] <- as.numeric(table_production)
  
  epsilon <- MONITORING_CONFIG$epsilon_psi
  
  p_ref <- pmax(
    proportion_reference,
    epsilon
  )
  
  p_prod <- pmax(
    proportion_production,
    epsilon
  )
  
  sum(
    (p_prod-p_ref)*
      log(p_prod/p_ref)
  )
}


# ==============================================================================
# 11. INTERPRÉTATION DU PSI
# ==============================================================================

interpreter_psi <- function(psi){
  
  if(is.na(psi)){
    return(NA_character_)
  }
  
  if(psi>=MONITORING_CONFIG$psi_drift){
    return("DRIFT_DETECTE")
  }
  
  if(psi>=MONITORING_CONFIG$psi_surveillance){
    return("A_SURVEILLER")
  }
  
  "OK"
}


# ==============================================================================
# 12. DRIFT DES VARIABLES NUMÉRIQUES
# ==============================================================================

analyser_drift_numerique <- function(
    donnees_production,
    reference
){
  
  variables <- intersect(
    names(reference$variables_numeriques),
    names(donnees_production)
  )
  
  if(length(variables)==0){
    return(tibble::tibble())
  }
  
  resultats <- lapply(
    variables,
    function(variable){
      
      ref <- reference$variables_numeriques[[variable]]
      
      x <- suppressWarnings(
        as.numeric(donnees_production[[variable]])
      )
      
      x_non_na <- x[
        is.finite(x)
      ]
      
      if(length(x_non_na)==0){
        
        return(
          tibble::tibble(
            variable=variable,
            type="numerique",
            n_production=0,
            psi=NA_real_,
            moyenne_reference=ref$moyenne,
            moyenne_production=NA_real_,
            mean_shift_z=NA_real_,
            mediane_reference=ref$mediane,
            mediane_production=NA_real_,
            taux_na_reference=ref$taux_na,
            taux_na_production=mean(is.na(x)),
            ecart_taux_na=NA_real_,
            taux_hors_plage=NA_real_,
            statut="A_SURVEILLER"
          )
        )
      }
      
      psi <- calculer_psi_numerique(
        x_non_na,
        ref
      )
      
      moyenne_production <- mean(
        x_non_na,
        na.rm=TRUE
      )
      
      mediane_production <- stats::median(
        x_non_na,
        na.rm=TRUE
      )
      
      if(
        is.na(ref$ecart_type) ||
        ref$ecart_type==0
      ){
        
        mean_shift_z <- NA_real_
        
      }else{
        
        mean_shift_z <- abs(
          moyenne_production-ref$moyenne
        )/ref$ecart_type
      }
      
      taux_na_production <- mean(
        is.na(x)
      )
      
      ecart_taux_na <- abs(
        taux_na_production-ref$taux_na
      )
      
      taux_hors_plage <- mean(
        x_non_na<ref$minimum |
          x_non_na>ref$maximum
      )
      
      statut_psi <- interpreter_psi(
        psi
      )
      
      statut_mean <- dplyr::case_when(
        is.na(mean_shift_z)~"OK",
        mean_shift_z>=MONITORING_CONFIG$mean_shift_drift~"DRIFT_DETECTE",
        mean_shift_z>=MONITORING_CONFIG$mean_shift_surveillance~"A_SURVEILLER",
        TRUE~"OK"
      )
      
      statut_na <- dplyr::case_when(
        ecart_taux_na>=MONITORING_CONFIG$missing_shift_drift~"DRIFT_DETECTE",
        ecart_taux_na>=MONITORING_CONFIG$missing_shift_surveillance~"A_SURVEILLER",
        TRUE~"OK"
      )
      
      statut_hors_plage <- dplyr::case_when(
        taux_hors_plage>=MONITORING_CONFIG$hors_plage_drift~"DRIFT_DETECTE",
        taux_hors_plage>=MONITORING_CONFIG$hors_plage_surveillance~"A_SURVEILLER",
        TRUE~"OK"
      )
      
      statut <- statut_maximal(
        c(
          statut_psi,
          statut_mean,
          statut_na,
          statut_hors_plage
        )
      )
      
      tibble::tibble(
        variable=variable,
        type="numerique",
        n_production=length(x_non_na),
        psi=psi,
        moyenne_reference=ref$moyenne,
        moyenne_production=moyenne_production,
        mean_shift_z=mean_shift_z,
        mediane_reference=ref$mediane,
        mediane_production=mediane_production,
        taux_na_reference=ref$taux_na,
        taux_na_production=taux_na_production,
        ecart_taux_na=ecart_taux_na,
        taux_hors_plage=taux_hors_plage,
        statut=statut
      )
    }
  )
  
  dplyr::bind_rows(
    resultats
  ) |>
    dplyr::arrange(
      dplyr::desc(
        vapply(
          statut,
          normaliser_statut,
          integer(1)
        )
      ),
      dplyr::desc(psi)
    )
}


# ==============================================================================
# 13. DRIFT DES VARIABLES CATÉGORIELLES
# ==============================================================================

analyser_drift_categoriel <- function(
    donnees_production,
    reference
){
  
  variables <- intersect(
    names(reference$variables_categorielles),
    names(donnees_production)
  )
  
  if(length(variables)==0){
    return(tibble::tibble())
  }
  
  resultats <- lapply(
    variables,
    function(variable){
      
      ref <- reference$variables_categorielles[[variable]]
      
      x_original <- as.character(
        donnees_production[[variable]]
      )
      
      x <- ifelse(
        is.na(x_original),
        "__NA__",
        x_original
      )
      
      psi <- calculer_psi_categoriel(
        x,
        ref
      )
      
      modalites_nouvelles <- setdiff(
        unique(x),
        ref$modalites
      )
      
      taux_modalites_inconnues <- mean(
        !x %in% ref$modalites
      )
      
      taux_na_production <- mean(
        is.na(x_original)
      )
      
      ecart_taux_na <- abs(
        taux_na_production-ref$taux_na
      )
      
      statut_psi <- interpreter_psi(
        psi
      )
      
      statut_modalites <- dplyr::case_when(
        taux_modalites_inconnues>=MONITORING_CONFIG$modalites_inconnues_drift~"DRIFT_DETECTE",
        taux_modalites_inconnues>=MONITORING_CONFIG$modalites_inconnues_surveillance~"A_SURVEILLER",
        TRUE~"OK"
      )
      
      statut_na <- dplyr::case_when(
        ecart_taux_na>=MONITORING_CONFIG$missing_shift_drift~"DRIFT_DETECTE",
        ecart_taux_na>=MONITORING_CONFIG$missing_shift_surveillance~"A_SURVEILLER",
        TRUE~"OK"
      )
      
      statut <- statut_maximal(
        c(
          statut_psi,
          statut_modalites,
          statut_na
        )
      )
      
      tibble::tibble(
        variable=variable,
        type="categorielle",
        n_production=length(x),
        psi=psi,
        nb_modalites_reference=length(ref$modalites),
        nb_modalites_production=dplyr::n_distinct(x),
        nb_nouvelles_modalites=length(modalites_nouvelles),
        nouvelles_modalites=paste(
          modalites_nouvelles,
          collapse=" | "
        ),
        taux_modalites_inconnues=taux_modalites_inconnues,
        taux_na_reference=ref$taux_na,
        taux_na_production=taux_na_production,
        ecart_taux_na=ecart_taux_na,
        statut=statut
      )
    }
  )
  
  dplyr::bind_rows(
    resultats
  )
}


# ==============================================================================
# 14. PREDICTION DRIFT
# ==============================================================================

analyser_prediction_drift <- function(
    donnees_production,
    reference
){
  
  if(is.null(reference$prediction)){
    return(tibble::tibble())
  }
  
  if(!"prediction" %in% names(donnees_production)){
    return(tibble::tibble())
  }
  
  x <- as.numeric(
    donnees_production$prediction
  )
  
  x <- x[
    is.finite(x)
  ]
  
  if(length(x)==0){
    return(tibble::tibble())
  }
  
  psi <- calculer_psi_numerique(
    x,
    reference$prediction
  )
  
  ref <- reference$prediction
  
  mean_shift_z <- if(
    is.na(ref$ecart_type) ||
    ref$ecart_type==0
  ){
    NA_real_
  }else{
    abs(mean(x)-ref$moyenne)/ref$ecart_type
  }
  
  statut_psi <- interpreter_psi(
    psi
  )
  
  statut_mean <- dplyr::case_when(
    is.na(mean_shift_z)~"OK",
    mean_shift_z>=MONITORING_CONFIG$mean_shift_drift~"DRIFT_DETECTE",
    mean_shift_z>=MONITORING_CONFIG$mean_shift_surveillance~"A_SURVEILLER",
    TRUE~"OK"
  )
  
  tibble::tibble(
    variable="prediction",
    type="prediction",
    n_production=length(x),
    psi=psi,
    moyenne_reference=ref$moyenne,
    moyenne_production=mean(x),
    mediane_reference=ref$mediane,
    mediane_production=stats::median(x),
    mean_shift_z=mean_shift_z,
    statut=statut_maximal(
      c(
        statut_psi,
        statut_mean
      )
    )
  )
}


# ==============================================================================
# 15. CONTRÔLE QUALITÉ DES DONNÉES DE PRODUCTION
# ==============================================================================

controler_qualite_production <- function(
    donnees_production
){
  
  nb_lignes <- nrow(
    donnees_production
  )
  
  nb_colonnes <- ncol(
    donnees_production
  )
  
  nb_na <- sum(
    is.na(donnees_production)
  )
  
  taux_na <- if(
    nb_lignes*nb_colonnes>0
  ){
    nb_na/(nb_lignes*nb_colonnes)
  }else{
    NA_real_
  }
  
  nb_doublons <- sum(
    duplicated(donnees_production)
  )
  
  variables_attendues <- c(
    VARIABLES_NUMERIQUES_MONITORING,
    VARIABLES_CATEGORIELLES_MONITORING
  )
  
  variables_manquantes <- setdiff(
    variables_attendues,
    names(donnees_production)
  )
  
  tibble::tibble(
    nb_lignes=nb_lignes,
    nb_colonnes=nb_colonnes,
    nb_valeurs_manquantes=nb_na,
    taux_valeurs_manquantes=taux_na,
    nb_doublons=nb_doublons,
    nb_variables_manquantes=length(variables_manquantes),
    variables_manquantes=paste(
      variables_manquantes,
      collapse=" | "
    )
  )
}


# ==============================================================================
# 16. MONITORING TECHNIQUE DE L'API
# ==============================================================================

calculer_kpi_api <- function(){
  
  logs <- lire_logs_api()
  
  if(nrow(logs)==0){
    
    return(
      tibble::tibble(
        nb_appels=0,
        nb_succes=0,
        nb_erreurs_client=0,
        nb_erreurs_serveur=0,
        taux_succes=NA_real_,
        taux_erreur_client=NA_real_,
        taux_erreur_serveur=NA_real_,
        latence_moyenne_ms=NA_real_,
        latence_p50_ms=NA_real_,
        latence_p95_ms=NA_real_,
        latence_p99_ms=NA_real_,
        statut="A_SURVEILLER"
      )
    )
  }
  
  codes <- as.numeric(
    logs$code
  )
  
  durees <- as.numeric(
    logs$duree_ms
  )
  
  nb_appels <- nrow(
    logs
  )
  
  nb_succes <- sum(
    codes>=200 &
      codes<300,
    na.rm=TRUE
  )
  
  nb_erreurs_client <- sum(
    codes>=400 &
      codes<500,
    na.rm=TRUE
  )
  
  nb_erreurs_serveur <- sum(
    codes>=500,
    na.rm=TRUE
  )
  
  taux_succes <- nb_succes/nb_appels
  
  taux_erreur_client <- nb_erreurs_client/nb_appels
  
  taux_erreur_serveur <- nb_erreurs_serveur/nb_appels
  
  latence_moyenne_ms <- mean(
    durees,
    na.rm=TRUE
  )
  
  latence_p50_ms <- calculer_quantile_securise(
    durees,
    0.50
  )
  
  latence_p95_ms <- calculer_quantile_securise(
    durees,
    0.95
  )
  
  latence_p99_ms <- calculer_quantile_securise(
    durees,
    0.99
  )
  
  statut_latence <- dplyr::case_when(
    latence_p95_ms>=MONITORING_CONFIG$latence_p95_critique_ms~"DRIFT_DETECTE",
    latence_p95_ms>=MONITORING_CONFIG$latence_p95_surveillance_ms~"A_SURVEILLER",
    TRUE~"OK"
  )
  
  statut_erreurs <- dplyr::case_when(
    taux_erreur_serveur>=MONITORING_CONFIG$taux_erreur_serveur_critique~"DRIFT_DETECTE",
    taux_erreur_serveur>=MONITORING_CONFIG$taux_erreur_serveur_surveillance~"A_SURVEILLER",
    TRUE~"OK"
  )
  
  statut <- statut_maximal(
    c(
      statut_latence,
      statut_erreurs
    )
  )
  
  tibble::tibble(
    nb_appels=nb_appels,
    nb_succes=nb_succes,
    nb_erreurs_client=nb_erreurs_client,
    nb_erreurs_serveur=nb_erreurs_serveur,
    taux_succes=taux_succes,
    taux_erreur_client=taux_erreur_client,
    taux_erreur_serveur=taux_erreur_serveur,
    latence_moyenne_ms=latence_moyenne_ms,
    latence_p50_ms=latence_p50_ms,
    latence_p95_ms=latence_p95_ms,
    latence_p99_ms=latence_p99_ms,
    statut=statut
  )
}


# ==============================================================================
# 17. RÉPARTITION DES CODES HTTP
# ==============================================================================

calculer_repartition_codes_http <- function(){
  
  logs <- lire_logs_api()
  
  if(nrow(logs)==0){
    return(tibble::tibble())
  }
  
  logs |>
    dplyr::count(
      code,
      name="nombre"
    ) |>
    dplyr::mutate(
      pourcentage=nombre/sum(nombre)
    ) |>
    dplyr::arrange(
      dplyr::desc(nombre)
    )
}


# ==============================================================================
# 18. ÉVOLUTION DE L'ACTIVITÉ API
# ==============================================================================

calculer_activite_api <- function(){
  
  logs <- lire_logs_api()
  
  if(nrow(logs)==0){
    return(tibble::tibble())
  }
  
  logs |>
    dplyr::mutate(
      date=as.Date(date_heure)
    ) |>
    dplyr::count(
      date,
      code,
      name="nb_appels"
    ) |>
    dplyr::arrange(
      date,
      code
    )
}


# ==============================================================================
# 19. PERFORMANCE RÉELLE DU MODÈLE
# ==============================================================================

evaluer_performance_reelle <- function(
    donnees,
    colonne_reelle,
    colonne_prediction="prediction"
){
  
  if(!colonne_reelle %in% names(donnees)){
    stop("La colonne réelle est absente des données.")
  }
  
  if(!colonne_prediction %in% names(donnees)){
    stop("La colonne de prédiction est absente des données.")
  }
  
  reel <- as.numeric(
    donnees[[colonne_reelle]]
  )
  
  prediction <- as.numeric(
    donnees[[colonne_prediction]]
  )
  
  valide <- is.finite(reel) &
    is.finite(prediction)
  
  reel <- reel[
    valide
  ]
  
  prediction <- prediction[
    valide
  ]
  
  if(length(reel)==0){
    stop("Aucune observation exploitable pour évaluer la performance.")
  }
  
  erreur <- prediction-reel
  
  mae <- mean(
    abs(erreur)
  )
  
  rmse <- sqrt(
    mean(erreur^2)
  )
  
  biais <- mean(
    erreur
  )
  
  wape <- if(
    sum(abs(reel))>0
  ){
    sum(abs(erreur))/sum(abs(reel))
  }else{
    NA_real_
  }
  
  indices_mape <- reel!=0
  
  mape <- if(
    any(indices_mape)
  ){
    mean(
      abs(
        erreur[indices_mape]/
          reel[indices_mape]
      )
    )
  }else{
    NA_real_
  }
  
  resultat <- tibble::tibble(
    date_calcul=Sys.Date(),
    nb_observations=length(reel),
    mae=mae,
    rmse=rmse,
    mape=mape,
    wape=wape,
    biais=biais
  )
  
  fichier_existe <- file.exists(
    MONITORING_PERFORMANCE_FILE
  )
  
  readr::write_csv(
    resultat,
    MONITORING_PERFORMANCE_FILE,
    append=fichier_existe,
    col_names=!fichier_existe
  )
  
  resultat
}


# ==============================================================================
# 20. ANALYSE COMPLÈTE DU DRIFT
# ==============================================================================

analyser_drift_complet <- function(
    fenetre_n=NULL,
    exporter=TRUE
){
  
  reference <- charger_reference_monitoring()
  
  production <- lire_predictions_monitoring()
  
  if(nrow(production)==0){
    
    return(
      list(
        statut_global="DONNEES_INSUFFISANTES",
        message="Aucune prédiction de production disponible."
      )
    )
  }
  
  if(!is.null(fenetre_n)){
    
    production <- utils::tail(
      production,
      fenetre_n
    )
  }
  
  if(
    nrow(production)<
    MONITORING_CONFIG$min_observations
  ){
    
    return(
      list(
        statut_global="DONNEES_INSUFFISANTES",
        nb_observations=nrow(production),
        minimum_requis=MONITORING_CONFIG$min_observations,
        message="Nombre d'observations insuffisant pour conclure sur le drift."
      )
    )
  }
  
  qualite <- controler_qualite_production(
    production
  )
  
  drift_numerique <- analyser_drift_numerique(
    production,
    reference
  )
  
  drift_categoriel <- analyser_drift_categoriel(
    production,
    reference
  )
  
  prediction_drift <- analyser_prediction_drift(
    production,
    reference
  )
  
  drift_variables <- dplyr::bind_rows(
    drift_numerique,
    drift_categoriel,
    prediction_drift
  )
  
  statut_global <- statut_maximal(
    drift_variables$statut
  )
  
  nb_ok <- sum(
    drift_variables$statut=="OK",
    na.rm=TRUE
  )
  
  nb_surveillance <- sum(
    drift_variables$statut=="A_SURVEILLER",
    na.rm=TRUE
  )
  
  nb_drift <- sum(
    drift_variables$statut=="DRIFT_DETECTE",
    na.rm=TRUE
  )
  
  synthese <- tibble::tibble(
    date_analyse=Sys.time(),
    version_modele=reference$version_modele,
    nb_observations_production=nrow(production),
    nb_variables_analysees=nrow(drift_variables),
    nb_variables_ok=nb_ok,
    nb_variables_a_surveiller=nb_surveillance,
    nb_variables_drift=nb_drift,
    statut_global=statut_global
  )
  
  if(exporter){
    
    creer_dossiers_monitoring()
    
    readr::write_csv(
      drift_variables,
      MONITORING_DRIFT_FILE
    )
    
    readr::write_csv(
      synthese,
      file.path(
        MONITORING_DIR,
        "synthese_drift.csv"
      )
    )
    
    fichier_alertes_existe <- file.exists(
      MONITORING_ALERTS_FILE
    )
    
    alertes <- drift_variables |>
      dplyr::filter(
        statut!="OK"
      ) |>
      dplyr::mutate(
        date_alerte=Sys.time()
      ) |>
      dplyr::relocate(
        date_alerte
      )
    
    if(nrow(alertes)>0){
      
      readr::write_csv(
        alertes,
        MONITORING_ALERTS_FILE,
        append=fichier_alertes_existe,
        col_names=!fichier_alertes_existe
      )
    }
  }
  
  list(
    synthese=synthese,
    qualite=qualite,
    drift_variables=drift_variables
  )
}


# ==============================================================================
# 21. TABLEAU DE BORD DE MONITORING
# ==============================================================================

generer_tableau_bord_monitoring <- function(
    fenetre_n=NULL
){
  
  kpi_api <- calculer_kpi_api()
  
  drift <- tryCatch(
    analyser_drift_complet(
      fenetre_n=fenetre_n,
      exporter=TRUE
    ),
    error=function(e){
      list(
        statut_global="NON_DISPONIBLE",
        message=conditionMessage(e)
      )
    }
  )
  
  list(
    date_generation=Sys.time(),
    api=kpi_api,
    drift=drift
  )
}


# ==============================================================================
# 22. EXPORT DES KPI API
# ==============================================================================

exporter_kpi_api <- function(){
  
  creer_dossiers_monitoring()
  
  kpi <- calculer_kpi_api()
  
  readr::write_csv(
    kpi,
    MONITORING_API_FILE
  )
  
  invisible(kpi)
}


# ==============================================================================
# FIN DU SCRIPT
# ==============================================================================