# ============================================================================
# 02_evolucion_posterior_progresiva.R
# Caso A "La Herrumbre" — Causa 1872/2024
# ============================================================================
# Construye la posterior en tres etapas sucesivas bajo AMBOS priors,
# mostrando cómo cada línea de evidencia actualiza la creencia:
#
#   Etapa 1: π × L_A                (prior + antropometría)
#   Etapa 2: π × L_A × L_B          (+ fuentes abiertas / OSINT)
#   Etapa 3: π × L_A × L_B × L_G   (+ genética → posterior completa)
#
# Punto clave: en Etapa 2, el ganador depende del prior (C2 vs C4).
# La genética resuelve la ambigüedad en Etapa 3 bajo cualquier prior.
#
# Salidas:
#   resultados/02_evolucion_progresiva.csv
#   resultados/graficos/02a_etapa1_antropometria.png
#   resultados/graficos/02b_etapa2_ambos_priors.png   ← comparación prior U vs D
#   resultados/graficos/02c_etapa3_completa.png
#   resultados/graficos/02d_evolucion_barras_apiladas.png
#   resultados/graficos/02e_tabla_comparacion_priors.png  ← tabla PNG resumen
# ============================================================================

.dir <- tryCatch(dirname(normalizePath(sys.frame(1)$ofile)),
         error = function(e) tryCatch(dirname(normalizePath(rstudioapi::getActiveDocumentContext()$path)),
         error = function(e) getwd()))
source(file.path(.dir, "00_setup_convenciones.R"))

cores <- COLORES_HIPOTESIS

# ============================================================================
# Calcular las 3 etapas × 2 priors
# ============================================================================

etapas <- list(
  uniforme    = list(
    P1 = calcular_posterior(logLR_A,                     prior_uniforme),
    P2 = calcular_posterior(logLR_A + logLR_B,           prior_uniforme),
    P3 = calcular_posterior(logLR_A + logLR_B + logLR_G, prior_uniforme)
  ),
  demografico = list(
    P1 = calcular_posterior(logLR_A,                     prior_demografico),
    P2 = calcular_posterior(logLR_A + logLR_B,           prior_demografico),
    P3 = calcular_posterior(logLR_A + logLR_B + logLR_G, prior_demografico)
  )
)

# CSV con ambos priors
tabla_progresion <- tibble(
  hipotesis               = candidatos,
  unif_etapa1_antrop      = round(etapas$uniforme$P1,    4),
  unif_etapa2_antrop_osint = round(etapas$uniforme$P2,   4),
  unif_etapa3_completa    = round(etapas$uniforme$P3,    6),
  demo_etapa1_antrop      = round(etapas$demografico$P1, 4),
  demo_etapa2_antrop_osint = round(etapas$demografico$P2, 4),
  demo_etapa3_completa    = round(etapas$demografico$P3, 6)
)

write_csv(tabla_progresion,
          file.path(RESULTADOS_DIR, "02_evolucion_progresiva.csv"))
cat("Escrito: 02_evolucion_progresiva.csv\n\n")

# ============================================================================
# Tabla comparativa en consola (como la imagen de la PPT)
# ============================================================================

fmt <- function(x) ifelse(x < 0.0005, "≈ 0", sprintf("%.4f", x))

cat("PRIOR UNIFORME\n")
cat(strrep("-", 60), "\n")
cat(sprintf("%-10s  %-12s  %-18s  %-10s\n",
            "Hipótesis", "Prior+Ant", "Prior+Ant+OSINT", "Completa"))
for (i in seq_along(candidatos)) {
  cat(sprintf("%-10s  %-12s  %-18s  %-10s\n",
    candidatos[i],
    fmt(etapas$uniforme$P1[i]),
    fmt(etapas$uniforme$P2[i]),
    ifelse(etapas$uniforme$P3[i] > 0.999, "≈ 1", fmt(etapas$uniforme$P3[i]))))
}

cat("\nPRIOR DEMOGRÁFICO\n")
cat(strrep("-", 60), "\n")
cat(sprintf("%-10s  %-12s  %-18s  %-10s\n",
            "Hipótesis", "Prior+Ant", "Prior+Ant+OSINT", "Completa"))
for (i in seq_along(candidatos)) {
  cat(sprintf("%-10s  %-12s  %-18s  %-10s\n",
    candidatos[i],
    fmt(etapas$demografico$P1[i]),
    fmt(etapas$demografico$P2[i]),
    ifelse(etapas$demografico$P3[i] > 0.999, "≈ 1", fmt(etapas$demografico$P3[i]))))
}

# Señalar el hallazgo clave
ganador_unif_e2  <- candidatos[which.max(etapas$uniforme$P2)]
ganador_demo_e2  <- candidatos[which.max(etapas$demografico$P2)]
ganador_unif_e3  <- candidatos[which.max(etapas$uniforme$P3)]
ganador_demo_e3  <- candidatos[which.max(etapas$demografico$P3)]

cat(sprintf("\n⚠  Etapa 2 (sin genética):\n"))
cat(sprintf("   Prior uniforme   → gana %s (%.4f)\n",
    ganador_unif_e2, max(etapas$uniforme$P2)))
cat(sprintf("   Prior demográfico → gana %s (%.4f)\n",
    ganador_demo_e2, max(etapas$demografico$P2)))
if (ganador_unif_e2 != ganador_demo_e2) {
  cat("   → El prior cambia el ganador en esta etapa.\n")
}
cat(sprintf("\n✓  Etapa 3 (con genética): %s gana bajo ambos priors.\n",
    ganador_unif_e3))
cat("   La genética resuelve la ambigüedad sin importar el prior.\n\n")

# ============================================================================
# PNG: tabla resumen comparación de priors (3 etapas × 2 priors)
# ============================================================================
library(grid)

fmt4 <- function(x) {
  ifelse(x > 0.9995, "≈ 1",
  ifelse(x < 0.0005, "≈ 0",
         sprintf("%.4f", x)))
}

tabla_png <- data.frame(
  Hipótesis      = candidatos,
  `U: Ant`       = fmt4(etapas$uniforme$P1),
  `U: Ant+OSINT` = fmt4(etapas$uniforme$P2),
  `U: Completa`  = fmt4(etapas$uniforme$P3),
  `D: Ant`       = fmt4(etapas$demografico$P1),
  `D: Ant+OSINT` = fmt4(etapas$demografico$P2),
  `D: Completa`  = fmt4(etapas$demografico$P3),
  check.names = FALSE
)

fila_ganadora <- which(candidatos == ganador_demo_e3)
fills         <- rep("white", nrow(tabla_png))
fills[fila_ganadora] <- "#c8e6c9"

tema_t <- ttheme_default(
  core    = list(bg_params = list(fill = fills, col = "gray75"),
                 fg_params = list(fontsize = 10)),
  colhead = list(bg_params = list(fill = "#37474f"),
                 fg_params = list(col = "white", fontsize = 10, fontface = "bold"))
)

grob_t  <- tableGrob(tabla_png, rows = NULL, theme = tema_t)
titulo_t <- textGrob(
  "Evolución de la posterior — Prior Uniforme (U) vs Demográfico (D)",
  gp = gpar(fontsize = 12, fontface = "bold")
)
sub_t <- textGrob(
  sprintf("Sin genética: U→%s | D→%s  •  Con genética: ambos convergen a %s",
          ganador_unif_e2, ganador_demo_e2, ganador_demo_e3),
  gp = gpar(fontsize = 9, col = "#CF5C36")
)

img_t <- arrangeGrob(titulo_t, sub_t, grob_t,
                     nrow    = 3,
                     heights = unit(c(0.7, 0.5, 4), c("cm", "cm", "null")))

png(file.path(GRAFICOS_DIR, "02e_tabla_comparacion_priors.png"),
    width = 1400, height = 340, res = 120)
grid.draw(img_t)
dev.off()
cat("Escrito: 02e_tabla_comparacion_priors.png\n\n")

# ============================================================================
# Gráficos — versión revisada
# ============================================================================

# directorio ya definido en 00_setup_convenciones.R
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

fmt_pct <- function(x) sprintf("%.1f%%", 100 * x)

prior_labels <- c(
  demografico = "Prior demográfico",
  uniforme    = "Prior uniforme"
)
PRIOR_DEMO <- prior_labels[["demografico"]]
PRIOR_UNIF <- prior_labels[["uniforme"]]

# Construir datos_etapas en formato largo para grafico_etapa_priors
datos_etapas <- bind_rows(
  tibble(prior = PRIOR_DEMO, etapa = "Antropometria",
         hipotesis = candidatos, posterior = etapas$demografico$P1),
  tibble(prior = PRIOR_DEMO, etapa = "Antropometria + OSINT",
         hipotesis = candidatos, posterior = etapas$demografico$P2),
  tibble(prior = PRIOR_DEMO, etapa = "Completa",
         hipotesis = candidatos, posterior = etapas$demografico$P3),
  tibble(prior = PRIOR_UNIF, etapa = "Antropometria",
         hipotesis = candidatos, posterior = etapas$uniforme$P1),
  tibble(prior = PRIOR_UNIF, etapa = "Antropometria + OSINT",
         hipotesis = candidatos, posterior = etapas$uniforme$P2),
  tibble(prior = PRIOR_UNIF, etapa = "Completa",
         hipotesis = candidatos, posterior = etapas$uniforme$P3)
) %>%
  mutate(
    etapa     = factor(etapa, levels = c("Antropometria",
                                         "Antropometria + OSINT",
                                         "Completa")),
    hipotesis = factor(hipotesis, levels = candidatos)
  )

grafico_etapa_priors <- function(nombre_etapa, titulo, archivo,
                                 width = 10, height = 5.6,
                                 alpha_prior_uniforme = 1) {
  limite_x <- min(1.08, max(0.12,
    max(datos_etapas$posterior[datos_etapas$etapa == nombre_etapa]) * 1.18
  ))

  datos <- datos_etapas %>%
    filter(etapa == nombre_etapa) %>%
    mutate(
      hipotesis_prior = reorder(
        paste(hipotesis, prior, sep = "__"),
        posterior
      ),
      etiqueta    = fmt_pct(posterior),
      alpha_panel = ifelse(prior == PRIOR_UNIF, alpha_prior_uniforme, 1),
      x_etiqueta  = pmin(posterior + limite_x * 0.015, limite_x * 0.96)
    )

  g <- ggplot(datos, aes(x = posterior, y = hipotesis_prior,
                          fill = hipotesis)) +
    geom_col(aes(alpha = alpha_panel), width = 0.68) +
    geom_text(aes(x = x_etiqueta, label = etiqueta, alpha = alpha_panel),
              hjust = 0, size = 3.2, fontface = "bold") +
    facet_wrap(~ prior, ncol = 2, scales = "free_y") +
    scale_fill_manual(values = cores) +
    scale_alpha_identity() +
    scale_y_discrete(labels = function(x) sub("__.*$", "", x)) +
    scale_x_continuous(limits = c(0, limite_x), labels = fmt_pct) +
    labs(title = titulo, x = "Probabilidad posterior", y = "Hipótesis") +
    tema(12) +
    theme(
      legend.position  = "none",
      strip.background = element_rect(fill = "gray92", color = NA),
      strip.text       = element_text(face = "bold")
    )

  guardar(archivo, g, width = width, height = height)
}

grafico_etapa_priors(
  "Antropometria",
  "Fuente de evidencia: antropometría",
  "02a_etapa1_antropometria_prior_uniforme_atenuado.png",
  alpha_prior_uniforme = 0.10
)

grafico_etapa_priors(
  "Antropometria + OSINT",
  "Fuente de evidencia: antropometría y OSINT",
  "02b_etapa2_ambos_priors.png"
)

grafico_etapa_priors(
  "Completa",
  "Fuente de evidencia: antropometría, OSINT y genética",
  "02c_etapa3_genetica_prior_uniforme_atenuado.png",
  alpha_prior_uniforme = 0.10
)

g02d <- datos_etapas %>%
  filter(prior == PRIOR_DEMO) %>%
  ggplot(aes(x = etapa, y = posterior, fill = hipotesis)) +
  geom_col(width = 0.58) +
  scale_fill_manual(values = cores) +
  scale_y_continuous(labels = fmt_pct) +
  labs(
    title = "Evolución de la posterior",
    x     = "Evidencia acumulada",
    y     = "Probabilidad posterior",
    fill  = "Hipótesis"
  ) +
  scale_x_discrete(labels = c(
    "Antropometria"         = "Antropometría",
    "Antropometria + OSINT" = "Antropometría + OSINT",
    "Completa"              = "Antropometría + OSINT + genética"
  )) +
  tema(12)

guardar("02d_evolucion_barras_apiladas.png", g02d, width = 8, height = 5)
