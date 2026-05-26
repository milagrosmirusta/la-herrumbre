library(dplyr)
library(readr)

# PRIOR DEMOGRÁFICA ------------------------------------------------------------

#datos
antropometrico <- read_csv("tablas_A_antropometrica.csv")
osint <- read_csv("tablas_B_osint.csv")
robustez <- read_csv("tablas_G_robustez.csv")
combinaciones <- read_csv("tablas_resumen_combinaciones.csv")

# Van las priors
prior_uniforme <- rep(1/6, 6)
prior_demografica <- c(0.20, 0.18, 0.22, 0.12, 0.20, 0.08)
prior_demografica_log <- log10(prior_demografica) 

# Hipótesis ----> H0 (nulo) + cinco candidatos
caso <- c("H0", antropometrico$candidato)

# ------------------------------------------------------------------------------
#                       SECCIÓN ANTROPOMETRÍA
# ------------------------------------------------------------------------------

# Antropometría A1: agrego H0 con LR = 1
# ---------------- LOG ------------------
lr_antropometrica_log <- c(0, antropometrico$A1_log10_LR)

# Numerador sin normalizar
evidencia_antro_log <- prior_demografica_log + lr_antropometrica_log

# Tabla
dataset <- data.frame(
  caso,
  prior_uniforme,
  prior_demografica,
  prior_demografica_log,
  lr_antropometrica_log,
  evidencia_antro_log)

# Primera posterior
dataset$posterior_antro_log <- dataset$evidencia_antro_log - (max(dataset$evidencia_antro_log))

# Entonces, considerando la prior demográfica y el método riguroso
# Numerador en escala log10

dataset$evidencia_antro_log <- dataset$prior_demografica_log + dataset$lr_antropometrica_log

# Constante de normalización
normalizador_log <- log10(sum(10^dataset$evidencia_antro_log))
# Posterior en escala log10
dataset$posterior_antro_log <- dataset$evidencia_antro_log - normalizador_log
# Posterior en escala original
dataset$posterior_antro <- 10^dataset$posterior_antro_log

# ------------------------------------------------------------------------------
#                       SECCIÓN OSINT
# ------------------------------------------------------------------------------

dataset <- dataset %>%
  mutate(
    lr_osint = c(0, osint$B2_log10_LR),
    posterior_osint = posterior_antro_log + lr_osint,
    normalizacion_osint = 10^posterior_osint,
    probabilidad_antro_osint = normalizacion_osint / sum(normalizacion_osint))
#View(dataset)


# ------------------------------------------------------------------------------
#                           SECCIÓN GENÉTICA
# ------------------------------------------------------------------------------


dataset <- dataset %>%
  mutate(
    lr_genetica = c(0, robustez$G2_log10_LR_efectivo),
    posterior_genetica = posterior_osint + lr_genetica,
    normalizacion_genetica = 10^posterior_genetica,
    probabilidad_antro_osint_gen = normalizacion_genetica / sum(normalizacion_genetica))

options(scipen = 999)

View(dataset)

# Graficamos
library(ggplot2)
library(tidyverse)

grafico <- dataset %>%
  select(caso,posterior_antro, probabilidad_antro_osint,
         probabilidad_antro_osint_gen)%>%
  pivot_longer(
    cols = c("posterior_antro","probabilidad_antro_osint", "probabilidad_antro_osint_gen"),
    names_to = "Probabilidades",
    values_to = "Value")%>%
  mutate(
    Value = round(Value, digits = 3)
  )
View(grafico)

ggplot(grafico, aes(x = caso, y = Value, 
                    fill = Probabilidades))+
         geom_bar(stat = "identity",
                  position = "dodge")+
  facet_grid(~Probabilidades)+
  geom_text(aes(label = Value))
  theme_bw()





