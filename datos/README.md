# Datos de entrada — Caso 1872/2024

## Archivos CSV

Estos archivos contienen los valores de **likelihood ratio (LR)** calculados por el laboratorio para cada línea de evidencia y cada candidato.

### `tablas_A_antropometrica.csv`

**Bloque A:** Verosimilitud antropométrica

Basada en:
- Sexo estimado (masculino, P = 0.95)
- Edad estimada (35–50 años)
- Intervalo post-mortem (sept–nov 2023)

**Convenciones:**
- **A1 (estricta):** σ_edad = 5 años, IPM riguroso
- **A2 (moderada):** σ_edad = 7 años, IPM permisivo

Candidatos: C1, C2, C3, C4, C5 (H0 = 0 implícitamente)

**Uso:** Cargar columnas `log10_LR_antrop_A1` o `log10_LR_antrop_A2` según convención elegida.

---

### `tablas_B_osint.csv`

**Bloque B:** Verosimilitud OSINT (testimonios, registros, redes sociales)

Basada en:
- Testimonios de personas con conocimiento directo
- Registros municipales (laborales, policiales, sanitarios)
- Actividad en redes sociales y cronología de avistamientos
- Confiabilidad estimada de cada testimonio

**Convenciones:**
- **B1 (estricta):** Descuento α = 0.6 para testimonios correlacionados (familia)
- **B2 (moderada):** Descuento α = 0.5 (menos penalización)

**Uso:** Cargar columnas `log10_LR_OSINT_B1` o `log10_LR_OSINT_B2`.

---

### `tablas_G_robustez.csv`

**Bloque G:** Verosimilitud genética (STR markers)

Basada en:
- Perfiles STR de los restos (16 de 20 marcadores amplificados)
- Perfiles STR de parientes de los candidatos en base genética
- Cálculo de likelihood ratio sobre la base poblacional

**Convenciones:**

Ajusta el LR crudo del laboratorio con un factor β según grado de parentesco:

- **G1 (estricta):**
  - β = 1.0 para parientes 1° (madre, hermanos)
  - β = 0.5 para 2° (sobrino)
  - β = 0.3 para 3° (primo)

- **G2 (moderada):**
  - β = 1.0 para 1° grado
  - β = 0.95 para multi-1° (madre + hermanos)
  - β = 0.7 para 2°
  - β = 0.4 para 3°

**Fórmula:** `log10_LR_efectivo = β × log10_LR_lab`

**Uso:** Cargar columnas `log10_LR_efec_G1` o `log10_LR_efec_G2`.

---

## Notas técnicas

- Todos los valores están en escala **log₁₀** (logaritmo base 10)
- Para convertir a log natural (log_e): multiplica por ln(10) ≈ 2.303
- **H0 (hipótesis "ninguno"):** Siempre LR = 1, es decir, log₁₀(LR) = 0
- Los LR de genética pueden ser muy grandes (C2 ≈ 10²⁸) → por eso se usa log

---

## Referencias

- Para más contexto del caso, ver: `03 - La Herrumbre/02 - Las tres líneas de evidencia.md`
- Para metodología, ver: `02_calculos_bayesianos/README.md`
