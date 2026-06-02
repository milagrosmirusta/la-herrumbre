# ==============================================================================
# Caso A "La Herrumbre" - Paso 6: Sensibilidad al peso lambda de la genetica
# ==============================================================================
# Pondera la linea genetica con un escalar lambda en escala log:
#     log LR_gen  ->  lambda * log LR_gen
# lambda = 0 ignora la genetica; lambda = 1 la usa entera.
# Se recorre lambda in {0, 0.3, 0.5, 0.7, 1.0} para las 8 combinaciones
# canonicas y los dos priors, y se observa a que valor de lambda cambia
# (si llega a cambiar) el candidato mas probable, y la decision forense
# con umbral 0.95.
#
# Como correr (working dir en esta carpeta):
#   Rscript sensibilidad_lambda.R
# ==============================================================================

suppressMessages({
  library(dplyr)
  library(readr)
  library(tidyr)
  library(ggplot2)
})

dir.create("salidas", showWarnings = FALSE)

# ------------------------------------------------------------------------------
# 1. Datos y estructuras
# ------------------------------------------------------------------------------
antropometrico <- read_csv("../tablas_A_antropometrica.csv", show_col_types = FALSE)
osint          <- read_csv("../tablas_B_osint.csv",          show_col_types = FALSE)
robustez       <- read_csv("../tablas_G_robustez.csv",       show_col_types = FALSE)

caso <- c("H0", antropometrico$candidato)

priors <- list(
  demografica = c(0.20, 0.18, 0.22, 0.12, 0.20, 0.08),
  uniforme    = rep(1/6, 6)
)

logLR <- list(
  A = list(A1 = c(0, antropometrico$A1_log10_LR),
           A2 = c(0, antropometrico$A2_log10_LR)),
  B = list(B1 = c(0, osint$B1_log10_LR),
           B2 = c(0, osint$B2_log10_LR)),
  G = list(G1 = c(0, robustez$G1_log10_LR_efectivo),
           G2 = c(0, robustez$G2_log10_LR_efectivo))
)

posterior_desde_log10 <- function(log_evidencia) {
  log_post <- log_evidencia - max(log_evidencia)
  normalizador <- log10(sum(10^log_post))
  10^(log_post - normalizador)
}

UMBRAL <- 0.95
lambdas <- c(0, 0.3, 0.5, 0.7, 1.0)

# ------------------------------------------------------------------------------
# 2. Barrido: combinacion x prior x lambda
# ------------------------------------------------------------------------------
grilla <- expand.grid(
  A = c("A1", "A2"), B = c("B1", "B2"), G = c("G1", "G2"),
  prior = c("demografica", "uniforme"),
  lambda = lambdas,
  stringsAsFactors = FALSE
)

filas <- vector("list", nrow(grilla))
for (i in seq_len(nrow(grilla))) {
  f <- grilla[i, ]
  log_prior <- log10(priors[[f$prior]])
  lrA <- logLR$A[[f$A]]; lrB <- logLR$B[[f$B]]; lrG <- logLR$G[[f$G]]

  post <- posterior_desde_log10(log_prior + lrA + lrB + f$lambda * lrG)

  filas[[i]] <- tibble(
    combinacion = paste(f$A, f$B, f$G, sep = "+"),
    prior       = f$prior,
    lambda      = f$lambda,
    caso        = caso,
    posterior   = post
  )
}
detalle <- bind_rows(filas)
write_csv(detalle, "salidas/sensibilidad_lambda_detalle.csv")
cat("Escrito: salidas/sensibilidad_lambda_detalle.csv  (", nrow(detalle), "filas )\n")

# ------------------------------------------------------------------------------
# 3. Decision forense por (combinacion, prior, lambda)
# ------------------------------------------------------------------------------
decision <- detalle %>%
  group_by(combinacion, prior, lambda) %>%
  slice_max(posterior, n = 1, with_ties = FALSE) %>%
  ungroup() %>%
  transmute(
    combinacion, prior, lambda,
    candidato_mas_probable = caso,
    posterior_max = posterior,
    decision = if_else(posterior_max >= UMBRAL,
                       "identificacion positiva", "indeterminacion")
  ) %>%
  arrange(prior, combinacion, lambda)

write_csv(decision, "salidas/sensibilidad_lambda_decision.csv")
cat("Escrito: salidas/sensibilidad_lambda_decision.csv\n\n")

# ------------------------------------------------------------------------------
# 4. A que lambda aparece la identificacion positiva (por combinacion/prior)
# ------------------------------------------------------------------------------
umbral_lambda <- decision %>%
  filter(decision == "identificacion positiva") %>%
  group_by(combinacion, prior, candidato_mas_probable) %>%
  summarise(lambda_minimo_positivo = min(lambda), .groups = "drop") %>%
  arrange(prior, combinacion)

cat("Lambda minimo para superar el umbral", UMBRAL, "(identificacion positiva):\n")
print(as.data.frame(umbral_lambda))

# Cambia el candidato mas probable al mover lambda?
cambios <- decision %>%
  group_by(combinacion, prior) %>%
  summarise(n_candidatos_distintos = n_distinct(candidato_mas_probable),
            candidatos = paste(unique(candidato_mas_probable), collapse = ", "),
            .groups = "drop") %>%
  filter(n_candidatos_distintos > 1)
cat("\nCombinaciones donde el candidato mas probable CAMBIA segun lambda:\n")
if (nrow(cambios) == 0) {
  cat("  Ninguna. El candidato ganador es estable; lambda solo afecta su masa.\n")
} else {
  print(as.data.frame(cambios))
}

# ------------------------------------------------------------------------------
# 5. Grafico: posterior del candidato ganador vs lambda
# ------------------------------------------------------------------------------
g <- decision %>%
  ggplot(aes(x = lambda, y = posterior_max,
             color = combinacion, linetype = prior)) +
  geom_line() +
  geom_point(size = 1.5) +
  geom_hline(yintercept = UMBRAL, linetype = "dashed", color = "red") +
  annotate("text", x = 0.05, y = UMBRAL + 0.02, label = "umbral 0.95",
           color = "red", hjust = 0, size = 3) +
  ylim(0, 1.02) +
  labs(title = "Sensibilidad al peso lambda de la genetica",
       subtitle = "Posterior del candidato mas probable",
       x = expression(lambda), y = "P(H ganador | E)") +
  theme_bw()
ggsave("salidas/grafico_sensibilidad_lambda.png", g, width = 9, height = 5.5, dpi = 150)
cat("\nEscrito: salidas/grafico_sensibilidad_lambda.png\n")
