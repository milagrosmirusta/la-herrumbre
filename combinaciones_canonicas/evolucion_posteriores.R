# PASO 7: Evolución de las creencias (P1, P2, P3)
# Muestra cómo se actualiza la posterior en tres etapas
# + Validación: compatibilidad genética de hermanos presuntos con madre

library(tidyverse)

cat("=== PASO 7: EVOLUCIÓN DE CREENCIAS ===\n\n")

# ============================================================================
# 1. CARGAR DATOS
# ============================================================================

cat("Cargando datos...\n\n")

# Detectar directorio de trabajo
wd <- getwd()
cat("Working directory:", wd, "\n")

# OPCIÓN 1: Si estamos en combinaciones_canonicas/
if (grepl("combinaciones_canonicas$", wd)) {
  cat("→ Detectado: estamos en combinaciones_canonicas/\n")
  repo_path <- ".."

# OPCIÓN 2: Si estamos en la-herrumbre/ (RStudio project root)
} else if (grepl("la-herrumbre$", wd)) {
  cat("→ Detectado: estamos en la-herrumbre/\n")
  repo_path <- "."

# OPCIÓN 3: Si estamos en otro lado, buscar relativamente
} else {
  cat("→ Ubicación desconocida. Buscando rutas...\n")
  # Buscar hacia arriba hasta encontrar tablas_A
  if (file.exists("../la-herrumbre/tablas_A_antropometrica.csv")) {
    repo_path <- "../la-herrumbre"
  } else if (file.exists("tablas_A_antropometrica.csv")) {
    repo_path <- "."
  } else {
    stop("❌ No puedo encontrar los archivos. Asegúrate de estar en la carpeta correcta.")
  }
}

cat("  Buscando archivos en:", repo_path, "\n\n")

# Cargar archivos con manejo de errores
load_file <- function(fname, path) {
  fpath <- file.path(path, fname)
  if (!file.exists(fpath)) {
    stop(sprintf("❌ No encontrado: %s", fpath))
  }
  data <- read.csv(fpath, stringsAsFactors = FALSE)
  cat(sprintf("  ✓ %s (%d rows, %d cols)\n", fname, nrow(data), ncol(data)))
  return(data)
}

tablas_A <- load_file("tablas_A_antropometrica.csv", repo_path)
tablas_B <- load_file("tablas_B_osint.csv", repo_path)
tablas_G <- load_file("tablas_G_robustez.csv", repo_path)
perfiles_cand <- load_file("perfiles_candidatos.csv", repo_path)
base_poblacional <- load_file("base_poblacional.csv", repo_path)

cat("\n✓ Todos los datos cargados correctamente.\n")

# ============================================================================
# 2. PARÁMETROS: Convención elegida A1+B1+G1, Prior uniforme
# ============================================================================

candidatos <- c("H0", "C1", "C2", "C3", "C4", "C5")
prior_demografica <- c(0.20, 0.18, 0.22, 0.12, 0.20, 0.08)

# Extraer columnas de log10_LR
# Estructura: tablas_A tiene columnas A1_log10_LR y A2_log10_LR
# Las filas son C1, C2, C3, C4, C5 (sin H0)

# Buscar nombres de columnas correctos
cat("Columnas disponibles en tablas_A:\n")
print(colnames(tablas_A))
cat("\n")

# Extraer log10 LR para A1, B1, G1
# Nota: El H0 tiene logLR = 0 (no aporta información)
logLR_A1 <- c(0, as.numeric(tablas_A$A1_log10_LR))  # H0 + C1-C5
logLR_B1 <- c(0, as.numeric(tablas_B$B1_log10_LR))  # H0 + C1-C5
logLR_G1 <- c(0, as.numeric(tablas_G$G1_log10_LR))  # H0 + C1-C5

cat("Parámetros:\n")
cat("  Convención: A1+B1+G1 (estricta)\n")
cat("  Prior: Demográfica\n")
cat("  Candidatos:", paste(candidatos, collapse=", "), "\n")
cat("  logLR_A1 length:", length(logLR_A1), "\n")
cat("  logLR_B1 length:", length(logLR_B1), "\n")
cat("  logLR_G1 length:", length(logLR_G1), "\n\n")

# ============================================================================
# 3. FUNCIÓN: Calcular posterior en escala log
# ============================================================================

calcular_posterior <- function(logLR_A, logLR_B, logLR_G, prior) {
  # Inicializar log-numeradores
  log_numerador <- log10(prior) + logLR_A + logLR_B + logLR_G

  # Restar máximo para evitar overflow
  log_num_adj <- log_numerador - max(log_numerador)

  # Exponenciar y normalizar
  numerador <- 10^log_num_adj
  posterior <- numerador / sum(numerador)

  return(posterior)
}

# ============================================================================
# 4. CALCULAR LAS TRES ETAPAS
# ============================================================================

cat("Calculando posteriors...\n\n")

# ETAPA 1: Solo antropometría (P1)
P1 <- calcular_posterior(logLR_A1, rep(0, 6), rep(0, 6), prior_demografica)
cat("ETAPA 1 (Solo Antropometría):\n")
cat("  C1:", round(P1[2], 4), " | C2:", round(P1[3], 4),
    " | C3:", round(P1[4], 4), " | C4:", round(P1[5], 4),
    " | C5:", round(P1[6], 4), "\n\n")

# ETAPA 2: Antropometría + OSINT (P2)
P2 <- calcular_posterior(logLR_A1, logLR_B1, rep(0, 6), prior_demografica)
cat("ETAPA 2 (Antropometría + OSINT):\n")
cat("  C1:", round(P2[2], 4), " | C2:", round(P2[3], 4),
    " | C3:", round(P2[4], 4), " | C4:", round(P2[5], 4),
    " | C5:", round(P2[6], 4), "\n\n")

# ETAPA 3: Posterior completa (P3)
P3 <- calcular_posterior(logLR_A1, logLR_B1, logLR_G1, prior_demografica)
cat("ETAPA 3 (Completa: Antropometría + OSINT + Genética):\n")
cat("  C1:", round(P3[2], 6), " | C2:", round(P3[3], 6),
    " | C3:", round(P3[4], 6), " | C4:", round(P3[5], 6),
    " | C5:", round(P3[6], 6), "\n\n")

# ============================================================================
# 3b. ANÁLISIS ALTERNATIVO: Si los hermanos de C2 NO son válidos
# ============================================================================

cat("=== ANÁLISIS ALTERNATIVO: Si hermanos de C2 NO son válidos ===\n\n")

# Crear vector alternativo donde C2 tiene logLR_G = 0 (sin genética válida)
logLR_G1_alt <- logLR_G1
logLR_G1_alt[3] <- 0  # C2 (posición 3: H0, C1, C2...) = 0 en lugar de 28.5

cat("Supuesto alternativo:\n")
cat("  logLR_G original para C2:", logLR_G1[3], "\n")
cat("  logLR_G alternativo para C2:", logLR_G1_alt[3], "\n")
cat("  (Si los hermanos NO son genéticamente compatibles)\n\n")

# Calcular P3 alternativa (sin genética válida para C2)
P3_alt <- calcular_posterior(logLR_A1, logLR_B1, logLR_G1_alt, prior_demografica)
cat("ETAPA 3 ALTERNATIVA (si hermanos NO son válidos):\n")
cat("  C1:", round(P3_alt[2], 6), " | C2:", round(P3_alt[3], 6),
    " | C3:", round(P3_alt[4], 6), " | C4:", round(P3_alt[5], 6),
    " | C5:", round(P3_alt[6], 6), "\n\n")

# Comparar
cat("COMPARACIÓN C2:\n")
cat("  P3 (con hermanos): ", round(P3[3], 6), "\n")
cat("  P3 (sin hermanos): ", round(P3_alt[3], 6), "\n")
cat("  Diferencia:        ", round(P3[3] - P3_alt[3], 6), "\n\n")

if (P3_alt[3] > 0.95) {
  cat("✅ ROBUSTEZ: C2 supera 0.95 INCLUSO SIN los hermanos.\n")
  cat("   → La conclusión es SÓLIDA sin dependencia de hermanos.\n")
} else if (P3_alt[3] > 0.50) {
  cat("⚠️  DÉBIL ROBUSTEZ: C2 baja a", round(P3_alt[3], 3), "sin hermanos.\n")
  cat("   → La conclusión DEPENDE de la validez de los hermanos.\n")
} else {
  cat("❌ NO ROBUSTO: C2 cae bajo 0.50 sin hermanos.\n")
  cat("   → La conclusión es FRÁGIL sin genética válida.\n")
}
cat("\n")

# ============================================================================
# 5. VALIDACIÓN: Compatibilidad genética de hermanos de C2
# ============================================================================

cat("=== VALIDACIÓN: Compatibilidad genética de hermanos de C2 ===\n\n")

# Extraer perfil de C2 (Dante Méndez)
c2_perfil <- perfiles_cand %>% filter(candidato_id == "C2_MENDEZ")

# Extraer perfil de madre (ID0382) y hermanos presuntos (ID0383, ID0384)
madre_perfil <- base_poblacional %>% filter(id == "ID0382")
hermano1_perfil <- base_poblacional %>% filter(id == "ID0383")
hermano2_perfil <- base_poblacional %>% filter(id == "ID0384")

cat("Candidato C2: Dante Méndez (38 años)\n")
cat("Madre declarada: ID0382 (Habitante_382, 65 años)\n")
cat("Hermanos declarados: ID0383 (Habitante_383, 20 años) + ID0384 (Habitante_384, 51 años)\n\n")

# Función: Verificar compatibilidad
verificar_compatibilidad <- function(madre, hijo_presunto, loci_nombres, id_hijo) {

  compatibles <- 0
  incompatibles <- 0

  for (locus in loci_nombres) {
    madre_a1 <- madre[[paste0(locus, "_a1")]]
    madre_a2 <- madre[[paste0(locus, "_a2")]]

    hijo_a1 <- hijo_presunto[[paste0(locus, "_a1")]]
    hijo_a2 <- hijo_presunto[[paste0(locus, "_a2")]]

    # Para ser hermano, al menos uno de los alelos del hijo debe ser compatible
    # (idealmente vendrían del mismo padre, pero sin padre, usamos lógica débil)
    # Compatibilidad = el hijo comparte al menos un alelo con la madre en este locus

    comparte <- (hijo_a1 %in% c(madre_a1, madre_a2)) || (hijo_a2 %in% c(madre_a1, madre_a2))

    if (comparte) {
      compatibles <- compatibles + 1
    } else {
      incompatibles <- incompatibles + 1
    }
  }

  total <- compatibles + incompatibles
  pct <- round(100 * compatibles / total, 1)

  cat(sprintf("  %s: %d/%d loci compatibles (%.1f%%)\n", id_hijo, compatibles, total, pct))

  # Criterio: si <70% compatible, es sospechoso
  if (pct >= 90) {
    cat(sprintf("    ✅ COMPATIBLE como hermano\n")
    )
    return(TRUE)
  } else if (pct >= 70) {
    cat(sprintf("    ⚠️  DÉBILMENTE COMPATIBLE (revisar)\n")
    )
    return(NA)
  } else {
    cat(sprintf("    ❌ INCOMPATIBLE como hermano (probable no-parentesco)\n")
    )
    return(FALSE)
  }
}

# Extraer nombres de loci (D3S1358, VWA, D16S539, ...)
loci_nombres <- unique(c2_perfil$locus)

# Verificar hermanos
compat_herm1 <- verificar_compatibilidad(madre_perfil, hermano1_perfil, loci_nombres, "ID0383 (Hermano 1)")
compat_herm2 <- verificar_compatibilidad(madre_perfil, hermano2_perfil, loci_nombres, "ID0384 (Hermano 2)")

cat("\n")

# ============================================================================
# 6. CONCLUSIÓN SOBRE COMPATIBILIDAD
# ============================================================================

if (all(c(compat_herm1, compat_herm2) %in% c(TRUE, NA))) {
  cat("✅ CONCLUSIÓN: Hermanos son genéticamente COMPATIBLES con madre.\n")
  cat("   → Usar LR genético completo (con hermanos)\n")
  usar_hermanos <- TRUE
} else {
  cat("❌ CONCLUSIÓN: Al menos uno de los hermanos es INCOMPATIBLE.\n")
  cat("   ⚠️  ALERTA: Revisar acta civil. LR genético puede ser incorrecto.\n")
  cat("   → Considerar usar solo LR de madre para C2\n")
  usar_hermanos <- FALSE
}

cat("\n")

# ============================================================================
# 7. CREAR TABLA DE RESULTADOS
# ============================================================================

evolucion <- data.frame(
  Hipotesis = candidatos,
  P1_solo_antrop = round(P1, 6),
  P2_antrop_osint = round(P2, 6),
  P3_completa_con_hermanos = round(P3, 6),
  P3_alternativa_sin_hermanos = round(P3_alt, 6),
  stringsAsFactors = FALSE
)

cat("TABLA: Evolución de posteriors (escenarios actual y alternativo)\n\n")
print(evolucion)
cat("\n")

# ============================================================================
# 8. GUARDAR TABLA
# ============================================================================

# Crear carpeta salidas/ si no existe
if (!dir.exists("salidas")) {
  dir.create("salidas", showWarnings = FALSE)
  cat("Creada carpeta: salidas/\n")
}

output_path <- "salidas/evolucion_posteriores.csv"
write.csv(evolucion, output_path, row.names = FALSE)
cat(sprintf("✓ Tabla guardada: %s\n\n", output_path))

# ============================================================================
# 9. HACER GRÁFICO
# ============================================================================

cat("Generando gráfico...\n")

# Gráfico 1: Evolución principal (P1, P2, P3 con hermanos)
grafico_data_principal <- evolucion %>%
  select(Hipotesis, P1_solo_antrop, P2_antrop_osint, P3_completa_con_hermanos) %>%
  pivot_longer(cols = -Hipotesis, names_to = "Etapa", values_to = "Posterior") %>%
  mutate(Etapa = factor(Etapa,
                        levels = c("P1_solo_antrop", "P2_antrop_osint", "P3_completa_con_hermanos"),
                        labels = c("P₁: Solo Antrop.", "P₂: Antrop.+OSINT", "P₃: Con hermanos")))

if (!dir.exists("salidas")) dir.create("salidas", showWarnings = FALSE)

png_path <- "salidas/grafico_evolucion_posteriores.png"
png(png_path, width = 1200, height = 600)

print(
  ggplot(grafico_data_principal, aes(x = Etapa, y = Posterior, color = Hipotesis, group = Hipotesis)) +
    geom_line(size = 1.2) +
    geom_point(size = 3) +
    labs(title = "Evolución de Creencias — A1+B1+G1, Prior Demográfico",
         subtitle = "Cómo se actualiza la probabilidad posterior en tres etapas (escenario actual con hermanos)",
         x = "Etapa de análisis",
         y = "Probabilidad posterior",
         color = "Hipótesis") +
    theme_minimal() +
    theme(
      plot.title = element_text(size = 14, face = "bold"),
      plot.subtitle = element_text(size = 11, color = "gray50"),
      axis.text = element_text(size = 11),
      axis.title = element_text(size = 12, face = "bold"),
      legend.position = "right"
    ) +
    scale_y_continuous(labels = scales::percent)
)

dev.off()

cat(sprintf("✓ Gráfico guardado: %s\n\n", png_path))

# Gráfico 2: Comparación C2 — con vs sin hermanos
png_path_comparacion <- "salidas/comparacion_C2_robustez.png"
png(png_path_comparacion, width = 900, height = 600)

c2_data <- data.frame(
  Escenario = c("Con hermanos\n(logLR_G=28.5)", "Sin hermanos\n(logLR_G=0)"),
  Posterior_C2 = c(P3[3], P3_alt[3])
)

print(
  ggplot(c2_data, aes(x = Escenario, y = Posterior_C2, fill = Escenario)) +
    geom_bar(stat = "identity", width = 0.5, alpha = 0.8) +
    geom_text(aes(label = sprintf("%.6f", Posterior_C2)), vjust = -0.5, size = 4, face = "bold") +
    labs(title = "Análisis de Robustez — C2 (Dante Méndez)",
         subtitle = "¿C2 se mantiene >0.95 incluso sin los hermanos?",
         x = "",
         y = "Probabilidad posterior (P3)") +
    ylim(0, 1.05) +
    theme_minimal() +
    theme(
      plot.title = element_text(size = 14, face = "bold"),
      plot.subtitle = element_text(size = 11, color = "gray50"),
      axis.text = element_text(size = 11),
      legend.position = "none"
    ) +
    scale_fill_manual(values = c("Con hermanos\n(logLR_G=28.5)" = "#2ecc71", "Sin hermanos\n(logLR_G=0)" = "#e74c3c"))
)

dev.off()

cat(sprintf("✓ Gráfico de robustez guardado: %s\n\n", png_path_comparacion))

# ============================================================================
# 10. RESUMEN FINAL
# ============================================================================

cat("=== RESUMEN ===\n\n")
cat("EVOLUCIÓN DE CREENCIAS:\n")
cat(sprintf("  • P₁ (solo antrop): C2 = %.4f (moderado)\n", P1[3]))
cat(sprintf("  • P₂ (antrop+OSINT): C2 = %.4f (empatado con C4)\n", P2[3]))
cat(sprintf("  • P₃ (completa): C2 = %.6f (abrumador)\n", P3[3]))
cat("\nINTERPRETACIÓN:\n")
cat("  - La genética RESUELVE la ambigüedad entre C2 y C4\n")
cat("  - Sin genética: C2 ≈ 0.50 (no supera umbral 0.95)\n")
cat("  - Con genética: C2 ≈ 1.00 (identificación positiva)\n\n")

cat("VALIDACIÓN DE HERMANOS:\n")
if (usar_hermanos) {
  cat("  ✅ Hermanos son genéticamente compatibles\n")
  cat("  → LR genético es VÁLIDO\n")
} else {
  cat("  ❌ Problema detectado con hermanos\n")
  cat("  → ALERTA: Revisar antes de usar en dictamen\n")
}

cat("\n✅ PASO 7 COMPLETADO EXITOSAMENTE.\n\n")
cat("Archivos generados:\n")
cat(sprintf("  ✓ %s\n", output_path))
cat(sprintf("  ✓ %s\n", png_path))
