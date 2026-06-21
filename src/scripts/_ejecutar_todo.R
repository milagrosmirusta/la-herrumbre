# ============================================================================
# _ejecutar_todo.R
# Caso A "La Herrumbre" — Causa 1872/2024
# ============================================================================
# Script maestro: ejecuta el análisis completo en orden.
# Correr desde la carpeta src/scripts/:
#
#   Rscript _ejecutar_todo.R
#
# O desde RStudio: setwd("src/scripts") → source("_ejecutar_todo.R")
#
# PARA CAMBIAR LA CONVENCIÓN: editar 00_setup_convenciones.R
# (las variables CONVENCION_A, CONVENCION_B, CONVENCION_G)
# El cambio se propaga automáticamente a todos los scripts.
# ============================================================================

cat("╔══════════════════════════════════════════════════════════════════════╗\n")
cat("║  Caso A \"La Herrumbre\" — Análisis Bayesiano Forense                 ║\n")
cat("║  Causa 1872/2024                                                    ║\n")
cat("╚══════════════════════════════════════════════════════════════════════╝\n\n")
cat("Inicio:", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n\n")

scripts <- c(
  "01_evolucion_posterior.R",
  "02_evolucion_posterior_progresiva.R",
  "03_kl_genetica.R",
  "04_sensibilidad_lambda.R",
  "05_tabla_pericial.R"
)

for (i in seq_along(scripts)) {
  cat(sprintf("\n[%d/%d] %s\n", i, length(scripts), scripts[i]))
  cat(strrep("─", 60), "\n")
  tryCatch(
    source(scripts[i]),
    error = function(e) {
      cat("✗ ERROR:", conditionMessage(e), "\n")
      stop(paste("Fallo en:", scripts[i]))
    }
  )
  cat("✓ OK\n")
}

cat("\n\n╔══════════════════════════════════════════════════════════════════════╗\n")
cat("║  ✓ Análisis completado exitosamente                                  ║\n")
cat("╚══════════════════════════════════════════════════════════════════════╝\n\n")

cat("Archivos generados en src/resultados/:\n\n")
cat("  CSV:\n")
cat("    01a_posterior_convencion_elegida.csv\n")
cat("    01b_sensibilidad_8combinaciones.csv\n")
cat("    02_evolucion_progresiva.csv\n")
cat("    03_kl_genetica.csv\n")
cat("    04_sensibilidad_lambda.csv\n")
cat("    05_tabla_pericial.csv\n\n")
cat("  Gráficos (graficos/):\n")
cat("    02a_etapa1_antropometria.png\n")
cat("    02b_etapa2_antrop_osint.png\n")
cat("    02c_etapa3_completa.png\n")
cat("    02d_evolucion_barras_apiladas.png\n")
cat("    03_kl_genetica.png\n")
cat("    04_sensibilidad_lambda.png\n")
cat("    05_tabla_pericial.png\n\n")

cat("Fin:", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n")
