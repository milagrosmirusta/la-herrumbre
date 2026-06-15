# ============================================================================
# SETUP: Cargar datos, definir convenciones, priors
# ============================================================================
# Causa 1872/2024 — La Herrumbre
# Identificación forense bayesiana de restos óseos
#
# CONVENCIONES ELEGIDAS:
# - Bloque A (Antropometría): A1 (estricta)
#   Razón: IPM vinculante; penalización justa a candidatos con actividad post-ventana
#
# - Bloque B (OSINT): B1 (estricta)
#   Razón: Testimonios de 1° grado son correlacionados pero confiables; α=0.6 cauteloso
#
# - Bloque G (Genética): G1 (estricta)
#   Razón: Penaliza parientes lejanos; C2 tiene multi-1° que resisten β=1.0
#
# ============================================================================

# Limpiar ambiente
rm(list = ls())

# Cargar librerías
library(tidyverse)
library(readr)

# ============================================================================
# 1. CARGAR TABLAS DE LIKELIHOOD
# ============================================================================

# Definir ruta base (un nivel arriba)
data_dir <- "../datos"

# Leer tablas
tabla_A <- read_csv(file.path(data_dir, "tablas_A_antropometrica.csv"))
tabla_B <- read_csv(file.path(data_dir, "tablas_B_osint.csv"))
tabla_G <- read_csv(file.path(data_dir, "tablas_G_robustez.csv"))

cat("✓ Tablas cargadas\n")
cat("  - Bloque A (Antropometría):", nrow(tabla_A), "candidatos\n")
cat("  - Bloque B (OSINT):", nrow(tabla_B), "candidatos\n")
cat("  - Bloque G (Genética):", nrow(tabla_G), "candidatos\n\n")

# ============================================================================
# 2. DEFINIR CONVENCIONES Y PRIORS
# ============================================================================

# Extraer log-LR según convenciones elegidas
# A1: convención estricta (σ_edad = 5 años, IPM riguroso)
# B1: convención estricta (α_familia = 0.6)
# G1: convención estricta (β fuerte para parientes lejanos)

datos_convencion <- tabla_A %>%
  select(candidato, log10_LR_antrop_A1) %>%
  rename(logLR_A = log10_LR_antrop_A1) %>%
  left_join(
    tabla_B %>% select(candidato, log10_LR_OSINT_B1) %>% rename(logLR_B = log10_LR_OSINT_B1),
    by = "candidato"
  ) %>%
  left_join(
    tabla_G %>% select(candidato, log10_LR_efec_G1) %>% rename(logLR_G = log10_LR_efec_G1),
    by = "candidato"
  )

# Agregar H0 (hipótesis "ninguno")
datos_convencion <- bind_rows(
  tibble(candidato = "H0", logLR_A = 0, logLR_B = 0, logLR_G = 0),
  datos_convencion
)

cat("Convenciones elegidas: A1 + B1 + G1\n\n")
print(datos_convencion)
cat("\n")

# ============================================================================
# 3. DEFINIR PRIORS
# ============================================================================

# Prior uniforme (baseline metodológico)
prior_uniforme <- rep(1/6, 6)

# Prior demográfico (sugerido por la clase)
# Justificación: refleja compatibilidad demográfica con corredor migratorio
prior_demografico <- c(0.20, 0.18, 0.22, 0.12, 0.20, 0.08)

# Verificar que sumen a 1
cat("Prior uniforme suma a:", sum(prior_uniforme), "\n")
cat("Prior demográfico suma a:", sum(prior_demografico), "\n\n")

# Crear dataframe con priors
datos_convencion <- datos_convencion %>%
  mutate(
    pi_uniforme = prior_uniforme,
    pi_demografico = prior_demografico
  )

# ============================================================================
# 4. EXPORTAR PARA SCRIPTS POSTERIORES
# ============================================================================

# Guardar en un archivo RDS para que otros scripts lo lean
saveRDS(list(
  datos = datos_convencion,
  prior_uniforme = prior_uniforme,
  prior_demografico = prior_demografico
), "00_datos_setup.rds")

cat("✓ Setup exportado a 00_datos_setup.rds\n")
cat("\nDatos listos para cálculos bayesianos\n")
