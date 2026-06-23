# ============================================================================
# 05_tabla_pericial.R
# Caso A "La Herrumbre" — Causa 1872/2024
# ============================================================================
# Genera la tabla pericial final del dictamen bayesiano:
#
#   Columnas por hipótesis (H0–C5):
#     πᵢ         — prior demográfico
#     log10 LR_ant — línea antropométrica
#     log10 LR_abi — línea de fuentes abiertas (OSINT)
#     log10 LR_gen — línea genética
#     log10 LR_tot — suma total
#     P(Hᵢ|E)    — posterior bajo prior demográfico
#
# Salidas:
#   resultados/05_tabla_pericial.csv
#   resultados/graficos/05_tabla_pericial.png   (imagen lista para PPT)
# ============================================================================

.dir <- tryCatch(dirname(normalizePath(sys.frame(1)$ofile)),
         error = function(e) tryCatch(dirname(normalizePath(rstudioapi::getActiveDocumentContext()$path)),
         error = function(e) getwd()))
source(file.path(.dir, "00_setup_convenciones.R"))

# ============================================================================
# Construir tabla
# ============================================================================

logLR_total <- logLR_A + logLR_B + logLR_G
posterior   <- calcular_posterior(logLR_total, prior_demografico)

tabla_pericial <- tibble(
  Hipótesis   = candidatos,
  `πᵢ`        = round(prior_demografico, 4),
  `log10 LR_ant` = round(logLR_A, 4),
  `log10 LR_abi` = round(logLR_B, 4),
  `log10 LR_gen` = round(logLR_G, 4),
  `log10 LR_tot` = round(logLR_total, 4),
  `P(Hᵢ|E)`   = round(posterior, 6)
)

write_csv(tabla_pericial,
          file.path(RESULTADOS_DIR, "05_tabla_pericial.csv"))
cat("Escrito: 05_tabla_pericial.csv\n\n")

# ============================================================================
# Imprimir tabla en consola
# ============================================================================

cat(sprintf("TABLA PERICIAL — Convención %s+%s+%s\n",
            CONVENCION_A, CONVENCION_B, CONVENCION_G))
cat(strrep("=", 70), "\n")
print(tabla_pericial)

# ============================================================================
# Decisión forense — regla completa del Paso 6 (consigna)
#
# Identificación positiva si:
#   (a) ganador supera UMBRAL_DECISION bajo prior uniforme, Y
#   (b) ganador supera UMBRAL_DECISION bajo prior demográfico, Y
#   (c) ganador supera UMBRAL_DECISION con λ ≥ 0.5 (genética al 50%)
#
# Si (a) y (b) se cumplen pero no (c) → INDETERMINACIÓN (depende de genética entera)
# ============================================================================

# Condición (a): prior uniforme
post_unif   <- calcular_posterior(logLR_total, prior_uniforme)
P_unif      <- max(post_unif)
gan_unif    <- candidatos[which.max(post_unif)]

# Condición (b): prior demográfico (ya calculado)
idx_max     <- which.max(posterior)
P_demo      <- posterior[idx_max]
gan_demo    <- candidatos[idx_max]

# Condición (c): sensibilidad λ (prior demográfico)
LAMBDAS     <- c(0, 0.3, 0.5, 0.7, 1.0)
post_lambda <- sapply(LAMBDAS, function(lam) {
  lrt  <- logLR_A + logLR_B + lam * logLR_G
  max(calcular_posterior(lrt, prior_demografico))
})
names(post_lambda) <- paste0("lambda=", LAMBDAS)

P_lambda05  <- post_lambda["lambda=0.5"]
cond_a      <- P_unif    >= UMBRAL_DECISION
cond_b      <- P_demo    >= UMBRAL_DECISION
cond_c      <- P_lambda05 >= UMBRAL_DECISION

cat(sprintf("\n%s\n", strrep("=", 70)))
cat("DECISIÓN FORENSE — Paso 6\n")
cat(sprintf("%s\n", strrep("=", 70)))
cat(sprintf("  (a) Prior uniforme    → %s  [P = %.4f]  %s\n",
    gan_unif, P_unif, ifelse(cond_a, "✓ supera umbral", "✗ no supera umbral")))
cat(sprintf("  (b) Prior demográfico → %s  [P = %.4f]  %s\n",
    gan_demo, P_demo, ifelse(cond_b, "✓ supera umbral", "✗ no supera umbral")))
cat(sprintf("  (c) λ = 0.5 (genética al 50%%) → P = %.4f  %s\n",
    P_lambda05, ifelse(cond_c, "✓ supera umbral", "✗ no supera umbral")))

cat("\n  Sensibilidad λ completa (prior demográfico):\n")
for (nm in names(post_lambda)) {
  cat(sprintf("    %s → P(%s|E) = %.6f  %s\n",
      nm, gan_demo, post_lambda[nm],
      ifelse(post_lambda[nm] >= UMBRAL_DECISION,
             sprintf(">= %.2f", UMBRAL_DECISION),
             sprintf("<  %.2f", UMBRAL_DECISION))))
}

lambda_min <- LAMBDAS[min(which(post_lambda >= UMBRAL_DECISION))]
cat(sprintf("\n  Lambda minimo para superar %.2f: lambda = %.1f\n",
            UMBRAL_DECISION, lambda_min))

cat(sprintf("\n%s\n", strrep("-", 70)))
if (cond_a && cond_b && cond_c) {
  cat(sprintf("  IDENTIFICACION POSITIVA: %s\n", gan_demo))
  cat("  Robusto bajo ambos priors y lambda >= 0.5\n")
} else if (cond_a && cond_b && !cond_c) {
  cat(sprintf("  INDETERMINACION\n"))
  cat(sprintf("  %s supera el umbral bajo ambos priors,\n", gan_demo))
  cat("  pero la conclusion depende de lambda = 1.0 (genetica integra).\n")
  cat("  Reportar conclusion condicionada al peritaje genetico.\n")
} else {
  cat("  INDETERMINACION\n")
  cat("  El candidato no supera el umbral bajo todas las configuraciones requeridas.\n")
}
cat(sprintf("%s\n", strrep("-", 70)))

# ============================================================================
# Imagen de la tabla — versión revisada
# ============================================================================

library(grid)
library(gridExtra)

# directorio ya definido en 00_setup_convenciones.R
fmt_decimal_coma <- function(x, digits) {
  gsub(".", ",", sprintf(paste0("%.", digits, "f"), x), fixed = TRUE)
}

fmt_decimal_coma_trim <- function(x, digits = 2) {
  salida <- fmt_decimal_coma(x, digits)
  salida <- sub(",0+$", "", salida)
  salida <- sub("(,[0-9]*?)0+$", "\\1", salida)
  salida
}

fmt_cientifica_coma <- function(x, digits = 2) {
  mantisa   <- x / 10^floor(log10(abs(x)))
  exponente <- floor(log10(abs(x)))
  paste0(fmt_decimal_coma_trim(mantisa, digits), " × 10^", exponente)
}

fmt_prob_pericial <- function(x) {
  case_when(
    x >= 0.001 ~ fmt_decimal_coma_trim(x, 2),
    x > 0      ~ fmt_cientifica_coma(x, 2),
    TRUE       ~ "0"
  )
}

tabla_pericial_img <- tibble(
  Hipotesis      = candidatos,
  pi             = fmt_decimal_coma_trim(prior_demografico, 2),
  `log10 LR_ant` = fmt_decimal_coma_trim(logLR_A, 2),
  `log10 LR_abi` = fmt_decimal_coma_trim(logLR_B, 2),
  `log10 LR_gen` = fmt_decimal_coma_trim(logLR_G, 2),
  `log10 LR_tot` = fmt_decimal_coma_trim(logLR_total, 2),
  `P(H|E)`       = fmt_prob_pericial(posterior)
)
names(tabla_pericial_img)[1] <- "Hipótesis"

fills_p <- rep("white", nrow(tabla_pericial_img))
fills_p[idx_max] <- COLORES_HIPOTESIS[["C2"]]

tema_pericial <- ttheme_default(
  core = list(
    bg_params = list(fill = fills_p, col = "gray70"),
    fg_params = list(fontsize = 11)
  ),
  colhead = list(
    bg_params = list(fill = "#37474f"),
    fg_params = list(col = "white", fontsize = 11, fontface = "bold")
  )
)

grob_pericial <- tableGrob(tabla_pericial_img, rows = NULL,
                            theme = tema_pericial)
titulo_pericial <- textGrob(
  "Tabla pericial bayesiana",
  gp = gpar(fontsize = 13, fontface = "bold")
)
img_pericial <- arrangeGrob(titulo_pericial, grob_pericial,
                             nrow    = 2,
                             heights = unit(c(0.8, 5), c("cm", "null")))

png(file.path(GRAFICOS_DIR, "05_tabla_pericial.png"),
    width = 1450, height = 400, res = 120, bg = "white")
grid.draw(img_pericial)
dev.off()
cat("Escrito: 05_tabla_pericial.png\n")
