library(dplyr)
library(readr)

#datos
antropometrico <- read_csv("tablas_A_antropometrica.csv")
osint <- read_csv("tablas_B_osint.csv")
robustez <- read_csv("tablas_G_robustez.csv")
combinaciones <- read_csv("tablas_resumen_combinaciones.csv")

# Van las priors
prior_uniforme <- rep(1/6, 6)
prior_demografica <- c(0.20, 0.18, 0.22, 0.12, 0.20, 0.08)

# Hipótesis ----> H0 (nulo) + cinco candidatos
caso <- c("H0", antropometrico$candidato)


# ------------------------------------------------------------------------------
#                       SECCIÓN ANTROPOMETRÍA
# ------------------------------------------------------------------------------


# Antropometría A1: agrego H0 con log10(LR)=0
log10_lr_antropometrica <- c(0, antropometrico$A1_log10_LR)

# Paso de log10
lr_antropometrica <- 10^log10_lr_antropometrica

# Numerador pero sin normalizar
evidencia_antro <- prior_demografica * lr_antropometrica

# Tabla
dataset <- data.frame(
  caso,
  prior_uniforme,
  prior_demografica,
  log10_lr_antropometrica,
  lr_antropometrica,
  evidencia_antro)

# Primera posterior
dataset$posterior_antro <- dataset$evidencia_antro / sum(dataset$evidencia_antro)

# Entonces, considerando la prior demográfica y el método riguroso
View(antropometrico)

