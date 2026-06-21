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

.dir <- tryCatch(dirname(normalizePath(sys.frame(1)$ofile)),
         error = function(e) tryCatch(dirname(normalizePath(rstudioapi::getActiveDocumentContext()$path)),
         error = function(e) getwd()))
source(file.path(.dir, "00_setup_convenciones.R"))

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

tabla_posterior <- tabla_posterior %>%
  mutate(
    log10_post_uniforme   = calcular_log_posterior(logLR_total, prior_uniforme),
    log10_post_demografico = calcular_log_posterior(logLR_total, prior_demografico)
  )

write_csv(tabla_posterior,
          file.path(RESULTADOS_DIR, "01a_posterior_convencion_elegida.csv"))
cat("Escrito: 01a_posterior_convencion_elegida.csv\n")

# Imprimir en escala logarítmica (como pide la consigna)
cat(sprintf("\nConvención: %s+%s+%s\n", CONVENCION_A, CONVENCION_B, CONVENCION_G))
cat("Posterior en escala log10  (0 = certeza, -31 = prácticamente imposible):\n")
tabla_posterior %>%
  select(hipotesis, logLR_antrop, logLR_osint, logLR_gen, logLR_total,
         log10_post_uniforme, log10_post_demografico) %>%
  mutate(across(where(is.numeric), ~ round(., 3))) %>%
  print()

# Decisión forense
idx_max <- which.max(tabla_posterior$posterior_demografico)
cat(sprintf(
  "\nDecisión forense (prior demográfico): %s  log10(P)=%.3f  %s\n",
  tabla_posterior$hipotesis[idx_max],
  tabla_posterior$log10_post_demografico[idx_max],
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
cat("\nGanador (log10 posterior demográfico) en cada combinación:\n")
tabla_8comb %>%
  group_by(combinacion) %>%
  slice_max(posterior_demografico, n = 1) %>%
  mutate(log10_P = round(log10(posterior_demografico + 1e-300), 3)) %>%
  select(combinacion, hipotesis, log10_P) %>%
  print()

# ============================================================================
# C. Gráfico: posterior por combinación (8 paneles)
# ============================================================================

g_8comb <- tabla_8comb %>%
  mutate(
    hipotesis = factor(hipotesis, levels = candidatos),
    label     = ifelse(posterior_demografico >= 0.001,
                       sprintf("%.2f", posterior_demografico), "≈0")
  ) %>%
  ggplot(aes(x = hipotesis, y = posterior_demografico, fill = hipotesis)) +
  geom_col(width = 0.65) +
  geom_text(aes(label = label), vjust = -0.4, size = 2.8, fontface = "bold") +
  facet_wrap(~ combinacion, ncol = 3) +
  scale_fill_manual(values = COLORES_HIPOTESIS) +
  scale_y_continuous(limits = c(0, 1.12), breaks = c(0, 0.5, 1)) +
  labs(
    title    = "Posterior completa por combinación canónica (prior demográfico)",
    subtitle = "En las 8 combinaciones posibles de convenciones, C2 siempre es identificado",
    x        = "Hipótesis",
    y        = "P(H | E)",
    fill     = NULL
  ) +
  theme_minimal(base_size = 11) +
  theme(
    legend.position = "none",
    plot.title      = element_text(face = "bold"),
    plot.subtitle   = element_text(color = "gray40"),
    strip.background = element_rect(fill = "gray92", color = NA),
    strip.text      = element_text(face = "bold", size = 9),
    panel.grid.major.x = element_blank()
  )

ggsave(file.path(GRAFICOS_DIR, "01_sensibilidad_8combinaciones.png"),
       g_8comb, width = 10, height = 7, dpi = 150)
cat("\nEscrito: 01_sensibilidad_8combinaciones.png\n")
