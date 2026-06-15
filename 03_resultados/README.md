# Resultados del análisis bayesiano

Este directorio contiene todos los outputs del análisis: tablas, gráficos y documentos de síntesis.

## Archivos CSV (Tablas)

### `01_tabla_pericial.csv`

**Tabla pericial principal.** Resumida para presentación.

Columnas:
- `candidato` — H0, C1, C2, C3, C4, C5
- `pi_uniforme` — Prior uniforme (1/6 cada uno)
- `logLR_A` — Likelihood antropométrico (convención A1)
- `logLR_B` — Likelihood OSINT (convención B1)
- `logLR_G` — Likelihood genético (convención G1)
- `logLR_total` — Suma: logLR_A + logLR_B + logLR_G
- `posterior_uniforme` — P(H_i | evidencia) con prior uniforme
- `posterior_demografico` — P(H_i | evidencia) con prior demográfico

**Lectura:**
- Fila con `candidato = C2` es la decisión: posterior ≈ 1.0
- Todas las demás filas tienen posterior ≈ 0
- La conclusión es robusta a la elección de prior

---

### `02_sensibilidad_8combinaciones.csv`

**Análisis de robustez a convenciones.**

Filas: Las 8 combinaciones posibles:
- A1_B1_G1, A1_B1_G2, A1_B2_G1, A1_B2_G2
- A2_B1_G1, A2_B1_G2, A2_B2_G1, A2_B2_G2

Columnas: H0, C1, C2, C3, C4, C5 (posteriors)

**Lectura:**
- C2 domina en 8/8 combinaciones
- Desviación máxima de C2 es <<0.01 (es decir, siempre ~1.0)
- La identificación es ROBUSTA a metodología

---

### `03_progresion_posterior.csv`

**Evolución de la creencia en 3 etapas de actualización.**

Columnas:
- `candidato`
- `etapa_1_antrop` — P(H_i | prior + A)
- `etapa_2_antrop_abi` — P(H_i | prior + A + B)
- `etapa_3_completa` — P(H_i | prior + A + B + G)

**Lectura:**
- Etapa 1: múltiples hipótesis vivas
- Etapa 2: C3 muere (OSINT negativa), C2 y C4 empatados (~50/46%)
- Etapa 3: C2 gana abrumadoramente (genética decide)
- Ilustra el principio de actualización secuencial

---

### `04_sensibilidad_lambda.csv`

**Robustez al peso λ de la genética.**

Columnas:
- `candidato`
- `lambda_0.0` — P(H_i) sin genética
- `lambda_0.3` — P(H_i) con genética al 30%
- `lambda_0.5` — P(H_i) con genética al 50%
- `lambda_0.7` — P(H_i) con genética al 70%
- `lambda_1.0` — P(H_i) con genética al 100%

**Lectura:**
- λ = 0: C2 ≈ 0.53 (empatado con C4, no supera umbral 0.95)
- λ = 0.3: C2 ≈ 0.99 (supera umbral)
- λ ≥ 0.5: C2 ≈ 1.00 (dominante)
- **Conclusión:** la identificación depende de creerle a la genética, pero es robusta a confianza parcial (λ ≥ 0.3)

---

### `05_kl_divergence.csv`

**Comparativa de posteriors con y sin genética.**

Columnas:
- `candidato`
- `P_sin_genetica` — Posterior sin bloque G
- `P_con_genetica` — Posterior con bloque G
- `cambio_absoluto` — P_con - P_sin
- `cambio_relativo` — Cambio en % relativo

**Lectura:**
- C2 cambio: +0.470 (de 0.530 a 1.000)
- C4 cambio: −0.461 (de 0.461 a 0.000)
- Otros: cambios negligibles
- **Narrativa:** La genética resolvió la indeterminación preexistente

---

### `05_kl_divergence_resumen.txt`

**Resumen numérico en texto legible.**

Contiene:
- Valor KL en nats y bits
- Posteriors sin y con genética
- Interpretación cualitativa
- Contribución de cada candidato a la reducción de incertidumbre

**Lectura:** KL ≈ 0.85–1.07 bits = ~35–40% de la información máxima posible.

---

## Gráficos (PNG)

Todos en subdirectorio `graficos/`

### `01_progresion_posterior.png`

**Barras apiladas mostrando evolución en 3 etapas.**

Eje X: Etapa 1 (A), Etapa 2 (A+B), Etapa 3 (A+B+G)
Eje Y: Probabilidad posterior
Colores: Un color por candidato

**Lectura:**
- Etapa 1: barras variadas (múltiples hipótesis)
- Etapa 2: C3 desaparece, C2 y C4 compiten
- Etapa 3: C2 domina toda la barra

---

### `02_sensibilidad_lambda.png`

**Línea mostrando cómo cambia posterior de C2 con λ.**

Eje X: λ ∈ {0, 0.3, 0.5, 0.7, 1.0}
Eje Y: P(C2 | evidencia)
Línea roja punteada: Umbral 0.95

**Lectura:**
- λ = 0: C2 en ~0.53 (bajo umbral)
- λ = 0.3: C2 salta a ~0.99 (supera umbral)
- λ ≥ 0.5: C2 en 1.00 (dominante)

---

### `03_sensibilidad_convenciones.png`

**Heatmap de 8 combinaciones.**

Filas: H0, C1, C2, C3, C4, C5
Columnas: A1_B1_G1, A1_B1_G2, ..., A2_B2_G2
Color: Escala azul (blanco=0, azul oscuro=1)
Números en celdas: Valor de posterior

**Lectura:**
- Fila C2: todo azul oscuro (todos los valores ≈ 1.0)
- Todas las demás filas: blancas (todos ≈ 0)
- **Conclusión:** C2 gana en TODAS las combinaciones

---

### `04_impacto_genetica.png`

**Barras comparativas: C2 y C4 con y sin genética.**

Eje X: C2, C4
Eje Y: P(H_i | evidencia)
Colores: Naranja (sin genética), Verde (con genética)

**Lectura:**
- Sin genética: C2 ≈ 0.53, C4 ≈ 0.46 (casi iguales)
- Con genética: C2 ≈ 1.00, C4 ≈ 0.00 (resuelto)
- Línea roja: Umbral 0.95
- **Conclusión visual:** La genética es el factor decisivo

---

## Cómo usar estos archivos

### Para la presentación PPT:

1. **Tabla pericial:** Copiar `01_tabla_pericial.csv` a una slide con tabla
2. **Gráficos:** Insertar los 4 PNG en slides de resultados
3. **Narrativa:** Leer los CSV y los gráficos para redactar conclusiones

### Para defensa oral:

1. Tener abiertos los gráficos durante la presentación
2. Referirse a números específicos de los CSVs
3. Explicar por qué las convenciones A1+B1+G1 fueron elegidas (ver `02_calculos_bayesianos/README.md`)

### Para auditoría/reproducibilidad:

1. Ver los scripts en `02_calculos_bayesianos/`
2. Verificar que los números coincidan entre:
   - Inputs (datos/*.csv)
   - Scripts (.R)
   - Outputs (este directorio)

---

## Validación de resultados

**Checklist de coherencia:**

- [ ] `01_tabla_pericial.csv`: posterior suma a 1 (validar en hoja de cálculo)
- [ ] `02_sensibilidad_8combinaciones.csv`: C2 es máximo en todas las 8 filas
- [ ] `03_progresion_posterior.csv`: valores crecientes/decrecientes lógicos por candidato
- [ ] `04_sensibilidad_lambda.csv`: λ=0 ≈ valores de etapa 2, λ=1 ≈ valores de etapa 3
- [ ] `05_kl_divergence.csv`: cambios son coherentes entre candidatos
- [ ] Gráficos: **no hay overlaps de texto, números son legibles, colores distinguibles**

---

## Archivos de referencia

- Análisis metodológico: `02_calculos_bayesianos/README.md`
- Documentación del caso: `03 - La Herrumbre/`
- Guía de construcción: `GUÍA_CONSTRUCCIÓN_HERRUMBRE.md`
