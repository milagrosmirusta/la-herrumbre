# ============================================================================
# 04_sensibilidad_lambda.R
# Caso A "La Herrumbre" — Causa 1872/2024

# ============================================================================

.dir <- tryCatch(dirname(normalizePath(sys.frame(1)$ofile)),
         error = function(e) tryCatch(dirname(normalizePath(rstudioapi::getActiveDocumentContext()$path)),
         error = function(e) getwd()))
source(file.path(.dir, "00_setup_convenciones.R"))

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
# Gráficos — versión revisada (log-scale + zoom + actualización por etapas)
# ============================================================================

library(grid)

# directorio ya definido en 00_setup_convenciones.R
cores <- COLORES_HIPOTESIS

tema <- function(base_size = 12) {
  theme_minimal(base_size = base_size) +
    theme(
      plot.title        = element_text(face = "bold"),
      panel.grid.minor  = element_blank(),
      panel.background  = element_rect(fill = "white", color = NA),
      plot.background   = element_rect(fill = "white", color = NA),
      legend.background = element_rect(fill = "white", color = NA),
      legend.position   = "top"
    )
}

guardar <- function(nombre, grafico, width = 9, height = 5.5) {
  ggsave(
    file.path(GRAFICOS_DIR, nombre),
    grafico,
    width  = width,
    height = height,
    dpi    = 150,
    bg     = "white"
  )
  cat("Escrito:", nombre, "\n")
}

fmt_pct              <- function(x) sprintf("%.1f%%", 100 * x)
fmt_decimal_coma_trim <- function(x, digits = 2) {
  salida <- gsub(".", ",", sprintf(paste0("%.", digits, "f"), x), fixed = TRUE)
  salida <- sub(",0+$", "", salida)
  salida <- sub("(,[0-9]*?)0+$", "\\1", salida)
  salida
}
log10_seguro <- function(x) log10(pmax(x, 1e-300))

prior_labels <- c(
  demografico = "Prior demográfico",
  uniforme    = "Prior uniforme"
)
PRIOR_DEMO <- prior_labels[["demografico"]]
PRIOR_UNIF <- prior_labels[["uniforme"]]

# Reconstruir datos_lambda con priors etiquetados
datos_lambda <- map_dfr(LAMBDAS, function(lam) {
  map_dfr(names(priors), function(pr) {
    lrt  <- logLR_A + logLR_B + lam * logLR_G
    post <- calcular_posterior(lrt, priors[[pr]])
    tibble(
      lambda    = lam,
      prior     = prior_labels[[pr]],
      hipotesis = candidatos,
      posterior = post
    )
  })
}) %>%
  mutate(
    hipotesis  = factor(hipotesis, levels = candidatos),
    log10_post = log10_seguro(posterior)
  )

lambda_umbral_general <- datos_lambda %>%
  filter(hipotesis == "C2", posterior >= UMBRAL_DECISION) %>%
  group_by(prior) %>%
  summarise(lambda_min = min(lambda), .groups = "drop")

PISO_POSTERIOR_LAMBDA <- 1e-10
Y_LAMBDA_UMBRAL       <- -0.45
Y_LAMBDA_SUPERIOR     <- 0.6

mapear_y_lambda <- function(p) {
  p         <- pmax(p, PISO_POSTERIOR_LAMBDA)
  y         <- log10(p)
  idx_medio <- p > 0.1 & p < UMBRAL_DECISION
  idx_alto  <- p >= UMBRAL_DECISION
  y[idx_medio] <- -1 + (
    (p[idx_medio] - 0.1) / (UMBRAL_DECISION - 0.1)
  ) * (Y_LAMBDA_UMBRAL + 1)
  y[idx_alto] <- Y_LAMBDA_UMBRAL + (
    (p[idx_alto] - UMBRAL_DECISION) / (1 - UMBRAL_DECISION)
  ) * abs(Y_LAMBDA_UMBRAL)
  y
}

y_lambda_exponentes  <- seq(-10, 0, by = 1)
y_lambda_breaks      <- y_lambda_exponentes
y_lambda_labels      <- paste0("10^", y_lambda_exponentes)
y_lambda_labels[[1]] <- "<=10^-10"

datos_lambda <- datos_lambda %>%
  mutate(
    posterior_plot = pmax(posterior, PISO_POSTERIOR_LAMBDA),
    y_lambda       = mapear_y_lambda(posterior_plot)
  )

datos_lambda_piso <- datos_lambda %>%
  filter(posterior <= PISO_POSTERIOR_LAMBDA)

g04 <- ggplot(datos_lambda,
              aes(x = lambda, y = y_lambda, color = hipotesis,
                  group = hipotesis)) +
  geom_vline(data = lambda_umbral_general,
             aes(xintercept = lambda_min),
             linetype = "dotted", color = "gray35", linewidth = 0.9) +
  geom_hline(yintercept = mapear_y_lambda(UMBRAL_DECISION),
             linetype = "dashed", color = "red", linewidth = 1.0) +
  geom_line(linewidth = 0.9) +
  geom_point(size = 2.7) +
  geom_line(data = datos_lambda_piso, linewidth = 1.25, alpha = 0.9) +
  geom_point(data = datos_lambda_piso, size = 3.0, alpha = 0.95) +
  annotate("text", x = 0.72, y = Y_LAMBDA_UMBRAL - 0.38,
           label = "Umbral 0,95", hjust = 0, color = "red", size = 3.3,
           fontface = "bold") +
  facet_wrap(~ prior, ncol = 1) +
  scale_color_manual(values = cores) +
  scale_x_continuous(breaks = LAMBDAS, limits = c(-0.02, 1.02)) +
  scale_y_continuous(
    limits = c(log10(PISO_POSTERIOR_LAMBDA), Y_LAMBDA_SUPERIOR),
    breaks = y_lambda_breaks,
    labels = y_lambda_labels,
    expand = expansion(mult = c(0, 0.02))
  ) +
  labs(
    title = "Sensibilidad al peso genético",
    x     = "λ aplicado al log10 LR genético",
    y     = "Probabilidad posterior",
    color = "Hipótesis"
  ) +
  tema(12) +
  theme(
    strip.background   = element_rect(fill = "gray92", color = NA),
    strip.text         = element_text(face = "bold"),
    panel.grid.major.y = element_line(color = "gray84", linewidth = 0.45)
  )

guardar("04_sensibilidad_lambda.png", g04, width = 10.5, height = 10.5)

datos_lambda_top2 <- datos_lambda %>%
  filter(hipotesis %in% c("C2", "C4"))

lambda_umbral <- datos_lambda_top2 %>%
  filter(hipotesis == "C2", posterior >= UMBRAL_DECISION) %>%
  group_by(prior) %>%
  summarise(lambda_min = min(lambda), .groups = "drop")

g04_zoom_general <- g04 +
  annotate("rect",
           xmin = -0.02, xmax = 0.32,
           ymin = mapear_y_lambda(0.10), ymax = mapear_y_lambda(1),
           fill = NA, color = "gray20", linewidth = 1.3,
           linetype = "solid")

g04_zoom_detalle <- ggplot(datos_lambda_top2,
                           aes(x = lambda, y = posterior, color = hipotesis,
                               group = hipotesis)) +
  geom_hline(yintercept = UMBRAL_DECISION, linetype = "dashed",
             color = "red", linewidth = 0.8) +
  geom_vline(data = lambda_umbral,
             aes(xintercept = lambda_min),
             linetype = "dotted", color = "gray35", linewidth = 0.7) +
  geom_line(linewidth = 1.1) +
  geom_point(size = 3) +
  facet_wrap(~ prior, ncol = 1) +
  scale_color_manual(values = cores[c("C2", "C4")]) +
  scale_x_continuous(breaks = LAMBDAS) +
  scale_y_continuous(limits = c(0, 1.05), labels = fmt_pct) +
  labs(
    title = "C2 y C4",
    x     = "λ aplicado al log10 LR genético",
    y     = "Probabilidad posterior",
    color = "Hipótesis"
  ) +
  tema(11) +
  theme(
    legend.position  = "none",
    strip.background = element_rect(fill = "gray92", color = NA),
    strip.text       = element_text(face = "bold"),
    panel.border     = element_rect(fill = NA, color = "gray25", linewidth = 0.7)
  )

guardar_zoom_compuesto <- function(nombre, general, detalle,
                                   width = 14, height = 9.5) {
  png(
    file.path(GRAFICOS_DIR, nombre),
    width  = width,
    height = height,
    units  = "in",
    res    = 150,
    bg     = "white"
  )
  on.exit(dev.off())
  grid.newpage()
  print(general, vp = viewport(x = 0.34, y = 0.49,
                               width = 0.66, height = 0.94))
  print(detalle, vp = viewport(x = 0.83, y = 0.44,
                               width = 0.31, height = 0.84))
  cat("Escrito:", nombre, "\n")
}

guardar_zoom_compuesto(
  "04c_sensibilidad_lambda_zoom_c2_c4.png",
  g04_zoom_general,
  g04_zoom_detalle
)

# ============================================================================
# 07. C2 y C4 durante la actualización por etapas
# ============================================================================

etapas_07 <- list(
  uniforme = list(
    `Antropometria`         = calcular_posterior(logLR_A,
                                                  prior_uniforme),
    `Antropometria + OSINT` = calcular_posterior(logLR_A + logLR_B,
                                                  prior_uniforme),
    `Completa`              = calcular_posterior(logLR_A + logLR_B + logLR_G,
                                                  prior_uniforme)
  ),
  demografico = list(
    `Antropometria`         = calcular_posterior(logLR_A,
                                                  prior_demografico),
    `Antropometria + OSINT` = calcular_posterior(logLR_A + logLR_B,
                                                  prior_demografico),
    `Completa`              = calcular_posterior(logLR_A + logLR_B + logLR_G,
                                                  prior_demografico)
  )
)

datos_etapas <- imap_dfr(etapas_07, function(lista_etapas, nombre_prior) {
  imap_dfr(lista_etapas, function(post, nombre_etapa) {
    tibble(
      prior     = prior_labels[[nombre_prior]],
      etapa     = nombre_etapa,
      hipotesis = candidatos,
      posterior = post
    )
  })
}) %>%
  mutate(
    etapa     = factor(etapa, levels = c("Antropometria",
                                         "Antropometria + OSINT",
                                         "Completa")),
    hipotesis = factor(hipotesis, levels = candidatos)
  )

datos_relato <- datos_etapas %>%
  filter(hipotesis %in% c("C2", "C4")) %>%
  mutate(
    hipotesis   = factor(hipotesis, levels = c("C2", "C4")),
    label_vjust = case_when(
      hipotesis == "C2"       ~ -0.9,
      etapa == "Completa"     ~ -0.9,
      TRUE                    ~ 1.6
    )
  )

g07 <- ggplot(datos_relato,
              aes(x = etapa, y = posterior, color = hipotesis,
                  group = hipotesis)) +
  geom_line(linewidth = 1.15) +
  geom_point(size = 3.2) +
  geom_text(aes(label = fmt_pct(posterior), vjust = label_vjust),
            size = 3.1, show.legend = FALSE) +
  facet_wrap(~ prior) +
  scale_color_manual(values = cores[c("C2", "C4")]) +
  scale_y_continuous(limits = c(0, 1.08), labels = fmt_pct) +
  labs(
    title = "C2 y C4 durante la actualización",
    x     = "Evidencia acumulada",
    y     = "Probabilidad posterior",
    color = "Hipótesis"
  ) +
  scale_x_discrete(labels = c(
    "Antropometria"         = "Antropometría",
    "Antropometria + OSINT" = "Antropometría\n+ OSINT",
    "Completa"              = "Antropometría\n+ OSINT\n+ genética"
  )) +
  tema(12) +
  theme(
    axis.text.x      = element_text(face = "bold"),
    strip.background = element_rect(fill = "gray92", color = NA),
    strip.text       = element_text(face = "bold")
  )

guardar("07_c2_c4_actualizacion.png", g07, width = 10, height = 5.4)

cat(sprintf(
  "\nGraficos revisados escritos en: %s\n",
  GRAFICOS_DIR
))
