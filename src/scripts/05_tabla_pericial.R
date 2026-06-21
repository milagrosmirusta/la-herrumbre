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

source("00_setup_convenciones.R")

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
# Imprimir en consola con decisión
# ============================================================================

cat(sprintf("TABLA PERICIAL — Convención %s+%s+%s | Prior demográfico\n",
            CONVENCION_A, CONVENCION_B, CONVENCION_G))
cat(strrep("=", 70), "\n")
print(tabla_pericial)

idx_max  <- which.max(posterior)
cat(sprintf(
  "\nCandidato con mayor posterior: %s  [P = %.6f]\n",
  candidatos[idx_max], posterior[idx_max]
))
cat(sprintf(
  "Decisión forense (umbral %.2f): %s\n",
  UMBRAL_DECISION,
  ifelse(posterior[idx_max] >= UMBRAL_DECISION,
         "IDENTIFICACIÓN POSITIVA", "INDETERMINACIÓN")
))

# ============================================================================
# Imagen de la tabla (para PPT)
# ============================================================================

# Preparar datos para visualización: mostrar P(H|E) con notación científica
# cuando es muy pequeño o muy grande
tabla_img <- tabla_pericial %>%
  mutate(
    `P(Hᵢ|E)` = case_when(
      `P(Hᵢ|E)` >= 0.001 ~ sprintf("%.4f", `P(Hᵢ|E)`),
      TRUE                ~ sprintf("%.2e", `P(Hᵢ|E)`)
    )
  )

# Colores: resaltar la fila ganadora
fila_ganadora <- idx_max
n_filas       <- nrow(tabla_img)
colores_fill  <- rep("white", n_filas)
colores_fill[fila_ganadora] <- "#c8e6c9"   # verde claro para el ganador
colores_text  <- rep("black", n_filas)

# Construir tabla con gridExtra
library(grid)
library(gridExtra)

# tableGrob no acepta vectores de color directamente en versiones viejas;
# usamos theme personalizado
tema_tabla <- ttheme_default(
  core = list(
    bg_params  = list(fill = colores_fill, col = "gray70"),
    fg_params  = list(col = colores_text, fontsize = 11)
  ),
  colhead = list(
    bg_params  = list(fill = "#37474f"),
    fg_params  = list(col = "white", fontsize = 11, fontface = "bold")
  )
)

grob_tabla <- tableGrob(tabla_img, rows = NULL, theme = tema_tabla)

# Título y subtítulo
titulo <- textGrob(
  sprintf("Tabla Pericial — %s+%s+%s | Prior demográfico",
          CONVENCION_A, CONVENCION_B, CONVENCION_G),
  gp = gpar(fontsize = 13, fontface = "bold")
)
subtitulo <- textGrob(
  sprintf("Umbral de identificación positiva: %.2f  |  Ganador: %s  [P ≈ %.4f]",
          UMBRAL_DECISION, candidatos[idx_max], posterior[idx_max]),
  gp = gpar(fontsize = 10, col = "gray40")
)

imagen_final <- arrangeGrob(
  titulo, subtitulo, grob_tabla,
  nrow = 3,
  heights = unit(c(0.8, 0.5, 5), c("cm", "cm", "null"))
)

png(file.path(GRAFICOS_DIR, "05_tabla_pericial.png"),
    width = 1200, height = 420, res = 120)
grid.draw(imagen_final)
dev.off()

cat("\nEscrito: 05_tabla_pericial.png\n")
