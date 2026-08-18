# ==============================================================================
# 02_preparation_donnees.R
# Projet : Prédiction des ventes pharmaceutiques
# Objectif : Importer, contrôler et préparer les données avant modélisation
# ==============================================================================


# -------------------------------------------------
    # Chargement de la configuration du projet
# -------------------------------------------------

source("R/00_packages.R")
source("R/01_configuration.R")


# -----------------------------
    # Import des données brutes
# ------------------------------
ventes_daily <- read_csv(file.path(DIR_RAW, "salesdaily.csv"),show_col_types = FALSE)

# Renommage des variables
ventes_daily <- ventes_daily |>
  rename(
    date = datum,
    anti_inflammatoires_acide_acetique = M01AB,
    anti_inflammatoires_acide_propionique = M01AE,
    analgesiques_antipyretiques_salicyles = N02BA,
    analgesiques_antipyretiques_anilides = N02BE,
    anxiolytiques = N05B,
    hypnotiques_sedatifs = N05C,
    medicaments_voies_respiratoires = R03,
    antihistaminiques_systemiques = R06,
    annee = Year,
    mois = Month,
    indicateur_temporel_source = Hour,
    jour_semaine = `Weekday Name`)


# Mise au bon format de la date
ventes_daily <- ventes_daily |>
  mutate(date = mdy(date))

#view(ventes_daily)
#head(ventes_daily)
dim(ventes_daily)
glimpse(ventes_daily)
range(ventes_daily$date, na.rm = TRUE)
colSums(is.na(ventes_daily))
sum(duplicated(ventes_daily))


# Contrôle des valeurs négatives dans les variables de ventes
variables_ventes <- c("anti_inflammatoires_acide_acetique", "anti_inflammatoires_acide_propionique",
  "analgesiques_antipyretiques_salicyles","analgesiques_antipyretiques_anilides",
  "anxiolytiques","hypnotiques_sedatifs",
  "medicaments_voies_respiratoires","antihistaminiques_systemiques")

# Nombre de valeurs négatives par variable
sapply(ventes_daily[variables_ventes],function(x) sum(x < 0, na.rm = TRUE))

#Verification des valeurs minimales et maximales
sapply(ventes_daily[variables_ventes],range,na.rm = TRUE)

# ventes_daily |>
#   arrange(desc(analgesiques_antipyretiques_anilides)) |>
#   select(date, analgesiques_antipyretiques_anilides) |>
#   head(10)


ventes_daily |>
  summarise(
    date_min = min(date),
    date_max = max(date),
    nb_jours_observes = n_distinct(date),
    nb_jours_theoriques = as.integer(max(date) - min(date)) + 1,
    nb_jours_manquants = nb_jours_theoriques - nb_jours_observes)

# Vérification de la cohérence des variables temporelles
controle_temporel <- ventes_daily |>
  mutate(
    annee_calculee = year(date),
    mois_calcule = month(date),
    jour_semaine_calcule = wday(date, label = TRUE, abbr = FALSE))
# Vérification de l'année
sum(controle_temporel$annee != controle_temporel$annee_calculee)
# Vérification du mois
sum(controle_temporel$mois != controle_temporel$mois_calcule)
# Vérification du jour de la semaine
controle_temporel |>
  count(jour_semaine, jour_semaine_calcule)

# Uniformisation du jour de la semaine en français
ventes_daily <- ventes_daily |>
  mutate(
      jour_semaine = case_when(
      jour_semaine == "Monday"    ~ "lundi",
      jour_semaine == "Tuesday"   ~ "mardi",
      jour_semaine == "Wednesday" ~ "mercredi",
      jour_semaine == "Thursday"  ~ "jeudi",
      jour_semaine == "Friday"    ~ "vendredi",
      jour_semaine == "Saturday"  ~ "samedi",
      jour_semaine == "Sunday"    ~ "dimanche",
      TRUE ~ jour_semaine))

#unique(ventes_daily$jour_semaine)



# ---------------------------------------------
# Création des variables temporelles de base
# ---------------------------------------------

ventes_daily <- ventes_daily |>
  mutate(jour_mois = day(date), # Jour du mois : 1 à 31
         semaine_annee = isoweek(date),    # Numéro de semaine dans l'année : 1 à 52/53
         trimestre = quarter(date), # Trimestre : 1 à 4
         weekend = if_else(jour_semaine %in% c("samedi", "dimanche"), 1L,0L)) # Indicateur week-end

# ventes_daily |>
#   select(date,annee,mois,jour_mois,
#     semaine_annee,trimestre,jour_semaine,weekend) |>
#   head(10)







# ------------------------------------------------------------------------------
# Contrôles initiaux
# ------------------------------------------------------------------------------

# Les contrôles porteront notamment sur :
# - dimensions du jeu de données
# - types des variables
# - valeurs manquantes
# - doublons
# - valeurs aberrantes ou incohérentes
# - cohérence des dates et périodes


# ------------------------------------------------------------------------------
# Préparation des données
# ------------------------------------------------------------------------------

# Cette section contiendra ensuite :
# - nettoyage des variables
# - création des variables temporelles
# - traitement des valeurs manquantes
# - création éventuelle de variables explicatives
# - sauvegarde des données préparées dans data/interim/