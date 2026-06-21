# ============================================================================
# 02_evolucion_posterior_progresiva.R
# Caso A "La Herrumbre" — Causa 1872/2024
# ============================================================================
# Construye la posterior en tres etapas sucesivas, mostrando cómo cada línea
# de evidencia actualiza la creencia:
#
#   Etapa 1: π × L_A                (prior + antropometría)
#   Etapa 2: π × L_A × L_B          (+ fuentes abiertas / OSINT)
#   Etapa 3: π × L_A × L_B × L_G   (+ genética → posterior completa)
#
# Convención y prior según 00_setup_convenciones.R.
#
# Salidas:
#   resultados/02_evolucion_progresiva.csv
#   resultados/graficos/02a_etapa1_antropometria.png
#   resultados/graficos/02b_etapa2_antrop_osint.png
#   resultados/graficos/02c_etapa3_completa.png
#   resultados/graficos/02d_evolucion_barras_apiladas.png
# ============================================================================

source("00_setup_convenciones.R")

# ============================================================================
# Calcular las 3 etapas (prior demográfico)
# ============================================================================

P1 <- calcular_posterior(logLR_A,                    prior_demografico)
P2 <- calcular_posterior(logLR_A + logLR_B,          prior_demografico)
P3 <- calcular_posterior(logLR_A + logLR_B + logLR_G, prior_demografico)

tabla_progresion <- tibble(
  hipotesis            = candidatos,
  etapa_1_antrop       = round(P1, 6),
  etapa_2_antrop_osint = round(P2, 6),
  etapa_3_completa     = round(P3, 6)
)

write_csv(tabla_progresion,
          file.path(RESULTADOS_DIR, "02_evolucion_progresiva.csv"))
cat("Escrito: 02_evolucion_progresiva.csv\n\n")

cat("Progresión (prior demográfico):\n")
print(tabla_progresion)

# ============================================================================
# Gráficos por etapa
# ============================================================================

cores <- c(H0 = "#636363", C1 = "#377eb8", C2 = "#4daf4a",
           C3 = "#ff7f00", C4 = "#984ea3", C5 = "#e41a1c")

# Función helper para gráfico de barras por etapa
grafico_etapa <- function(datos, col, titulo, subtitulo,
                          ylim_max = 0.6, color_titulo = "black") {
  datos %>%
    ggplot(aes(x = reorder(hipotesis, -.data[[col]]),
               y = .data[[col]], fill = hipotesis)) +
    geom_col(width = 0.65) +
    geom_text(aes(label = sprintf("%.1f%%", .data[[col]] * 100)),
              vjust = -0.4, size = 3.5, fontface = "bold") +
    scale_fill_manual(values = cores) +
    labs(title = titulo, subtitle = subtitulo,
         x = "Hipótesis", y = "Probabilidad posterior") +
    theme_minimal(base_size = 13) +
    theme(legend.position = "none",
          plot.title    = element_text(face = "bold", color = color_titulo),
          plot.subtitle = element_text(color = "gray40")) +
    ylim(0, ylim_max)
}

g1 <- grafico_etapa(
  tabla_progresion, "etapa_1_antrop",
  "Etapa 1 — Solo antropometría",
  "Compatibilidad con sexo, edad e intervalo post-mortem"
)
ggsave(file.path(GRAFICOS_DIR, "02a_etapa1_antropometria.png"),
       g1, width = 7, height = 5, dpi = 150)
cat("Escrito: 02a_etapa1_antropometria.png\n")

g2 <- grafico_etapa(
  tabla_progresion, "etapa_2_antrop_osint",
  "Etapa 2 — Antropometría + OSINT",
  "Incorporación de testimonios y fuentes abiertas"
)
ggsave(file.path(GRAFICOS_DIR, "02b_etapa2_antrop_osint.png"),
       g2, width = 7, height = 5, dpi = 150)
cat("Escrito: 02b_etapa2_antrop_osint.png\n")

g3 <- grafico_etapa(
  tabla_progresion, "etapa_3_completa",
  "Etapa 3 — Posterior completa (Antrop. + OSINT + Genética)",
  "La genética resuelve la ambigüedad",
  ylim_max = 1.05, color_titulo = "#2ca02c"
)
ggsave(file.path(GRAFICOS_DIR, "02c_etapa3_completa.png"),
       g3, width = 7, height = 5, dpi = 150)
cat("Escrito: 02c_etapa3_completa.png\n")

# Gráfico comparativo: barras apiladas 3 etapas
datos_long <- tabla_progresion %>%
  pivot_longer(-hipotesis, names_to = "etapa", values_to = "posterior") %>%
  mutate(
    etapa = factor(etapa,
                   levels = c("etapa_1_antrop", "etapa_2_antrop_osint", "etapa_3_completa"),
                   labels = c("Etapa 1\n(A)", "Etapa 2\n(A+B)", "Etapa 3\n(A+B+G)")),
    hipotesis = factor(hipotesis, levels = candidatos)
  )

g4 <- ggplot(datos_long, aes(x = etapa, y = posterior, fill = hipotesis)) +
  geom_col(position = "stack", width = 0.6) +
  scale_fill_manual(values = cores) +
  labs(title = "Progresión de la posterior en 3 etapas",
       subtitle = "Cómo cada línea de evidencia poda el espacio de hipótesis",
       x = "Evidencia acumulada", y = "Probabilidad posterior",
       fill = "Hipótesis") +
  theme_minimal(base_size = 13) +
  theme(plot.title    = element_text(face = "bold"),
        plot.subtitle = element_text(color = "gray40")) +
  ylim(0, 1)

ggsave(file.path(GRAFICOS_DIR, "02d_evolucion_barras_apiladas.png"),
       g4, width = 8, height = 5, dpi = 150)
cat("Escrito: 02d_evolucion_barras_apiladas.png\n")

# ============================================================================
# Narrativa en consola
# ============================================================================

cat(sprintf("\nETAPA 1 (solo antropometría):\n"))
cat(sprintf("  %s\n", paste(
  sprintf("%s:%.1f%%", candidatos, P1 * 100), collapse = "  "
)))
cat(sprintf("\nETAPA 2 (antrop. + OSINT):\n"))
cat(sprintf("  %s\n", paste(
  sprintf("%s:%.1f%%", candidatos, P2 * 100), collapse = "  "
)))
cat(sprintf("\nETAPA 3 (completa):\n"))
cat(sprintf("  %s\n\n", paste(
  sprintf("%s:%.4f%%", candidatos, P3 * 100), collapse = "  "
)))
