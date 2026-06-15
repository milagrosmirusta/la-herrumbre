# ============================================================================
# PROGRESIÓN DE LA POSTERIOR EN 3 ETAPAS
# ============================================================================
# Mostrar cómo evoluciona la creencia bayesiana al agregar evidencia:
#
# Etapa 1: π × L_A  (prior + antropometría)
# Etapa 2: π × L_A × L_B  (prior + antropometría + OSINT)
# Etapa 3: π × L_A × L_B × L_G  (prior + antropometría + OSINT + genética)
#
# Esto ilustra el principio de actualización secuencial en inferencia bayesiana.
# ============================================================================

rm(list = ls())
library(tidyverse)
library(readr)

# Cargar datos
tabla_A <- read_csv("../datos/tablas_A_antropometrica.csv")
tabla_B <- read_csv("../datos/tablas_B_osint.csv")
tabla_G <- read_csv("../datos/tablas_G_robustez.csv")

# Usar convenciones A1, B1, G1 (las elegidas)
logLR_A <- c(0, tabla_A$log10_LR_antrop_A1)
logLR_B <- c(0, tabla_B$log10_LR_OSINT_B1)
logLR_G <- c(0, tabla_G$log10_LR_efec_G1)

prior_uniforme <- rep(1/6, 6)

# ============================================================================
# FUNCIÓN PARA CALCULAR POSTERIOR
# ============================================================================

calcular_posterior <- function(logLR, prior) {
  logLR_natural <- logLR * log(10)
  log_num <- log(prior) + logLR_natural
  log_num_adj <- log_num - max(log_num, na.rm = TRUE)
  numerador <- exp(log_num_adj)
  posterior <- numerador / sum(numerador)
  return(posterior)
}

# ============================================================================
# CALCULAR LAS 3 ETAPAS
# ============================================================================

# Etapa 1: Solo antropometría
P1 <- calcular_posterior(logLR_A, prior_uniforme)

# Etapa 2: Antropometría + OSINT
logLR_A_B <- logLR_A + logLR_B
P2 <- calcular_posterior(logLR_A_B, prior_uniforme)

# Etapa 3: Antropometría + OSINT + Genética
logLR_A_B_G <- logLR_A + logLR_B + logLR_G
P3 <- calcular_posterior(logLR_A_B_G, prior_uniforme)

# ============================================================================
# CREAR TABLA DE PROGRESIÓN
# ============================================================================

tabla_progresion <- tibble(
  candidato = c("H0", "C1", "C2", "C3", "C4", "C5"),
  etapa_1_antrop = P1,
  etapa_2_antrop_abi = P2,
  etapa_3_completa = P3
) %>%
  mutate(
    across(starts_with("etapa"), ~ round(., 6))
  )

cat("PROGRESIÓN DE LA POSTERIOR EN 3 ETAPAS\n")
cat("============================================================================\n\n")
print(tabla_progresion)
cat("\n")

# ============================================================================
# EXPORTAR
# ============================================================================

write_csv(tabla_progresion, "../03_resultados/03_progresion_posterior.csv")

cat("✓ Tabla de progresión exportada a 03_progresion_posterior.csv\n\n")

# ============================================================================
# NARRATIVA: QUÉ PASÓ EN CADA ETAPA
# ============================================================================

cat("NARRATIVA: CÓMO PODÓ LA EVIDENCIA EL ESPACIO DE HIPÓTESIS\n")
cat("============================================================================\n\n")

cat("ETAPA 1 (Antropometría):\n")
cat(sprintf("  H0: %.1f%% | C1: %.1f%% | C2: %.1f%% | C3: %.1f%% | C4: %.1f%% | C5: %.1f%%\n",
  P1[1]*100, P1[2]*100, P1[3]*100, P1[4]*100, P1[5]*100, P1[6]*100))
cat("  → Múltiples hipótesis vivas; C2 y C4 lideran (compatibles con edad/IPM)\n\n")

cat("ETAPA 2 (Antropometría + OSINT):\n")
cat(sprintf("  H0: %.1f%% | C1: %.1f%% | C2: %.1f%% | C3: %.1f%% | C4: %.1f%% | C5: %.1f%%\n",
  P2[1]*100, P2[2]*100, P2[3]*100, P2[4]*100, P2[5]*100, P2[6]*100))
cat("  → C3 casi desaparece (testimonios en contra)\n")
cat("  → C2 y C4 empatados (~50/46%); elección de B1 vs B2 determina ganador\n")
cat("  → La OSINT no resuelve la ambigüedad entre los dos candidatos fuertes\n\n")

cat("ETAPA 3 (Antropometría + OSINT + Genética):\n")
cat(sprintf("  H0: %.1f%% | C1: %.1f%% | C2: %.6f%% | C3: %.1f%% | C4: %.1f%% | C5: %.1f%%\n",
  P3[1]*100, P3[2]*100, P3[3]*100, P3[4]*100, P3[5]*100, P3[6]*100))
cat("  → C2 DOMINA (≈100%); todos los demás colapsados a 0\n")
cat("  → La genética RESOLVIÓ la indeterminación preexistente\n")
cat("  → LR genético de C2 (~10^28) es tan abrumador que hace colapsar la posterior\n\n")

# ============================================================================
# MAGNITUD DEL APORTE: KL INFORMAL
# ============================================================================

# Diferencia de entropía
H_P2 <- -sum(P2[P2 > 0] * log2(P2[P2 > 0]))
H_P3 <- -sum(P3[P3 > 0] * log2(P3[P3 > 0]))

cat("MEDIDA DE APORTE (INFORMAL):\n")
cat(sprintf("  Entropía (Etapa 2): %.4f bits\n", H_P2))
cat(sprintf("  Entropía (Etapa 3): %.4f bits\n", H_P3))
cat(sprintf("  Reducción: %.4f bits\n", H_P2 - H_P3))
cat("  → La genética redujo la incertidumbre drásticamente\n")
