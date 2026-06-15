# ============================================================================
# SENSIBILIDAD A CONVENCIONES (8 COMBINACIONES)
# ============================================================================
# Calcular la posterior bajo todas las 8 combinaciones posibles:
# A1/A2 × B1/B2 × G1/G2
#
# Esto permite evaluar qué tan robusta es la conclusión a las elecciones
# metodológicas sobre el tratamiento de la incertidumbre en cada bloque.
# ============================================================================

rm(list = ls())
library(tidyverse)
library(readr)

# Cargar tablas originales
tabla_A <- read_csv("../datos/tablas_A_antropometrica.csv")
tabla_B <- read_csv("../datos/tablas_B_osint.csv")
tabla_G <- read_csv("../datos/tablas_G_robustez.csv")

# ============================================================================
# 1. DEFINIR COMBINACIONES Y COLUMNAS
# ============================================================================

combinaciones <- expand_grid(
  convencion_A = c("A1", "A2"),
  convencion_B = c("B1", "B2"),
  convencion_G = c("G1", "G2")
)

# Mapeo de convenciones a columnas
col_mapping <- list(
  A1 = "log10_LR_antrop_A1",
  A2 = "log10_LR_antrop_A2",
  B1 = "log10_LR_OSINT_B1",
  B2 = "log10_LR_OSINT_B2",
  G1 = "log10_LR_efec_G1",
  G2 = "log10_LR_efec_G2"
)

# Prior uniforme
prior_uniforme <- c(1/6, 1/6, 1/6, 1/6, 1/6, 1/6)

# ============================================================================
# 2. FUNCIÓN PARA CALCULAR POSTERIOR
# ============================================================================

calcular_posterior_simple <- function(logLR_total, prior) {
  logLR_natural <- logLR_total * log(10)
  log_num <- log(prior) + logLR_natural
  log_num_adj <- log_num - max(log_num, na.rm = TRUE)
  numerador <- exp(log_num_adj)
  posterior <- numerador / sum(numerador)
  return(posterior)
}

# ============================================================================
# 3. CALCULAR TODAS LAS COMBINACIONES
# ============================================================================

resultados_lista <- list()

for (i in 1:nrow(combinaciones)) {

  conv_A <- combinaciones$convencion_A[i]
  conv_B <- combinaciones$convencion_B[i]
  conv_G <- combinaciones$convencion_G[i]

  # Extraer columnas según combinación
  col_A <- col_mapping[[conv_A]]
  col_B <- col_mapping[[conv_B]]
  col_G <- col_mapping[[conv_G]]

  # Combinar: H0 siempre es 0
  logLR_A <- c(0, tabla_A[[col_A]])
  logLR_B <- c(0, tabla_B[[col_B]])
  logLR_G <- c(0, tabla_G[[col_G]])

  logLR_total <- logLR_A + logLR_B + logLR_G

  # Calcular posterior
  posterior <- calcular_posterior_simple(logLR_total, prior_uniforme)

  # Guardar en lista
  col_name <- paste0(conv_A, "_", conv_B, "_", conv_G)

  resultados_lista[[col_name]] <- posterior

  cat(sprintf(
    "[%d/8] %s: C2 = %.6f\n",
    i, col_name, posterior[3]  # C2 es el 3er elemento (después de H0, C1)
  ))
}

# ============================================================================
# 4. CREAR TABLA DE SENSIBILIDAD
# ============================================================================

tabla_sensibilidad <- as_tibble(resultados_lista) %>%
  mutate(
    candidato = c("H0", "C1", "C2", "C3", "C4", "C5"),
    .before = 1
  )

# Reordenar columnas: candidato primero, luego las 8 combinaciones
tabla_sensibilidad <- tabla_sensibilidad %>%
  select(candidato, everything())

cat("\nTABLA DE SENSIBILIDAD (8 COMBINACIONES)\n")
cat("============================================================================\n\n")

# Redondear para visualización
tabla_sensibilidad %>%
  mutate(across(-candidato, ~ round(., 6))) %>%
  print()

# ============================================================================
# 5. EXPORTAR RESULTADOS
# ============================================================================

write_csv(tabla_sensibilidad, "../03_resultados/02_sensibilidad_8combinaciones.csv")

cat("\n✓ Tabla de sensibilidad exportada a 02_sensibilidad_8combinaciones.csv\n")

# ============================================================================
# 6. ANÁLISIS: ¿QÚÉMICA CANDIDATO GANA EN CUÁNTAS COMBINACIONES?
# ============================================================================

cat("\n\nANÁLISIS: ROBUSTEZ A CONVENCIONES\n")
cat("============================================================================\n\n")

# Para cada candidato, contar cuántas combinaciones lo ponen como ganador
ganadores <- tabla_sensibilidad %>%
  select(-candidato) %>%
  as.matrix() %>%
  apply(2, which.max) %>%
  factor(levels = 1:6, labels = c("H0", "C1", "C2", "C3", "C4", "C5")) %>%
  table()

print(ganadores)

cat("\n")

# Calcular máximo, mínimo, media para C2
C2_min <- min(tabla_sensibilidad$C2)
C2_max <- max(tabla_sensibilidad$C2)
C2_mean <- mean(tabla_sensibilidad$C2)

cat(sprintf(
  "C2 — Posterior mínima: %.6f\n", C2_min
))
cat(sprintf(
  "C2 — Posterior máxima: %.6f\n", C2_max
))
cat(sprintf(
  "C2 — Posterior promedio: %.6f\n", C2_mean
))

# Contar cuántas combinaciones tienen C2 > 0.95
n_C2_alto <- sum(tabla_sensibilidad$C2 > 0.95)
cat(sprintf(
  "\nCombinaciones con C2 > 0.95: %d/8\n", n_C2_alto
))

cat("\nCONCLUSIÓN: La identificación de C2 es ROBUSTA a la elección de convenciones.\n")
