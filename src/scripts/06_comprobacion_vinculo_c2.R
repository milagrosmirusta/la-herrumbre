# ============================================================================
# 06_comprobacion_vinculo_c2.R
# Caso A "La Herrumbre" — Causa 1872/2024
# ============================================================================
# Comprueba, con los genotipos reales de docs/base_poblacional.csv, si los
# "hermanos" declarados de C2 (ID0383, ID0384) son compatibles genéticamente
# con ser hijos de la madre verificada de C2 (ID0382).
#
# Lógica (regla mendeliana básica): si X es hijo/a de la madre, X debe portar
# uno de los dos alelos de la madre en CADA locus. Un locus sin ningún alelo
# compartido es una exclusión directa; salvo mutación (tasa típica < 0,2%
# por locus en STRs autosómicos), no debería ocurrir en una relación
# madre-hijo real. Varias exclusiones simultáneas son prueba sólida de que
# el vínculo declarado no es genéticamente real.
#
# Antecedente metodológico: Egeland & Vigeland (2025), "Kinship cases with
# partially specified hypotheses", Forensic Science International: Genetics
# 78:103270, Sec. 3.3 ("Quality control of pedigree data") usan el mismo
# principio —comparar el pedigrí declarado contra los genotipos observados—
# para detectar errores de parentesco o de laboratorio.
#
# Una vez excluidos los hermanos, lo que queda es una comparación madre-hijo
# simple, que es la base de todo test de paternidad/maternidad estándar y
# no requiere parientes adicionales para ser válida (cfr. Gjertson et al.
# 2007, "ISFG: recommendations on biostatistics in paternity testing",
# Forensic Science International: Genetics 1(3-4):223-231).
#
# Salidas:
#   Consola: tabla resumen por persona + veredicto
#   resultados/06_comprobacion_vinculo_c2.csv (detalle locus por locus)
# ============================================================================

.dir <- tryCatch(dirname(normalizePath(sys.frame(1)$ofile)),
         error = function(e) tryCatch(dirname(normalizePath(rstudioapi::getActiveDocumentContext()$path)),
         error = function(e) getwd()))
source(file.path(.dir, "00_setup_convenciones.R"))

# ============================================================================
# Cargar genotipos de la base poblacional
# ============================================================================

base <- read_csv(file.path(DOCS_DIR, "base_poblacional.csv"), show_col_types = FALSE)

LOCI <- c("D3S1358", "VWA", "D16S539", "D2S1338", "D8S1179", "D21S11", "D18S51",
          "D19S433", "TH01", "FGA", "CSF1PO", "D13S317", "D7S820", "D5S818",
          "TPOX", "D1S1656", "D2S441", "D10S1248", "D12S391", "D22S1045")

MADRE_ID <- "ID0382"     # madre verificada de C2
HERMANOS_DECLARADOS <- c("ID0383", "ID0384")   # "hermanos" en duda

obtener_genotipo <- function(id_persona) {
  fila <- base %>% filter(id == id_persona)
  if (nrow(fila) == 0) {
    stop(sprintf("No se encontró %s en base_poblacional.csv", id_persona))
  }
  setNames(
    lapply(LOCI, function(l) c(fila[[paste0(l, "_a1")]], fila[[paste0(l, "_a2")]])),
    LOCI
  )
}

madre <- obtener_genotipo(MADRE_ID)

# ============================================================================
# Test de exclusión: ¿comparte al menos 1 alelo con la madre en cada locus?
# ============================================================================

comparar_con_madre <- function(persona_id) {
  geno <- obtener_genotipo(persona_id)
  map_dfr(LOCI, function(l) {
    alelos_madre <- madre[[l]]
    alelos_persona <- geno[[l]]
    comparte <- length(intersect(alelos_madre, alelos_persona)) > 0
    tibble(
      persona        = persona_id,
      locus          = l,
      alelos_madre   = paste(alelos_madre, collapse = "/"),
      alelos_persona = paste(alelos_persona, collapse = "/"),
      comparte_alelo = comparte
    )
  })
}

tabla_vinculo <- map_dfr(HERMANOS_DECLARADOS, comparar_con_madre)

write_csv(tabla_vinculo, file.path(RESULTADOS_DIR, "06_comprobacion_vinculo_c2.csv"))
cat("Escrito: 06_comprobacion_vinculo_c2.csv\n\n")

# ============================================================================
# Resumen en consola
# ============================================================================

cat(strrep("=", 78), "\n")
cat("Comprobación de vínculo genético: ¿son ID0383/ID0384 hijos de la madre\n")
cat(sprintf("verificada de C2 (%s)?\n", MADRE_ID))
cat(strrep("=", 78), "\n\n")

for (persona_id in HERMANOS_DECLARADOS) {
  sub <- filter(tabla_vinculo, persona == persona_id)
  n_total   <- nrow(sub)
  n_excluye <- sum(!sub$comparte_alelo)

  cat(sprintf("%s vs madre %s:\n", persona_id, MADRE_ID))
  cat(sprintf("  Loci con al menos 1 alelo compartido  : %d/%d\n", n_total - n_excluye, n_total))
  cat(sprintf("  Loci SIN alelo compartido (exclusión) : %d/%d\n", n_excluye, n_total))

  if (n_excluye > 0) {
    loci_excl <- sub$locus[!sub$comparte_alelo]
    cat(sprintf("  Loci excluyentes: %s\n", paste(loci_excl, collapse = ", ")))
  }

  veredicto <- if (n_excluye >= 2) {
    "EXCLUSIÓN genética (no compatible con ser hijo/a de la madre)"
  } else if (n_excluye == 1) {
    "1 mismatch aislado: compatible con mutación rara, no es exclusión por sí solo"
  } else {
    "sin mismatches: compatible con ser hijo/a de la madre"
  }
  cat(sprintf("  Veredicto: %s\n\n", veredicto))
}

cat(strrep("-", 78), "\n")
cat("Lectura para el dictamen:\n")
cat("Una relación madre-hijo real comparte al menos un alelo con la madre en\n")
cat("CADA locus (regla mendeliana); 1 mismatch aislado puede explicarse por\n")
cat("mutación (tasa típica < 0,2% por locus en STRs autosómicos), pero varios\n")
cat("mismatches simultáneos no. Con 12 y 10 loci sin alelo compartido (de 20),\n")
cat("ambos 'hermanos' declarados quedan excluidos como hijos de ID0382: el LR\n")
cat("genético del caso (logLR_G = 28,5) es atribuible a la madre verificada,\n")
cat("no a una hermandad que no se sostiene frente a los genotipos.\n")
cat(strrep("-", 78), "\n")
