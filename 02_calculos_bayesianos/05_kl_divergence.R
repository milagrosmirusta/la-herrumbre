# ============================================================================
# DIVERGENCIA KL: APORTE INFORMACIONAL DE LA GENÉTICA
# ============================================================================
# La divergencia de Kullback-Leibler mide cuánta información se pierde
# al usar una distribución q para aproximar p:
#
# KL(p || q) = Σ_i p_i × log(p_i / q_i)
#
# En este caso:
# - p = posterior con genética (A + B + G)
# - q = posterior sin genética (A + B)
#
# KL grande → la genética movió mucho la creencia
# KL pequeña → la genética confirmó lo que ya estaba establecido
#
# En este caso esperamos KL sustancial porque:
# - Sin genética: C2 ≈ 0.53, C4 ≈ 0.46 (empatados)
# - Con genética: C2 ≈ 1.00, C4 ≈ 0.00 (resuelto)
# ============================================================================

rm(list = ls())
library(tidyverse)
library(readr)

# Cargar datos
tabla_A <- read_csv("../datos/tablas_A_antropometrica.csv")
tabla_B <- read_csv("../datos/tablas_B_osint.csv")
tabla_G <- read_csv("../datos/tablas_G_robustez.csv")

# Convenciones A1, B1, G1
logLR_A <- c(0, tabla_A$log10_LR_antrop_A1)
logLR_B <- c(0, tabla_B$log10_LR_OSINT_B1)
logLR_G <- c(0, tabla_G$log10_LR_efec_G1)

prior_uniforme <- rep(1/6, 6)

# ============================================================================
# FUNCIÓN: CALCULAR POSTERIOR
# ============================================================================

calcular_posterior <- function(logLR, prior) {
  logLR_natural <- logLR * log(10)
  log_num <- log(prior) + logLR_natural
  log_num_adj <- log_num - max(log_num, na.rm = TRUE)
  numerador <- exp(log_num_adj)
  posterior <- numerador / sum(numerador)
  return(posterior)
}

# ============================================================================
# FUNCIÓN: CALCULAR KL DIVERGENCE
# ============================================================================

kl_divergence <- function(p, q) {
  # KL(p || q) = Σ p_i * log(p_i / q_i)
  # Manejar p_i = 0 o q_i = 0
  kl <- 0
  for (i in seq_along(p)) {
    if (p[i] > 1e-10 && q[i] > 1e-10) {
      kl <- kl + p[i] * log(p[i] / q[i])
    }
  }
  return(kl)
}

# ============================================================================
# CALCULAR POSTERIORS: CON Y SIN GENÉTICA
# ============================================================================

# Sin genética (A + B)
logLR_sin_G <- logLR_A + logLR_B
P_sin_G <- calcular_posterior(logLR_sin_G, prior_uniforme)

# Con genética (A + B + G)
logLR_con_G <- logLR_A + logLR_B + logLR_G
P_con_G <- calcular_posterior(logLR_con_G, prior_uniforme)

# ============================================================================
# CALCULAR KL DIVERGENCE
# ============================================================================

kl_nats <- kl_divergence(P_con_G, P_sin_G)
kl_bits <- kl_nats / log(2)

cat("DIVERGENCIA KL: INFORMACIÓN APORTADA POR LA GENÉTICA\n")
cat("============================================================================\n\n")

cat("Distribuciones:\n")
cat("  p = Posterior CON genética (A + B + G)\n")
cat("  q = Posterior SIN genética (A + B)\n\n")

cat("Fórmula:\n")
cat("  KL(p || q) = Σ_i p_i × log(p_i / q_i)\n\n")

cat(sprintf("Resultado:\n"))
cat(sprintf("  KL(p || q) = %.4f nats = %.4f bits\n", kl_nats, kl_bits))
cat(sprintf("  (1 nat = %.4f bits; 1 bit = %.4f nats)\n\n", 1/log(2), log(2)))

# ============================================================================
# TABLA: CONTRIBUCIÓN POR CANDIDATO
# ============================================================================

cat("CONTRIBUCIÓN A KL POR CANDIDATO:\n")
cat("============================================================================\n\n")

tabla_kl_desagregado <- tibble(
  candidato = c("H0", "C1", "C2", "C3", "C4", "C5"),
  P_sin_G = P_sin_G,
  P_con_G = P_con_G
) %>%
  mutate(
    KL_contribucion = P_con_G * log(P_con_G / (P_sin_G + 1e-10))
  ) %>%
  mutate(
    across(where(is.numeric), ~ round(., 6))
  )

print(tabla_kl_desagregado)

cat("\n")

# Encontrar quién movió más
idx_max_contrib <- which.max(tabla_kl_desagregado$KL_contribucion)
candidato_max_contrib <- tabla_kl_desagregado$candidato[idx_max_contrib]
contrib_max <- tabla_kl_desagregado$KL_contribucion[idx_max_contrib]

cat(sprintf(
  "Candidato que 'se movió' más con genética: %s (contribución: %.4f nats)\n",
  candidato_max_contrib, contrib_max
))

# ============================================================================
# COMPARACIÓN POSTERIOR SIN Y CON GENÉTICA
# ============================================================================

cat("\n\nCOMPARACIÓN DE POSTERIORS\n")
cat("============================================================================\n\n")

tabla_comparacion <- tibble(
  candidato = c("H0", "C1", "C2", "C3", "C4", "C5"),
  P_sin_genetica = round(P_sin_G, 6),
  P_con_genetica = round(P_con_G, 6),
  cambio_absoluto = round(P_con_G - P_sin_G, 6),
  cambio_relativo = round((P_con_G - P_sin_G) / (P_sin_G + 1e-10), 4)
)

print(tabla_comparacion)

cat("\n")

# Narrativa
cat("NARRATIVA:\n")
cat(sprintf(
  "  Sin genética: C2 = %.3f (30%% ganador, ~50%%), C4 = %.3f (~46%%)\n",
  P_sin_G[3], P_sin_G[5]
))
cat(sprintf(
  "  Con genética: C2 = %.6f (dominante), C4 = %.6f (colapsa)\n",
  P_con_G[3], P_con_G[5]
))
cat("  \n")
cat(sprintf(
  "  KL = %.4f bits = %.2f%% del máximo teórico (log₂ 6 ≈ 2.59 bits)\n",
  kl_bits, kl_bits / log2(6) * 100
))
cat("  \n")
cat("  → La genética RESOLVIÓ la ambigüedad preexistente entre C2 y C4\n")
cat("  → El aporte informacional es SUSTANCIAL (~40% del máximo posible)\n")

# ============================================================================
# EXPORTAR
# ============================================================================

write_csv(tabla_comparacion, "../03_resultados/05_kl_divergence.csv")

# Crear un texto resumen
sink("../03_resultados/05_kl_divergence_resumen.txt")

cat("DIVERGENCIA KL — RESUMEN\n")
cat("============================================================================\n\n")

cat(sprintf("KL(posterior_con_G || posterior_sin_G) = %.6f nats = %.6f bits\n\n",
  kl_nats, kl_bits))

cat("Posteriors:\n")
cat(sprintf("  Sin genética (A+B):\n"))
for (i in seq_along(P_sin_G)) {
  cat(sprintf("    %s: %.6f\n", tabla_comparacion$candidato[i], P_sin_G[i]))
}
cat("\n")

cat(sprintf("  Con genética (A+B+G):\n"))
for (i in seq_along(P_con_G)) {
  cat(sprintf("    %s: %.6f\n", tabla_comparacion$candidato[i], P_con_G[i]))
}
cat("\n")

cat("Interpretación:\n")
cat(sprintf("  La genética aportó %.4f bits de información (%.1f%% del máximo).\n",
  kl_bits, kl_bits / log2(6) * 100))
cat("  Esto equivale a decir que la genética 'podó' ~40% de la incertidumbre.\n")

sink()

cat("\n✓ Resultados exportados a 05_kl_divergence.csv y 05_kl_divergence_resumen.txt\n")
