# ==============================================================================
# test-api.R
# Projet : Prédiction des ventes pharmaceutiques
# Objectif : Tester automatiquement les principaux endpoints de l'API
# ==============================================================================

URL_API <- "http://127.0.0.1:8000"

API_KEY_TEST <- Sys.getenv("API_KEY")

if(API_KEY_TEST==""){
  stop("La variable d'environnement API_KEY est absente.")
}

# ==============================================================================
# Données valides utilisées pour les tests
# ==============================================================================

donnees_valides <- list(
  date="2018-08-19",
  annee=2018,
  mois=8,
  jour_mois=19,
  semaine_annee=33,
  trimestre=3,
  jour_semaine="dimanche",
  weekend=1,
  tendance=1691,
  debut_mois=0,
  fin_mois=0,
  ventes_lag_1=32.1,
  ventes_lag_7=16,
  ventes_lag_14=13,
  ventes_lag_30=35.2,
  moyenne_mobile_7j=23.7071,
  moyenne_mobile_30j=20.6279,
  variation_7j=16.1,
  ecart_moyennes_mobiles=3.0792,
  volatilite_7j=7.6743
)

# ==============================================================================
# TEST 1 : endpoint /health
# ==============================================================================

testthat::test_that("/health retourne HTTP 200",{
  
  reponse <- httr2::request(
    paste0(URL_API,"/health")
  ) |>
    httr2::req_perform()
  
  testthat::expect_equal(
    httr2::resp_status(reponse),
    200
  )
  
  contenu <- httr2::resp_body_json(reponse,simplifyVector=TRUE)
  
  testthat::expect_equal(
    contenu$status,
    "ok"
  )
  
})

# ==============================================================================
# TEST 2 : clé API invalide
# ==============================================================================

testthat::test_that("/predict refuse une mauvaise clé API",{
  
  reponse <- httr2::request(
    paste0(URL_API,"/predict")
  ) |>
    httr2::req_headers(
      `X-API-Key`="FAUSSE_CLE"
    ) |>
    httr2::req_body_json(
      list(body=donnees_valides)
    ) |>
    httr2::req_error(is_error=function(resp) FALSE) |>
    httr2::req_perform()
  
  testthat::expect_equal(
    httr2::resp_status(reponse),
    401
  )
  
  contenu <- httr2::resp_body_json(reponse,simplifyVector=TRUE)
  
  testthat::expect_equal(
    contenu$code,
    401
  )
  
})

# ==============================================================================
# TEST 3 : données invalides
# ==============================================================================

testthat::test_that("/predict refuse des données invalides",{
  
  donnees_invalides <- donnees_valides
  
  # Mois volontairement impossible
  donnees_invalides$mois <- 15
  
  reponse <- httr2::request(
    paste0(URL_API,"/predict")
  ) |>
    httr2::req_headers(
      `X-API-Key`=API_KEY_TEST
    ) |>
    httr2::req_body_json(
      list(body=donnees_invalides)
    ) |>
    httr2::req_error(is_error=function(resp) FALSE) |>
    httr2::req_perform()
  
  testthat::expect_equal(
    httr2::resp_status(reponse),
    400
  )
  
  contenu <- httr2::resp_body_json(reponse,simplifyVector=TRUE)
  
  testthat::expect_equal(
    contenu$code,
    400
  )
  
})

# ==============================================================================
# TEST 4 : prédiction valide
# ==============================================================================

testthat::test_that("/predict retourne une prédiction valide",{
  
  reponse <- httr2::request(
    paste0(URL_API,"/predict")
  ) |>
    httr2::req_headers(
      `X-API-Key`=API_KEY_TEST
    ) |>
    httr2::req_body_json(
      list(body=donnees_valides)
    ) |>
    httr2::req_perform()
  
  testthat::expect_equal(
    httr2::resp_status(reponse),
    200
  )
  
  contenu <- httr2::resp_body_json(reponse,simplifyVector=TRUE)
  
  testthat::expect_equal(
    contenu$status,
    "success"
  )
  
  testthat::expect_equal(
    contenu$code,
    200
  )
  
  testthat::expect_true(
    is.numeric(contenu$prediction)
  )
  
  testthat::expect_true(
    contenu$prediction>=0
  )
  
})