# ============================================================================
# CALCULAR POSTERIOR BAYESIANA
# ============================================================================
# Teorema de Bayes: P(H_i | E) = (π_i × L(H_i)) / Z
# donde Z = Σ_j (π_j × L(H_j))
#
# Para evitar overflow numérico, se trabaja en escala logarítmica:
# log P(H_i | E) = log(π_i) + logLR_i - logZ
# ============================================================================

rm(list = ls())
library(tidyverse)
library(readr)

# Cargar datos de setup
setup <- readRDS("00_datos_setup.rds")
datos <- setup$datos

# ============================================================================
# 1. CALCULAR LIKELIHOOD TOTAL (en escala log10)
# ============================================================================

datos <- datos %>%
  mutate(
    logLR_total = logLR_A + logLR_B + logLR_G
  )

cat("Likelihood total (log10):\n")
print(datos %>% select(candidato, logLR_A, logLR_B, logLR_G, logLR_total))
cat("\n")

# ============================================================================
# 2. FUNCIÓN PARA CALCULAR POSTERIOR
# ============================================================================

calcular_posterior <- function(datos, prior_name) {

  # Seleccionar prior
  if (prior_name == "uniforme") {
    prior_col <- "pi_uniforme"
  } else if (prior_name == "demografico") {
    prior_col <- "pi_demografico"
  } else {
    stop("Prior desconocido")
  }

  # Convertir de log10 a log natural
  logLR_natural <- datos$logLR_total * log(10)
  prior_values <- datos[[prior_col]]

  # Calcular log-numerador: log(π_i × L_i)
  # = log(π_i) + log(L_i)
  # = log(π_i) + logLR_natural
  log_numerador <- log(prior_values) + logLR_natural

  # Normalizar: restar el máximo para evitar overflow
  log_num_adj <- log_numerador - max(log_numerador, na.rm = TRUE)

  # Exponenciar para volver a escala natural
  numerador <- exp(log_num_adj)

  # Normalizar: dividir por Z
  posterior <- numerador / sum(numerador)

  return(posterior)
}

# ============================================================================
# 3. CALCULAR POSTERIORES PARA AMBOS PRIORS
# ============================================================================

datos <- datos %>%
  mutate(
    posterior_uniforme = calcular_posterior(datos, "uniforme"),
    posterior_demografico = calcular_posterior(datos, "demografico")
  )

# ============================================================================
# 4. TABLA PERICIAL FINAL
# ============================================================================

tabla_pericial <- datos %>%
  select(
    candidato,
    pi_uniforme,
    pi_demografico,
    logLR_A,
    logLR_B,
    logLR_G,
    logLR_total,
    posterior_uniforme,
    posterior_demografico
  ) %>%
  mutate(
    across(starts_with("pi_"), list(pct = ~ . * 100), .names = "{.col}_pct"),
    across(starts_with("posterior_"), list(pct = ~ . * 100), .names = "{.col}_pct")
  )

cat("TABLA PERICIAL — POSTERIOR BAYESIANA\n")
cat("Convenciones: A1 + B1 + G1\n")
cat("============================================================================\n\n")

# Mostrar con formato legible
tabla_pericial %>%
  select(candidato, pi_uniforme, logLR_total, posterior_uniforme, posterior_demografico) %>%
  mutate(
    across(where(is.numeric), ~ round(., 6))
  ) %>%
  print()

# ============================================================================
# 5. EXPORTAR RESULTADOS
# ============================================================================

# Versión completa (con todas las columnas)
write_csv(tabla_pericial, "../03_resultados/01_tabla_pericial_completa.csv")

# Versión simplificada para presentación
tabla_pericial_simple <- tabla_pericial %>%
  select(
    candidato,
    pi_uniforme,
    logLR_A,
    logLR_B,
    logLR_G,
    logLR_total,
    posterior_uniforme,
    posterior_demografico
  ) %>%
  mutate(
    across(where(is.numeric), ~ round(., 4))
  )

write_csv(tabla_pericial_simple, "../03_resultados/01_tabla_pericial.csv")

cat("\n✓ Tabla pericial exportada a 03_resultados/01_tabla_pericial.csv\n")

# ============================================================================
# 6. ANÁLISIS DE DECISIÓN
# ============================================================================

cat("\nANÁLISIS DE DECISIÓN\n")
cat("============================================================================\n")

# Encontrar máximo posterior
idx_max_uniforme <- which.max(tabla_pericial$posterior_uniforme)
idx_max_demografico <- which.max(tabla_pericial$posterior_demografico)

candidato_max_uniforme <- tabla_pericial$candidato[idx_max_uniforme]
posterior_max_uniforme <- tabla_pericial$posterior_uniforme[idx_max_uniforme]

candidato_max_demografico <- tabla_pericial$candidato[idx_max_demografico]
posterior_max_demografico <- tabla_pericial$posterior_demografico[idx_max_demografico]

cat(sprintf(
  "MAP (Maximum A Posteriori) — Prior uniforme: %s (P = %.6f)\n",
  candidato_max_uniforme, posterior_max_uniforme
))

cat(sprintf(
  "MAP (Maximum A Posteriori) — Prior demográfico: %s (P = %.6f)\n",
  candidato_max_demografico, posterior_max_demografico
))

# Umbral de decisión
umbral <- 0.95

cat(sprintf(
  "\nUmbral de identificación positiva: %.2f\n", umbral
))

cat(sprintf(
  "¿%s supera umbral (prior uniforme)? %s (%.4f > %.2f)\n",
  candidato_max_uniforme,
  ifelse(posterior_max_uniforme > umbral, "SÍ", "NO"),
  posterior_max_uniforme,
  umbral
))

cat(sprintf(
  "¿%s supera umbral (prior demográfico)? %s (%.4f > %.2f)\n",
  candidato_max_demografico,
  ifelse(posterior_max_demografico > umbral, "SÍ", "NO"),
  posterior_max_demografico,
  umbral
))

cat("\n")
