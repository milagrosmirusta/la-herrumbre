# Análisis Bayesiano — Causa 1872/2024, La Herrumbre

## Visión general

Este directorio contiene el análisis bayesiano completo para la identificación forense de restos óseos hallados en La Herrumbre (Buenos Aires, enero 2024).

**Tarea:** Combinar tres líneas de evidencia (antropometría, OSINT, genética) para construir una distribución posterior sobre 6 hipótesis (5 candidatos + "ninguno") y decidir quién es el fallecido.

---

## Convenciones elegidas

### Bloque A — Antropometría

**Convención: A1 (estricta)**

- σ_edad = 5 años (más restrictivo)
- IPM riguroso: penalización fuerte a candidatos con actividad registrada fuera de la ventana sept–nov 2023

**Justificación:**
- La ventana IPM (2–4 meses post-mortem) es clara y documentada.
- Candidatos con actividad digital posterior (ej. C3 en dic 2023) deben ser penalizados fuertemente.
- A1 favorece consistencia temporal.

---

### Bloque B — OSINT (testimonios, registros, redes)

**Convención: B1 (estricta)**

- Factor descuento para testimonios correlacionados: α = 0.6
- Trato cauteloso de la redundancia familiar.

**Justificación:**
- Los testimonios de 1° grado (madre, hermanos) son correlacionados pero confiables.
- No queremos descartar familias por redundancia, pero tampoco contar dos veces.
- α = 0.6 es un término medio: penaliza sin anular.

---

### Bloque G — Genética

**Convención: G1 (estricta)**

- β = 1.0 para parientes 1° grado (madre, hermanos, hermana)
- β = 0.5 para 2° grado (sobrino)
- β = 0.3 para 3° grado (primo)
- C1 sin pariente → LR = 1 (ausencia de información, no evidencia en contra)

**Justificación:**
- La genética es la evidencia más fuerte; merecemos ser cautelosos con métodos indirectos (parientes).
- C2 tiene madre + 2 hermanos (1° grado) → LR ~10²⁸ (abrumador).
- Incluso con penalización estricta (β=1.0), C2 mantiene ventaja decisiva.
- Parientes más lejanos pierden poder exponencialmente → penalización es razonable.

---

## Scripts de análisis

Ejecutar en orden:

### 1. `00_setup_convenciones.R`
- Carga tablas de LR del directorio `datos/`
- Define priors (uniforme y demográfico)
- Exporta `00_datos_setup.rds` para que otros scripts lo lean
- **Output:** Tabla con candidatos, priors, log-LR por bloque

### 2. `01_calcular_posterior.R`
- Implementa Teorema de Bayes en escala logarítmica
- Calcula P(H_i | E) para ambos priors
- Exporta `01_tabla_pericial.csv`
- **Output:** Tabla pericial con π_i, logLR_A/B/G, P(H_i|E)

### 3. `02_sensibilidad_convenciones.R`
- Calcula posterior bajo 8 combinaciones: A1/A2 × B1/B2 × G1/G2
- Evalúa robustez a decisiones metodológicas
- Exporta `02_sensibilidad_8combinaciones.csv`
- **Output:** Tabla 6×8 (hipótesis × convenciones)

### 4. `03_progresion_etapas.R`
- Muestra cómo evoluciona la posterior en 3 etapas
  - Etapa 1: π × L_A
  - Etapa 2: π × L_A × L_B
  - Etapa 3: π × L_A × L_B × L_G
- Exporta `03_progresion_posterior.csv`
- **Output:** Tabla 6×3 mostrando actualización secuencial

### 5. `04_sensibilidad_lambda.R`
- Pondera genética con λ ∈ {0, 0.3, 0.5, 0.7, 1.0}
- Responde: "¿A qué punto la conclusión depende de la genética?"
- Exporta `04_sensibilidad_lambda.csv`
- **Output:** Tabla 6×5 (hipótesis × valores de λ)

### 6. `05_kl_divergence.R`
- Calcula divergencia KL entre posterior con y sin genética
- Cuantifica aporte informacional: KL(p_con_G || p_sin_G)
- Desagrega contribución por candidato
- Exporta `05_kl_divergence.csv` y `05_kl_divergence_resumen.txt`
- **Output:** Valor de KL en nats y bits; tabla de contribución

### 7. `06_graficos.R`
- Genera 4 gráficos para presentación:
  1. Barras apiladas: progresión en 3 etapas
  2. Línea: sensibilidad a λ
  3. Heatmap: 8 combinaciones
  4. Comparativa: C2 vs C4 con y sin genética
- **Output:** 4 archivos PNG en `03_resultados/graficos/`

---

## Archivos de entrada

En el directorio `datos/`:

- `tablas_A_antropometrica.csv` — LR antropométrico (A1 y A2)
- `tablas_B_osint.csv` — LR OSINT (B1 y B2)
- `tablas_G_robustez.csv` — LR genético ajustado (G1 y G2)

---

## Archivos de salida

En el directorio `03_resultados/`:

**Tablas CSV:**
- `01_tabla_pericial.csv` — Tabla pericial principal
- `02_sensibilidad_8combinaciones.csv` — Posteriors para 8 combos
- `03_progresion_posterior.csv` — Evolución en 3 etapas
- `04_sensibilidad_lambda.csv` — Posteriors para diferentes λ
- `05_kl_divergence.csv` — Comparativa con/sin genética

**Documentos de texto:**
- `05_kl_divergence_resumen.txt` — Resumen KL en texto legible

**Gráficos (en `graficos/`):**
- `01_progresion_posterior.png`
- `02_sensibilidad_lambda.png`
- `03_sensibilidad_convenciones.png`
- `04_impacto_genetica.png`

---

## Nota técnica: Escala logarítmica

Todos los cálculos se hacen en **escala logarítmica** para evitar overflow numérico:

$$\log P(H_i | E) = \log \pi_i + \log LR(H_i) - \log Z$$

donde

$$\log Z = \log \left( \sum_j \pi_j \cdot L(H_j) \right)$$

Antes de exponenciar para volver a probabilidades reales, se resta el máximo del log-numerador:

```r
log_num_adj <- log_num - max(log_num)
posterior <- exp(log_num_adj) / sum(exp(log_num_adj))
```

Esto es crítico porque LR genético de C2 ≈ 10²⁸. Sin escala log, los cálculos no serían computables.

---

## Resultados principales

### Conclusión
Los restos óseos corresponden a **Dante Méndez (C2)** con una probabilidad posterior ≈ **100%** bajo:
- Convención A1 + B1 + G1
- Prior uniforme o demográfico
- Todas las 8 combinaciones de convenciones

### Robustez
- **A la elección de convenciones:** C2 gana en 8/8 combinaciones
- **Al peso λ de la genética:** C2 supera umbral 0.95 para λ ≥ 0.3
- **Al prior:** Igual resultado con prior uniforme y demográfico

### Aporte de la genética
- **KL divergence:** 0.85–1.07 bits (~35–40% de la información máxima)
- **Impacto:** Resolvió la indeterminación preexistente entre C2 (53%) y C4 (46%)
- **Genética de C2:** Coincidencia perfecta (16/16 marcadores) con madre + 2 hermanos → LR ~10²⁸

---

## Referencias teóricas

Los conceptos de clase aplicados en este análisis:

- [[Teorema de Bayes]] — la fórmula central: P(H|E) ∝ π × L
- [[Prior]] — distribución inicial π_i
- [[Likelihood]] — los LR de los tres bloques
- [[Posterior]] — distribución P(H_i|E) que calculamos
- [[Actualización secuencial]] — etapas 1, 2, 3
- [[Independencia condicional]] — supuesto que permite multiplicar LR
- [[Divergencia KL]] — mide aporte de la genética
- [[MAP (Maximum A Posteriori)]] — C2 es el máximo posterior
- [[Intervalo de credibilidad]] — no aplicable aquí (posterior colapsa)

---

## Cómo ejecutar

**Opción 1: Ejecutar scripts uno a uno**
```r
source("00_setup_convenciones.R")
source("01_calcular_posterior.R")
source("02_sensibilidad_convenciones.R")
# ... etc
```

**Opción 2: Script maestro (si existe)**
```r
source("_ejecutar_todo.R")
```

**Requisitos R:**
- `tidyverse` (dplyr, ggplot2, readr, stringr)
- `gridExtra` (opcional, para layouts complejos)

---

## Contacto / Preguntas

Para dudas sobre metodología, ver:
- Documentación del caso: `03 - La Herrumbre/`
- Guía de construcción: `GUÍA_CONSTRUCCIÓN_HERRUMBRE.md`
