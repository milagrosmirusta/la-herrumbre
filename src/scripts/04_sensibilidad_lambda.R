# ============================================================================
# 04_sensibilidad_lambda.R
# Caso A "La Herrumbre" — Causa 1872/2024
# ============================================================================
# Evalúa la robustez de la identificación al peso asignado a la genética.
# Se pondera el log-LR genético con un escalar λ:
#
#   log LR_gen  →  λ × log LR_gen
#
#   λ = 0.0 : genética ignorada
#   λ = 1.0 : genética con peso completo (valor del laboratorio)
#
# Se reporta la posterior del candidato más probable para cada λ, bajo
# la convención elegida y ambos priors.
#
# Salidas:
#   resultados/04_sensibilidad_lambda.csv
#   resultados/graficos/04_sensibilidad_lambda.png
# ============================================================================

source("00_setup_convenciones.R")

LAMBDAS <- c(0, 0.3, 0.5, 0.7, 1.0)

# ============================================================================
# Calcular posterior para cada λ × prior
# ============================================================================

priors <- list(
  demografico = prior_demografico,
  uniforme    = prior_uniforme
)

filas <- map_dfr(LAMBDAS, function(lam) {
  map_dfr(names(priors), function(pr) {
    lrt  <- logLR_A + logLR_B + lam * logLR_G
    post <- calcular_posterior(lrt, priors[[pr]])
    tibble(
      lambda    = lam,
      prior     = pr,
      hipotesis = candidatos,
      posterior = post
    )
  })
})

write_csv(filas, file.path(RESULTADOS_DIR, "04_sensibilidad_lambda.csv"))
cat("Escrito: 04_sensibilidad_lambda.csv\n\n")

# ============================================================================
# Decisión forense por λ
# ============================================================================

decision <- filas %>%
  group_by(lambda, prior) %>%
  slice_max(posterior, n = 1, with_ties = FALSE) %>%
  ungroup() %>%
  mutate(
    decision = ifelse(posterior >= UMBRAL_DECISION,
                      "identificación positiva", "indeterminación")
  )

cat(sprintf("Umbral de decisión: %.2f\n\n", UMBRAL_DECISION))
cat("Decisión forense por λ (convención ", CONVENCION_A, "+", CONVENCION_B, "+", CONVENCION_G, "):\n")
decision %>%
  select(lambda, prior, hipotesis, posterior, decision) %>%
  mutate(posterior = round(posterior, 4)) %>%
  arrange(prior, lambda) %>%
  print()

# ¿En qué λ el candidato ganador cambia?
cambios <- decision %>%
  group_by(prior) %>%
  summarise(
    n_candidatos_distintos = n_distinct(hipotesis),
    candidatos = paste(unique(hipotesis), collapse = ", "),
    .groups = "drop"
  )

cat("\n¿El candidato ganador cambia al variar λ?\n")
if (all(cambios$n_candidatos_distintos == 1)) {
  cat("  No. El ganador es estable para todos los λ probados.\n")
} else {
  print(cambios)
}

# λ mínimo para superar el umbral (prior demográfico)
lambda_minimo <- decision %>%
  filter(prior == "demografico", decision == "identificación positiva") %>%
  summarise(lambda_min = min(lambda)) %>%
  pull(lambda_min)

cat(sprintf(
  "\nλ mínimo para superar %.2f (prior demográfico): λ = %.1f\n",
  UMBRAL_DECISION, lambda_minimo
))

# ============================================================================
# Gráfico
# ============================================================================

cores_hipotesis <- c(H0 = "#636363", C1 = "#377eb8", C2 = "#4daf4a",
                     C3 = "#ff7f00", C4 = "#984ea3", C5 = "#e41a1c")

g <- filas %>%
  mutate(prior = recode(prior,
                        demografico = "Prior demográfico",
                        uniforme    = "Prior uniforme"),
         hipotesis = factor(hipotesis, levels = candidatos)) %>%
  ggplot(aes(x = lambda, y = posterior, color = hipotesis, group = hipotesis)) +
  geom_line(linewidth = 1) +
  geom_point(size = 2.5) +
  geom_hline(yintercept = UMBRAL_DECISION,
             linetype = "dashed", color = "red", linewidth = 0.8) +
  annotate("text", x = 0.05, y = UMBRAL_DECISION + 0.03,
           label = sprintf("Umbral %.2f", UMBRAL_DECISION),
           color = "red", hjust = 0, size = 3.5) +
  facet_wrap(~ prior) +
  scale_color_manual(values = cores_hipotesis) +
  scale_x_continuous(breaks = LAMBDAS) +
  labs(
    title    = "Sensibilidad al peso λ de la genética",
    subtitle = sprintf("Convención: %s+%s+%s",
                       CONVENCION_A, CONVENCION_B, CONVENCION_G),
    x        = "λ  (factor de ponderación de log LR_gen)",
    y        = "Probabilidad posterior",
    color    = "Hipótesis"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.title    = element_text(face = "bold"),
    plot.subtitle = element_text(color = "gray40"),
    legend.position = "right"
  ) +
  ylim(0, 1.02)

ggsave(file.path(GRAFICOS_DIR, "04_sensibilidad_lambda.png"),
       g, width = 10, height = 5.5, dpi = 150)
cat("\nEscrito: 04_sensibilidad_lambda.png\n")
