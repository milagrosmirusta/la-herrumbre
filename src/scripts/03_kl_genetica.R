# ============================================================================
# 03_kl_genetica.R
# Caso A "La Herrumbre" — Causa 1872/2024
# ============================================================================
# Cuantifica el aporte informacional de la línea genética mediante la
# divergencia de Kullback-Leibler entre:
#
#   p = P(H | E_ant, E_osint, E_gen)   [posterior completa]
#   q = P(H | E_ant, E_osint)          [posterior sin genética]
#
#   KL(p || q) = Σ_i p_i · log₂(p_i / q_i)   [en bits]
#
# Se calcula para las 8 combinaciones y ambos priors.
#
# Salidas:
#   resultados/03_kl_genetica.csv
#   resultados/graficos/03_kl_genetica.png
# ============================================================================

source("00_setup_convenciones.R")

# ============================================================================
# Función KL divergence
# ============================================================================

kl_bits <- function(p, q) {
  # KL(p||q) en bits; ignora términos donde p=0
  idx <- p > 1e-15
  sum(p[idx] * log2(p[idx] / q[idx]))
}

# ============================================================================
# Calcular KL para las 8 combinaciones × 2 priors
# ============================================================================

cols <- list(
  A = list(A1 = "log10_LR_antrop_A1", A2 = "log10_LR_antrop_A2"),
  B = list(B1 = "log10_LR_OSINT_B1",  B2 = "log10_LR_OSINT_B2"),
  G = list(G1 = "log10_LR_efec_G1",   G2 = "log10_LR_efec_G2")
)

grilla <- expand_grid(
  conv_A = c("A1", "A2"),
  conv_B = c("B1", "B2"),
  conv_G = c("G1", "G2"),
  prior  = c("demografico", "uniforme")
)

priors <- list(
  demografico = prior_demografico,
  uniforme    = prior_uniforme
)

kl_tabla <- map_dfr(seq_len(nrow(grilla)), function(i) {
  cA <- grilla$conv_A[i]; cB <- grilla$conv_B[i]
  cG <- grilla$conv_G[i]; pr <- grilla$prior[i]

  lrA <- c(0, tabla_A[[cols$A[[cA]]]])
  lrB <- c(0, tabla_B[[cols$B[[cB]]]])
  lrG <- c(0, tabla_G[[cols$G[[cG]]]])
  pi  <- priors[[pr]]

  p <- calcular_posterior(lrA + lrB + lrG, pi)  # con genética
  q <- calcular_posterior(lrA + lrB,        pi)  # sin genética

  tibble(
    combinacion = paste(cA, cB, cG, sep = "+"),
    prior       = pr,
    KL_bits     = kl_bits(p, q),
    KL_nats     = KL_bits * log(2)
  )
})

write_csv(kl_tabla, file.path(RESULTADOS_DIR, "03_kl_genetica.csv"))
cat("Escrito: 03_kl_genetica.csv\n\n")

cat("Divergencia KL — aporte de la genética (bits):\n")
kl_tabla %>%
  mutate(across(starts_with("KL"), ~ round(., 3))) %>%
  print()

# ============================================================================
# Detalle para la convención elegida
# ============================================================================

comb_elegida <- paste(CONVENCION_A, CONVENCION_B, CONVENCION_G, sep = "+")

kl_elegida <- kl_tabla %>%
  filter(combinacion == comb_elegida)

cat(sprintf("\nConvención elegida (%s):\n", comb_elegida))
cat(sprintf("  Prior demográfico → KL = %.4f bits (%.4f nats)\n",
  filter(kl_elegida, prior == "demografico")$KL_bits,
  filter(kl_elegida, prior == "demografico")$KL_nats))
cat(sprintf("  Prior uniforme    → KL = %.4f bits (%.4f nats)\n",
  filter(kl_elegida, prior == "uniforme")$KL_bits,
  filter(kl_elegida, prior == "uniforme")$KL_nats))

# Interpretación: % del máximo teórico log2(6) ≈ 2.585 bits
max_kl <- log2(length(candidatos))
kl_dem <- filter(kl_elegida, prior == "demografico")$KL_bits
cat(sprintf("\nMáximo teórico KL (distribución uniforme → punto): %.4f bits\n", max_kl))
cat(sprintf("Aporte relativo: %.1f%% del máximo\n", kl_dem / max_kl * 100))
cat("\nInterpretación: KL grande → la genética movió sustancialmente la posterior.\n")

# ============================================================================
# Gráfico
# ============================================================================

g <- kl_tabla %>%
  mutate(prior = recode(prior,
                        demografico = "Prior demográfico",
                        uniforme    = "Prior uniforme")) %>%
  ggplot(aes(x = combinacion, y = KL_bits, fill = prior)) +
  geom_col(position = "dodge") +
  geom_text(aes(label = round(KL_bits, 2)),
            position = position_dodge(width = 0.9),
            vjust = -0.3, size = 3) +
  scale_fill_manual(values = c("Prior demográfico" = "#2c7bb6",
                                "Prior uniforme"    = "#abd9e9")) +
  labs(
    title    = "Aporte informacional de la línea genética",
    subtitle = "KL(posterior con genética || posterior sin genética)",
    x        = "Combinación de convenciones",
    y        = "Divergencia KL (bits)",
    fill     = NULL
  ) +
  theme_minimal(base_size = 12) +
  theme(
    axis.text.x   = element_text(angle = 30, hjust = 1),
    plot.title    = element_text(face = "bold"),
    plot.subtitle = element_text(color = "gray40"),
    legend.position = "top"
  )

ggsave(file.path(GRAFICOS_DIR, "03_kl_genetica.png"),
       g, width = 9, height = 5.5, dpi = 150)
cat("\nEscrito: 03_kl_genetica.png\n")
