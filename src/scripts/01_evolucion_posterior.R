# ============================================================================
# 01_evolucion_posterior.R
# Caso A "La Herrumbre" — Causa 1872/2024
# ============================================================================
# Calcula la posterior P(H_i | E) bajo:
#   (a) la convención elegida en 00_setup_convenciones.R
#   (b) prior uniforme y prior demográfico
#   (c) las 8 combinaciones canónicas A×B×G (sensibilidad a convenciones)
#
# Salidas:
#   resultados/01a_posterior_convencion_elegida.csv
#   resultados/01b_sensibilidad_8combinaciones.csv
# ============================================================================

source("00_setup_convenciones.R")

# ============================================================================
# A. Posterior bajo la convención elegida (ambos priors)
# ============================================================================

logLR_total <- logLR_A + logLR_B + logLR_G

tabla_posterior <- tibble(
  hipotesis         = candidatos,
  pi_uniforme       = prior_uniforme,
  pi_demografico    = prior_demografico,
  logLR_antrop      = logLR_A,
  logLR_osint       = logLR_B,
  logLR_gen         = logLR_G,
  logLR_total       = logLR_total,
  posterior_uniforme    = calcular_posterior(logLR_total, prior_uniforme),
  posterior_demografico = calcular_posterior(logLR_total, prior_demografico)
)

write_csv(tabla_posterior,
          file.path(RESULTADOS_DIR, "01a_posterior_convencion_elegida.csv"))
cat("Escrito: 01a_posterior_convencion_elegida.csv\n")

# Imprimir resumen
cat(sprintf("\nConvención: %s+%s+%s\n", CONVENCION_A, CONVENCION_B, CONVENCION_G))
cat("Posterior (prior demográfico):\n")
tabla_posterior %>%
  select(hipotesis, logLR_total, posterior_uniforme, posterior_demografico) %>%
  mutate(across(where(is.numeric), ~ round(., 4))) %>%
  print()

# Decisión forense
idx_max <- which.max(tabla_posterior$posterior_demografico)
cat(sprintf(
  "\nDecisión forense (prior demográfico): %s  P=%.6f  %s\n",
  tabla_posterior$hipotesis[idx_max],
  tabla_posterior$posterior_demografico[idx_max],
  ifelse(tabla_posterior$posterior_demografico[idx_max] >= UMBRAL_DECISION,
         "→ IDENTIFICACIÓN POSITIVA", "→ INDETERMINACIÓN")
))

# ============================================================================
# B. Sensibilidad a convenciones: las 8 combinaciones A×B×G
# ============================================================================

# Todas las columnas disponibles por bloque
cols <- list(
  A = list(A1 = "log10_LR_antrop_A1", A2 = "log10_LR_antrop_A2"),
  B = list(B1 = "log10_LR_OSINT_B1",  B2 = "log10_LR_OSINT_B2"),
  G = list(G1 = "log10_LR_efec_G1",   G2 = "log10_LR_efec_G2")
)

grilla <- expand_grid(
  conv_A = c("A1", "A2"),
  conv_B = c("B1", "B2"),
  conv_G = c("G1", "G2")
)

filas <- map(seq_len(nrow(grilla)), function(i) {
  cA <- grilla$conv_A[i]; cB <- grilla$conv_B[i]; cG <- grilla$conv_G[i]
  lrA <- c(0, tabla_A[[cols$A[[cA]]]])
  lrB <- c(0, tabla_B[[cols$B[[cB]]]])
  lrG <- c(0, tabla_G[[cols$G[[cG]]]])
  lrt <- lrA + lrB + lrG

  tibble(
    combinacion          = paste(cA, cB, cG, sep = "+"),
    hipotesis            = candidatos,
    posterior_uniforme   = calcular_posterior(lrt, prior_uniforme),
    posterior_demografico = calcular_posterior(lrt, prior_demografico)
  )
})

tabla_8comb <- bind_rows(filas)
write_csv(tabla_8comb,
          file.path(RESULTADOS_DIR, "01b_sensibilidad_8combinaciones.csv"))
cat("\nEscrito: 01b_sensibilidad_8combinaciones.csv\n")

# Resumen: ganador por combinación
cat("\nGanador (posterior demográfico) en cada combinación:\n")
tabla_8comb %>%
  group_by(combinacion) %>%
  slice_max(posterior_demografico, n = 1) %>%
  select(combinacion, hipotesis, posterior_demografico) %>%
  mutate(posterior_demografico = round(posterior_demografico, 4)) %>%
  print()
