# ==============================================================================
# Caso A "La Herrumbre" - Las 8 combinaciones canonicas (A x B x G)
# ==============================================================================
# Calcula la posterior P(H_i | E) para las 8 combinaciones de convencion
#   A in {A1, A2}  x  B in {B1, B2}  x  G in {G1, G2}
# bajo dos priors (demografica y uniforme), en escala log10.
#
# Metodo: se suman las log-evidencias (log-prior + logLR_A + logLR_B + logLR_G)
# y se normaliza UNA sola vez al final (log-sum-exp, restando el maximo). Esto
# evita el problema de sumar LR sobre posteriores ya normalizadas.
#
# Como correr: con el working directory en esta carpeta (combinaciones_canonicas/):
#   Rscript combinaciones_canonicas.R
# Los CSV de datos se leen de la carpeta padre (..).
# ==============================================================================

suppressMessages({
  library(dplyr)
  library(readr)
  library(tidyr)
  library(ggplot2)
})

dir.create("salidas", showWarnings = FALSE)

# ------------------------------------------------------------------------------
# 1. Lectura de datos (LR ya calculados por el laboratorio)
# ------------------------------------------------------------------------------
antropometrico <- read_csv("../tablas_A_antropometrica.csv", show_col_types = FALSE)
osint          <- read_csv("../tablas_B_osint.csv",          show_col_types = FALSE)
robustez       <- read_csv("../tablas_G_robustez.csv",       show_col_types = FALSE)
ground_truth   <- read_csv("../tablas_resumen_combinaciones.csv", show_col_types = FALSE)

# ------------------------------------------------------------------------------
# 2. Hipotesis y priors
# ------------------------------------------------------------------------------
# Orden de hipotesis: H0 (residual) + los cinco candidatos
caso <- c("H0", antropometrico$candidato)

priors <- list(
  demografica = c(0.20, 0.18, 0.22, 0.12, 0.20, 0.08),
  uniforme    = rep(1/6, 6)
)

# ------------------------------------------------------------------------------
# 3. Tablas de log10-LR por convencion (H0 = 0 porque LR(H0) = 1)
# ------------------------------------------------------------------------------
logLR <- list(
  A = list(A1 = c(0, antropometrico$A1_log10_LR),
           A2 = c(0, antropometrico$A2_log10_LR)),
  B = list(B1 = c(0, osint$B1_log10_LR),
           B2 = c(0, osint$B2_log10_LR)),
  G = list(G1 = c(0, robustez$G1_log10_LR_efectivo),
           G2 = c(0, robustez$G2_log10_LR_efectivo))
)

# ------------------------------------------------------------------------------
# 4. Funcion reutilizable: posterior a partir de log-evidencias
# ------------------------------------------------------------------------------
# Recibe el log10-numerador (ya sumado) y devuelve la posterior normalizada.
posterior_desde_log10 <- function(log_evidencia) {
  log_post <- log_evidencia - max(log_evidencia)  # estabilidad numerica
  normalizador <- log10(sum(10^log_post))
  10^(log_post - normalizador)
}

# ------------------------------------------------------------------------------
# 5. Barrido de las 8 combinaciones x 2 priors
# ------------------------------------------------------------------------------
grilla <- expand.grid(
  A = c("A1", "A2"), B = c("B1", "B2"), G = c("G1", "G2"),
  prior = c("demografica", "uniforme"),
  stringsAsFactors = FALSE
)

filas <- vector("list", nrow(grilla))
for (i in seq_len(nrow(grilla))) {
  fila <- grilla[i, ]
  lrA <- logLR$A[[fila$A]]
  lrB <- logLR$B[[fila$B]]
  lrG <- logLR$G[[fila$G]]
  log_prior <- log10(priors[[fila$prior]])

  log10_LR_total <- lrA + lrB + lrG                     # independiente del prior
  evidencia_full <- log_prior + log10_LR_total          # con genetica
  evidencia_sinG <- log_prior + lrA + lrB               # sin genetica

  filas[[i]] <- tibble(
    combinacion          = paste(fila$A, fila$B, fila$G, sep = "+"),
    prior                = fila$prior,
    caso                 = caso,
    log10_LR_total       = log10_LR_total,
    posterior_completa   = posterior_desde_log10(evidencia_full),
    posterior_sin_genetica = posterior_desde_log10(evidencia_sinG)
  )
}
resumen <- bind_rows(filas)

write_csv(resumen, "salidas/resumen_8_combinaciones.csv")
cat("Escrito: salidas/resumen_8_combinaciones.csv  (", nrow(resumen), "filas )\n")

# ------------------------------------------------------------------------------
# 6. Validacion vs. ground-truth (tablas_resumen_combinaciones.csv)
# ------------------------------------------------------------------------------
# El ground-truth usa la columna `candidato` (C1..C5, H0); emparejamos por clave.
gt <- ground_truth %>%
  transmute(
    combinacion,
    caso = candidato,
    gt_log10_LR_total      = log10_LR_total,
    gt_posterior_completo  = posterior_completo,
    gt_posterior_sin_gen   = posterior_sin_genetica
  )

tol <- 1e-3
hacer_validacion <- function(prior_nombre) {
  resumen %>%
    filter(prior == prior_nombre) %>%
    inner_join(gt, by = c("combinacion", "caso")) %>%
    transmute(
      prior = prior_nombre, combinacion, caso,
      dif_log10_LR_total = abs(log10_LR_total - gt_log10_LR_total),
      dif_posterior_completa = abs(posterior_completa - gt_posterior_completo),
      dif_posterior_sin_gen  = abs(posterior_sin_genetica - gt_posterior_sin_gen),
      ok_log10_LR_total      = dif_log10_LR_total < tol,
      ok_posterior_completa  = dif_posterior_completa < tol,
      ok_posterior_sin_gen   = dif_posterior_sin_gen < tol
    )
}

validacion <- bind_rows(hacer_validacion("demografica"),
                        hacer_validacion("uniforme"))
write_csv(validacion, "salidas/validacion_vs_groundtruth.csv")
cat("Escrito: salidas/validacion_vs_groundtruth.csv\n\n")

# Resumen de coincidencias en consola
resumen_val <- validacion %>%
  group_by(prior) %>%
  summarise(
    n = n(),
    log10_LR_total   = sum(ok_log10_LR_total),
    posterior_full   = sum(ok_posterior_completa),
    posterior_sin_G  = sum(ok_posterior_sin_gen),
    .groups = "drop"
  )
cat("Coincidencias dentro de tolerancia (", tol, "):\n", sep = "")
print(as.data.frame(resumen_val))
cat("\n-> El prior que reproduce `posterior_sin_genetica` es el que uso el laboratorio.\n\n")

# ------------------------------------------------------------------------------
# 7. Grafico: posteriores completas por combinacion (prior demografica)
# ------------------------------------------------------------------------------
g <- resumen %>%
  filter(prior == "demografica") %>%
  mutate(caso = factor(caso, levels = caso[seq_along(unique(caso))])) %>%
  ggplot(aes(x = caso, y = posterior_completa, fill = caso)) +
  geom_col() +
  geom_text(aes(label = round(posterior_completa, 2)), vjust = -0.3, size = 2.6) +
  facet_wrap(~combinacion) +
  ylim(0, 1.1) +
  labs(title = "Posterior completa por combinacion canonica (prior demografica)",
       x = "Hipotesis", y = "P(H | E)") +
  theme_bw() +
  theme(legend.position = "none")
ggsave("salidas/grafico_posteriores.png", g, width = 9, height = 6, dpi = 150)
cat("Escrito: salidas/grafico_posteriores.png\n")
