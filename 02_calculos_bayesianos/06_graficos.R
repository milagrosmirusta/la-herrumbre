# ============================================================================
# GENERAR GRÁFICOS
# ============================================================================
# Visualizaciones para la presentación:
# 1. Barras apiladas: evolución en 3 etapas
# 2. Línea: sensibilidad a λ
# 3. Heatmap: 8 combinaciones de convenciones
# ============================================================================

rm(list = ls())
library(tidyverse)
library(readr)
library(gridExtra)

# Crear directorio de gráficos si no existe
dir.create("../03_resultados/graficos", showWarnings = FALSE)

# ============================================================================
# 1. GRÁFICO DE PROGRESIÓN (3 ETAPAS)
# ============================================================================

datos_progresion <- read_csv("../03_resultados/03_progresion_posterior.csv")

# Transformar a formato largo para ggplot
datos_prog_long <- datos_progresion %>%
  pivot_longer(
    starts_with("etapa"),
    names_to = "etapa",
    values_to = "posterior"
  ) %>%
  mutate(
    etapa = factor(
      etapa,
      levels = c("etapa_1_antrop", "etapa_2_antrop_abi", "etapa_3_completa"),
      labels = c("Etapa 1\n(A)", "Etapa 2\n(A+B)", "Etapa 3\n(A+B+G)")
    ),
    candidato = factor(candidato, levels = c("H0", "C1", "C2", "C3", "C4", "C5"))
  )

# Gráfico de barras apiladas
g1 <- ggplot(datos_prog_long, aes(x = etapa, y = posterior, fill = candidato)) +
  geom_col(position = "stack", width = 0.6) +
  scale_fill_brewer(palette = "Dark2") +
  labs(
    title = "Progresión de la Posterior en 3 Etapas",
    subtitle = "Cómo la evidencia poda el espacio de hipótesis",
    x = "Evidencia acumulada",
    y = "Probabilidad posterior",
    fill = "Hipótesis"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(face = "bold", size = 14),
    plot.subtitle = element_text(size = 11),
    legend.position = "right"
  ) +
  ylim(0, 1)

ggsave("../03_resultados/graficos/01_progresion_posterior.png", g1, width = 8, height = 5, dpi = 150)
cat("✓ Gráfico 1: Progresión de posterior\n")

# ============================================================================
# 2. GRÁFICO DE SENSIBILIDAD A λ
# ============================================================================

datos_lambda <- read_csv("../03_resultados/04_sensibilidad_lambda.csv")

# Transformar a largo
datos_lambda_long <- datos_lambda %>%
  pivot_longer(
    starts_with("lambda"),
    names_to = "lambda",
    values_to = "posterior"
  ) %>%
  mutate(
    lambda = as.numeric(str_extract(lambda, "\\d+\\.\\d+")),
    candidato = factor(candidato, levels = c("H0", "C1", "C2", "C3", "C4", "C5"))
  )

# Gráfico de líneas
g2 <- ggplot(datos_lambda_long, aes(x = lambda, y = posterior, color = candidato, group = candidato)) +
  geom_line(size = 1) +
  geom_point(size = 3) +
  geom_hline(yintercept = 0.95, linetype = "dashed", color = "red", size = 0.8) +
  annotate("text", x = 0.05, y = 0.98, label = "Umbral 0.95", color = "red", size = 9) +
  scale_color_brewer(palette = "Dark2") +
  labs(
    title = "Sensibilidad a Peso λ de la Genética",
    subtitle = "¿A qué punto la conclusión deja de depender de creerle a la genética?",
    x = "λ (factor de ponderación de logLR_G)",
    y = "Probabilidad posterior",
    color = "Hipótesis"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(face = "bold", size = 14),
    plot.subtitle = element_text(size = 11),
    legend.position = "right"
  ) +
  scale_x_continuous(breaks = c(0, 0.3, 0.5, 0.7, 1.0)) +
  ylim(0, 1)

ggsave("../03_resultados/graficos/02_sensibilidad_lambda.png", g2, width = 8, height = 5, dpi = 150)
cat("✓ Gráfico 2: Sensibilidad a λ\n")

# ============================================================================
# 3. HEATMAP DE 8 COMBINACIONES
# ============================================================================

datos_sens <- read_csv("../03_resultados/02_sensibilidad_8combinaciones.csv")

# Transformar a largo para heatmap
datos_sens_long <- datos_sens %>%
  pivot_longer(
    -candidato,
    names_to = "combinacion",
    values_to = "posterior"
  ) %>%
  mutate(
    candidato = factor(candidato, levels = c("H0", "C1", "C2", "C3", "C4", "C5")),
    combinacion = factor(combinacion, levels = unique(combinacion))
  )

# Heatmap
g3 <- ggplot(datos_sens_long, aes(x = combinacion, y = candidato, fill = posterior)) +
  geom_tile(color = "white", size = 1) +
  scale_fill_gradient(low = "white", high = "#1f77b4", limits = c(0, 1)) +
  geom_text(aes(label = round(posterior, 3)), color = "black", size = 3) +
  labs(
    title = "Sensibilidad a Convenciones (8 Combinaciones)",
    subtitle = "A1/A2 × B1/B2 × G1/G2",
    x = "Combinación de convenciones",
    y = "Hipótesis",
    fill = "Posterior"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(face = "bold", size = 14),
    plot.subtitle = element_text(size = 11),
    axis.text.x = element_text(angle = 45, hjust = 1, size = 9),
    axis.text.y = element_text(size = 10)
  )

ggsave("../03_resultados/graficos/03_sensibilidad_convenciones.png", g3, width = 10, height = 6, dpi = 150)
cat("✓ Gráfico 3: Heatmap de convenciones\n")

# ============================================================================
# 4. GRÁFICO DE POSTERIORS SIN Y CON GENÉTICA (C2 vs C4)
# ============================================================================

datos_kl <- read_csv("../03_resultados/05_kl_divergence.csv")

# Seleccionar solo C2 y C4 para visualizar el impacto
datos_c2_c4 <- datos_kl %>%
  filter(candidato %in% c("C2", "C4")) %>%
  mutate(
    candidato = factor(candidato, levels = c("C2", "C4"))
  ) %>%
  pivot_longer(
    c(P_sin_genetica, P_con_genetica),
    names_to = "tipo",
    values_to = "posterior"
  ) %>%
  mutate(
    tipo = factor(tipo, levels = c("P_sin_genetica", "P_con_genetica"),
                  labels = c("Sin genética", "Con genética"))
  )

g4 <- ggplot(datos_c2_c4, aes(x = candidato, y = posterior, fill = tipo)) +
  geom_col(position = "dodge", width = 0.6) +
  geom_hline(yintercept = 0.95, linetype = "dashed", color = "red", size = 0.8) +
  annotate("text", x = 2.3, y = 0.98, label = "Umbral", color = "red", size = 9) +
  scale_fill_manual(values = c("Sin genética" = "#ff7f0e", "Con genética" = "#2ca02c")) +
  labs(
    title = "Impacto de la Genética: C2 vs C4",
    subtitle = "Sin genética estaban empatados (~50%). La genética resuelve",
    x = "Candidato",
    y = "Probabilidad posterior",
    fill = "Scenario"
  ) +
  theme_minimal() +
  theme(
    plot.title = element_text(face = "bold", size = 14),
    plot.subtitle = element_text(size = 11),
    legend.position = "bottom"
  ) +
  ylim(0, 1)

ggsave("../03_resultados/graficos/04_impacto_genetica.png", g4, width = 7, height = 5, dpi = 150)
cat("✓ Gráfico 4: Impacto de la genética\n")

# ============================================================================
# RESUMEN
# ============================================================================

cat("\n✓ TODOS LOS GRÁFICOS GENERADOS\n")
cat("  - 01_progresion_posterior.png\n")
cat("  - 02_sensibilidad_lambda.png\n")
cat("  - 03_sensibilidad_convenciones.png\n")
cat("  - 04_impacto_genetica.png\n")
cat("\nGuardados en: 03_resultados/graficos/\n")
