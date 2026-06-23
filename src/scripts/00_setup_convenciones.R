# ============================================================================
# 00_setup_convenciones.R
# Caso A "La Herrumbre" — Causa 1872/2024
# Inferencia Bayesiana, Maestría en Minería de Datos, FCEN UBA
# ============================================================================
# CONFIGURACIÓN CENTRAL: todos los scripts de análisis sourcean este archivo.
# Para cambiar la convención o el prior, editar SOLO esta sección.
# ============================================================================



CONVENCION_A <- "A2"   # "A1" o "A2"
CONVENCION_B <- "B2"   # "B1" o "B2"
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
# Detectar el directorio de este script
# Funciona con: source(), Rscript, y Run desde RStudio
SCRIPT_DIR <- tryCatch(
  # Caso 1: source() o Rscript
  dirname(normalizePath(sys.frame(1)$ofile)),
  error = function(e) tryCatch(
    # Caso 2: Run desde RStudio (archivo abierto en el editor)
    dirname(normalizePath(rstudioapi::getActiveDocumentContext()$path)),
    error = function(e) getwd()
  )
)

DOCS_DIR       <- normalizePath(file.path(SCRIPT_DIR, "../../docs"), mustWork = FALSE)
RESULTADOS_DIR <- normalizePath(file.path(SCRIPT_DIR, "../resultados"),  mustWork = FALSE)
GRAFICOS_DIR   <- normalizePath(file.path(RESULTADOS_DIR, "graficos"),   mustWork = FALSE)

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
# Funciones de posterior
# ----------------------------------------------------------------------------

# Devuelve P(H|E) en escala lineal [0,1]
# Usa log-sum-exp: resta el máximo antes de exponenciar para evitar overflow
calcular_posterior <- function(logLR_total, prior) {
  log_num     <- log10(prior) + logLR_total
  log_num_adj <- log_num - max(log_num)        # log-sum-exp: resta el máximo
  num         <- 10^log_num_adj
  num / sum(num)
}

# Devuelve log10[ P(H|E) ] — escala logarítmica, como pide la consigna
# C2 → ≈ 0  |  C4 → ≈ -17  |  H0 → ≈ -31
calcular_log_posterior <- function(logLR_total, prior) {
  log_num     <- log10(prior) + logLR_total
  log_num_adj <- log_num - max(log_num)        # log-sum-exp
  log10_Z     <- log10(sum(10^log_num_adj))    # log10 de la constante normalizadora
  log_num_adj - log10_Z                        # log10[ P(Hi|E) ]
}

# ----------------------------------------------------------------------------
# Paleta de colores (modificable)
# ----------------------------------------------------------------------------
# H0 = gris (hipótesis residual)
# C2 = naranja óxido (el ganador, más visible)
# Ajustar el mapeo según preferencia

COLORES_HIPOTESIS <- c(
  H0 = "#D3D5D7",  
  C1 = "#F4E3B2",     
  C2 = "#CF5C36",   
  C3 = "#EFC88B",   
  C4 = "#0D2847",  
  C5 = "#8B9EA8"    
)

cat(sprintf(
  "Setup cargado: convencion %s+%s+%s | umbral=%.2f\n",
  CONVENCION_A, CONVENCION_B, CONVENCION_G, UMBRAL_DECISION
))

