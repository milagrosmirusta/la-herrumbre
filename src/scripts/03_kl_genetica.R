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
# ============================================================================

.dir <- tryCatch(dirname(normalizePath(sys.frame(1)$ofile)),
         error = function(e) tryCatch(dirname(normalizePath(rstudioapi::getActiveDocumentContext()$path)),
         error = function(e) getwd()))
source(file.path(.dir, "00_setup_convenciones.R"))

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

cat("Divergencia KL: aporte de la genética (bits):\n")
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

# Lectura en términos de probabilidad, para dar contexto concreto:
q_C2_elegida <- calcular_posterior(logLR_A + logLR_B, prior_demografico)[candidatos == "C2"]
p_C2_elegida <- calcular_posterior(logLR_A + logLR_B + logLR_G, prior_demografico)[candidatos == "C2"]

cat(sprintf("\nLectura en probabilidad (convención elegida, prior demográfico):\n"))
cat(sprintf("  Antes de la genética, P(C2) = %.1f%%  (casi un empate con C4)\n", q_C2_elegida * 100))
cat(sprintf("  Después de la genética, P(C2) = %.1f%%\n", p_C2_elegida * 100))
cat("\nInterpretación (criterio de la consigna): KL de ~1 bit indica que la\n")
cat("genética movió la posterior de manera sustantiva: pasó de un cuasi-empate\n")
cat("a una identificación prácticamente cierta. No 'confirmó nomás' lo que ya\n")
cat("estaba establecido, aunque tampoco arrancó de la nada.\n")


# ============================================================================

orden_AG <- c("A1+G1", "A1+G2", "A2+G1", "A2+G2")

kl_plot_df <- kl_tabla %>%
  mutate(
    prior = recode(prior,
                    demografico = "Prior demográfico",
                    uniforme    = "Prior uniforme"),
    conv_B_raw     = str_extract(combinacion, "B[12]"),
    conv_B_label   = recode(conv_B_raw,
                             B1 = "B1: OSINT estricta",
                             B2 = "B2: OSINT moderada"),
    combinacion_AG = str_remove(combinacion, "\\+B[12]"),
    combinacion_AG = factor(combinacion_AG, levels = orden_AG),
    elegida        = combinacion == comb_elegida
  )

kl_elegida_df <- filter(kl_plot_df, elegida)

g <- ggplot(kl_plot_df, aes(x = combinacion_AG, y = KL_bits, fill = prior)) +
  geom_col(position = position_dodge(width = 0.85), width = 0.75) +
  geom_col(data = kl_elegida_df,
           position = position_dodge(width = 0.85), width = 0.75,
           color = "#8D3708", linewidth = 1.1, show.legend = FALSE) +
  geom_text(aes(label = sprintf("%.2f", KL_bits)),
            position = position_dodge(width = 0.85),
            vjust = -0.4, size = 3) +
  scale_fill_manual(values = c("Prior demográfico" = "#0D2847",
                                "Prior uniforme"        = "#EFC88B")) +
  scale_y_continuous(limits = c(0, max(kl_plot_df$KL_bits) * 1.18),
                      expand = expansion(mult = c(0, 0.02))) +
  facet_wrap(~ conv_B_label) +
  labs(
    title    = "Aporte informacional de la línea genética",
    subtitle = "KL(posterior con genética || posterior sin genética)  ·  borde resaltado = convención elegida (A2+B2+G1)",
    x        = "Combinación A + G (paneles separan B1 / B2)",
    y        = "Divergencia KL (bits)",
    fill     = NULL
  ) +
  theme_minimal(base_size = 12) +
  theme(
    axis.text.x     = element_text(angle = 0, hjust = 0.5),
    plot.title      = element_text(face = "bold"),
    plot.subtitle   = element_text(color = "gray40", size = 9),
    legend.position = "top",
    strip.text      = element_text(face = "bold", color = "#0D2847")
  )

ggsave(file.path(GRAFICOS_DIR, "03_kl_genetica.png"),
       g, width = 9.5, height = 5.5, dpi = 150)
cat("\nEscrito: 03_kl_genetica.png\n")
