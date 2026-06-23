# ============================================================================
# 06_comprobacion_vinculo_c2.R
# Caso A "La Herrumbre" — Causa 1872/2024
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


