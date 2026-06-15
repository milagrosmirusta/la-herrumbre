# ============================================================================
# SCRIPT MAESTRO: EJECUTAR ANÁLISIS BAYESIANO COMPLETO
# ============================================================================
# Ejecuta todos los scripts en orden para generar:
# - Tabla pericial
# - Análisis de sensibilidad (convenciones, λ)
# - KL divergence
# - Gráficos
# ============================================================================

cat("╔════════════════════════════════════════════════════════════════════════╗\n")
cat("║  ANÁLISIS BAYESIANO — CAUSA 1872/2024 (La Herrumbre)                  ║\n")
cat("║  Identificación forense de restos óseos                               ║\n")
cat("╚════════════════════════════════════════════════════════════════════════╝\n\n")

cat("Tiempo de inicio:", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n\n")

# ============================================================================
# EJECUTAR SCRIPTS
# ============================================================================

scripts <- c(
  "00_setup_convenciones.R",
  "01_calcular_posterior.R",
  "02_sensibilidad_convenciones.R",
  "03_progresion_etapas.R",
  "04_sensibilidad_lambda.R",
  "05_kl_divergence.R",
  "06_graficos.R"
)

for (i in seq_along(scripts)) {
  script <- scripts[i]
  cat(sprintf("\n[%d/%d] Ejecutando %s...\n", i, length(scripts), script))
  cat("────────────────────────────────────────────────────────────────────────\n")

  tryCatch({
    source(script)
    cat("\n✓ Completado\n")
  }, error = function(e) {
    cat("\n✗ ERROR:", e$message, "\n")
    stop(paste("Script", script, "falló"))
  })
}

# ============================================================================
# RESUMEN FINAL
# ============================================================================

cat("\n\n")
cat("╔════════════════════════════════════════════════════════════════════════╗\n")
cat("║  ✓ ANÁLISIS COMPLETADO CON ÉXITO                                      ║\n")
cat("╚════════════════════════════════════════════════════════════════════════╝\n\n")

cat("Archivos generados en 03_resultados/:\n\n")

cat("📊 TABLAS (CSV):\n")
cat("  • 01_tabla_pericial.csv\n")
cat("  • 02_sensibilidad_8combinaciones.csv\n")
cat("  • 03_progresion_posterior.csv\n")
cat("  • 04_sensibilidad_lambda.csv\n")
cat("  • 05_kl_divergence.csv\n")
cat("  • 05_kl_divergence_resumen.txt\n\n")

cat("📈 GRÁFICOS (PNG en graficos/):\n")
cat("  • 01_progresion_posterior.png\n")
cat("  • 02_sensibilidad_lambda.png\n")
cat("  • 03_sensibilidad_convenciones.png\n")
cat("  • 04_impacto_genetica.png\n\n")

cat("📋 DOCUMENTACIÓN:\n")
cat("  • README.md (este directorio)\n\n")

cat("Tiempo de finalización:", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n\n")

cat("👉 Próximo paso: Usar archivos en 03_resultados/ para mejorar la presentación PPT\n")
