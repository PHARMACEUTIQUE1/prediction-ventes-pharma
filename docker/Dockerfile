# ==============================================================================
# Dockerfile
# Projet : Prédiction des ventes pharmaceutiques
# Objectif : Construire l'image Docker de l'API Plumber
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. Image R de base
# ------------------------------------------------------------------------------

FROM rocker/r-ver:4.3.1


# ------------------------------------------------------------------------------
# 2. Dépendances système nécessaires aux packages R
# ------------------------------------------------------------------------------

RUN apt-get update && apt-get install -y \
    curl \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    libgit2-dev \
    libicu-dev \
    libfontconfig1-dev \
    libfreetype6-dev \
    libsodium-dev \
    libx11-dev \
    libharfbuzz-dev \
    libfribidi-dev \
    libwebp-dev \
    libwebpdemux2 \
    libpng-dev \
    libjpeg-dev \
    libtiff-dev \
    pandoc \
    make \
    g++ \
    cmake \
    && rm -rf /var/lib/apt/lists/*


# ------------------------------------------------------------------------------
# 3. Répertoire de travail du conteneur
# ------------------------------------------------------------------------------

WORKDIR /app


# ------------------------------------------------------------------------------
# 4. Installation de renv
# ------------------------------------------------------------------------------

RUN R -e "install.packages('renv',repos='https://cloud.r-project.org')"


# ------------------------------------------------------------------------------
# 5. Copie du fichier de dépendances
# ------------------------------------------------------------------------------

COPY renv.lock renv.lock


# ------------------------------------------------------------------------------
# 6. Restauration de l'environnement R
# ------------------------------------------------------------------------------

RUN R -e "renv::restore(prompt=FALSE)"


# ------------------------------------------------------------------------------
# 7. Copie des composants nécessaires à l'API
# ------------------------------------------------------------------------------

COPY R R
COPY api api
COPY models models


# ------------------------------------------------------------------------------
# 8. Création du dossier de logs
# ------------------------------------------------------------------------------

RUN mkdir -p outputs/logs


# ------------------------------------------------------------------------------
# 9. Port utilisé par l'API
# ------------------------------------------------------------------------------

EXPOSE 8000


# ------------------------------------------------------------------------------
# 10. Lancement de l'API
# ------------------------------------------------------------------------------

CMD ["R","-e","setwd('/app/api');port<-as.integer(Sys.getenv('PORT',unset='8000'));plumber::plumb('plumber.R')$run(host='0.0.0.0',port=port)"]