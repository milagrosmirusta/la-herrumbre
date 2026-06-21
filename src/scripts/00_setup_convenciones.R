# ============================================================================
# 00_setup_convenciones.R
# Caso A "La Herrumbre" — Causa 1872/2024
# Inferencia Bayesiana, Maestría en Minería de Datos, FCEN UBA
# ============================================================================
# CONFIGURACIÓN CENTRAL: todos los scripts de análisis sourcean este archivo.
# Para cambiar la convención o el prior, editar SOLO esta sección.
# ============================================================================

# ----------------------------------------------------------------------------
# PARÁMETROS MODIFICABLES
# ----------------------------------------------------------------------------
# Convenciones por bloque (cambiar aquí para explorar alternativas):
#   A1 = antropometría estricta  (σ_edad = 5 años, IPM riguroso)
#   A2 = antropometría moderada  (σ_edad = 10 años, IPM flexible)
#   B1 = OSINT estricta          (α descuento testimonios = 0.6)
#   B2 = OSINT moderada          (α descuento testimonios = 0.8)
#   G1 = genética estricta       (β diferenciado por grado de parentesco)
#   G2 = genética moderada       (β uniforme, más permisivo)

CONVENCION_A <- "A1"   # "A1" o "A2"
CONVENCION_B <- "B1"   # "B1" o "B2"
CONVENCION_G <- "G1"   # "G1" o "G2"

# Umbral para declarar identificación positiva
UMBRAL_DECISION <- 0.95

# Semilla fija (número de la causa)
set.seed(1872)

# ----------------------------------------------------------------------------
# Librerías
# ----------------------------------------------------------------------------
suppressMessages({
  library(tidyverse)
  library(readr)
  library(gridExtra)
})

# ----------------------------------------------------------------------------
# Rutas
# ----------------------------------------------------------------------------
# Este script vive en src/scripts/; los datos están en ../../docs/
DOCS_DIR     <- file.path(dirname(dirname(getwd())), "docs")
# Fallback si se ejecuta desde otra ubicación
if (!dir.exists(DOCS_DIR)) {
  DOCS_DIR <- "../../docs"
}
RESULTADOS_DIR        <- file.path(dirname(getwd()), "resultados")
GRAFICOS_DIR          <- file.path(RESULTADOS_DIR, "graficos")

dir.create(RESULTADOS_DIR, showWarnings = FALSE, recursive = TRUE)
dir.create(GRAFICOS_DIR,   showWarnings = FALSE, recursive = TRUE)

# ----------------------------------------------------------------------------
# Cargar tablas de LR (ya calculados por el laboratorio)
# ----------------------------------------------------------------------------
tabla_A <- read_csv(file.path(DOCS_DIR, "tablas_A_antropometrica.csv"),
                    show_col_types = FALSE)
tabla_B <- read_csv(file.path(DOCS_DIR, "tablas_B_osint.csv"),
                    show_col_types = FALSE)
tabla_G <- read_csv(file.path(DOCS_DIR, "tablas_G_robustez.csv"),
                    show_col_types = FALSE)

candidatos <- c("H0", tabla_A$candidato)   # H0 + C1..C5

# ----------------------------------------------------------------------------
# Mapear convención a columna CSV
# ----------------------------------------------------------------------------
COL_A <- paste0("log10_LR_antrop_", CONVENCION_A)  # ej: log10_LR_antrop_A1
COL_B <- paste0("log10_LR_OSINT_",  CONVENCION_B)  # ej: log10_LR_OSINT_B1
COL_G <- paste0("log10_LR_efec_",   CONVENCION_G)  # ej: log10_LR_efec_G1

# Vectores de log10-LR para la convención elegida (H0 = 0 siempre: LR(H0)=1)
logLR_A <- c(0, tabla_A[[COL_A]])
logLR_B <- c(0, tabla_B[[COL_B]])
logLR_G <- c(0, tabla_G[[COL_G]])

# ----------------------------------------------------------------------------
# Priors
# ----------------------------------------------------------------------------
prior_demografico <- c(H0 = 0.20, C1 = 0.18, C2 = 0.22,
                       C3 = 0.12, C4 = 0.20, C5 = 0.08)
prior_uniforme    <- setNames(rep(1/6, 6), candidatos)

# ----------------------------------------------------------------------------
# Función: calcular posterior en escala log10 (evita overflow de 10^28)
# ----------------------------------------------------------------------------
calcular_posterior <- function(logLR_total, prior) {
  log_num     <- log10(prior) + logLR_total          # log10 del numerador
  log_num_adj <- log_num - max(log_num)              # estabilidad numérica
  num         <- 10^log_num_adj
  num / sum(num)
}

cat(sprintf(
  "Setup cargado: convencion %s+%s+%s | umbral=%.2f\n",
  CONVENCION_A, CONVENCION_B, CONVENCION_G, UMBRAL_DECISION
))
