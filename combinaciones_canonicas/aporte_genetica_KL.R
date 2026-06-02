# ==============================================================================
# Caso A "La Herrumbre" - Paso 5: Aporte informacional de la linea genetica (KL)
# ==============================================================================
# Cuantifica cuanta informacion agrega la genetica con la divergencia de
# Kullback-Leibler entre la posterior SIN genetica (prior + A + B) y la
# posterior completa (prior + A + B + G):
#
#   KL( P(H|E_full) || P(H|E_antB) ) = sum_i P(H|E_full) * log( P_full / P_antB )
#
# Se reporta en bits (log2) y en nats (log natural), para las 8 combinaciones
# canonicas y los dos priors.
#
# Como correr (working dir en esta carpeta):
#   Rscript aporte_genetica_KL.R
# ==============================================================================

suppressMessages({
  library(dplyr)
  library(readr)
  library(tidyr)
  library(ggplot2)
})

dir.create("salidas", showWarnings = FALSE)

# ------------------------------------------------------------------------------
# 1. Datos y estructuras (mismo armado que combinaciones_canonicas.R)
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

# ------------------------------------------------------------------------------
# 2. Divergencia KL( P || Q )
# ------------------------------------------------------------------------------
# base = 2 -> bits ; base = exp(1) -> nats. Se omiten terminos con P=0.
kl_divergencia <- function(P, Q, base = 2) {
  idx <- P > 0
  sum(P[idx] * (log(P[idx] / Q[idx]) / log(base)))
}

# ------------------------------------------------------------------------------
# 3. Barrido: KL por combinacion y prior
# ------------------------------------------------------------------------------
grilla <- expand.grid(
  A = c("A1", "A2"), B = c("B1", "B2"), G = c("G1", "G2"),
  prior = c("demografica", "uniforme"),
  stringsAsFactors = FALSE
)

filas <- vector("list", nrow(grilla))
for (i in seq_len(nrow(grilla))) {
  f <- grilla[i, ]
  log_prior <- log10(priors[[f$prior]])
  lrA <- logLR$A[[f$A]]; lrB <- logLR$B[[f$B]]; lrG <- logLR$G[[f$G]]

  P_sinG <- posterior_desde_log10(log_prior + lrA + lrB)         # Q
  P_full <- posterior_desde_log10(log_prior + lrA + lrB + lrG)   # P

  filas[[i]] <- tibble(
    combinacion = paste(f$A, f$B, f$G, sep = "+"),
    prior       = f$prior,
    KL_bits     = kl_divergencia(P_full, P_sinG, base = 2),
    KL_nats     = kl_divergencia(P_full, P_sinG, base = exp(1))
  )
}
kl_tabla <- bind_rows(filas) %>% arrange(prior, combinacion)

write_csv(kl_tabla, "salidas/aporte_genetica_KL.csv")
cat("Escrito: salidas/aporte_genetica_KL.csv\n\n")
cat("Divergencia KL (posterior con genetica vs sin genetica):\n")
print(as.data.frame(kl_tabla %>% mutate(across(starts_with("KL"), ~round(., 3)))))

# ------------------------------------------------------------------------------
# 4. Grafico: KL en bits por combinacion, comparando priors
# ------------------------------------------------------------------------------
g <- ggplot(kl_tabla, aes(x = combinacion, y = KL_bits, fill = prior)) +
  geom_col(position = "dodge") +
  geom_text(aes(label = round(KL_bits, 1)),
            position = position_dodge(width = 0.9), vjust = -0.3, size = 2.6) +
  labs(title = "Aporte informacional de la linea genetica (divergencia KL)",
       subtitle = "KL( posterior con genetica || posterior sin genetica )",
       x = "Combinacion canonica", y = "KL (bits)") +
  theme_bw() +
  theme(axis.text.x = element_text(angle = 30, hjust = 1))
ggsave("salidas/grafico_aporte_genetica_KL.png", g, width = 9, height = 5, dpi = 150)
cat("\nEscrito: salidas/grafico_aporte_genetica_KL.png\n")
