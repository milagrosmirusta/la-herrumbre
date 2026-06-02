# Caso A "La Herrumbre" — Resumen de las combinaciones canónicas

Identificación forense bayesiana sobre 6 hipótesis (H0 + 5 candidatos C1–C5),
combinando tres líneas evidenciales: antropométrica (A), OSINT (B) y genética (G),
cada una con dos convenciones (estricta / moderada).

## Qué hay en esta carpeta

| Archivo | Qué hace |
|---|---|
| `combinaciones_canonicas.R` | Calcula la posterior de las **8 combinaciones canónicas** (A1/A2 × B1/B2 × G1/G2) bajo prior demográfica y uniforme. Valida contra el ground-truth. |
| `aporte_genetica_KL.R` | **Paso 5**: divergencia KL del aporte de la línea genética (posterior con vs. sin genética). |
| `sensibilidad_lambda.R` | **Paso 6**: barrido del peso λ ∈ {0, 0.3, 0.5, 0.7, 1.0} de la genética + decisión forense con umbral 0.95. |
| `salidas/` | CSVs y gráficos generados por los scripts. |

**Cómo correr** (con el working directory en esta carpeta):
```bash
Rscript combinaciones_canonicas.R
Rscript aporte_genetica_KL.R
Rscript sensibilidad_lambda.R
```

## Método

Posterior en escala log10, sumando log-evidencias y normalizando **una sola vez al final**
(log-sum-exp, restando el máximo antes de exponenciar):

```
log P(H|E) ∝ log10(prior) + log10 LR_A + log10 LR_B + log10 LR_G
```

Los LR vienen pre-calculados por el laboratorio (LR(H0) = 1 → log = 0 en las tres líneas).

## Resultados principales

### 1. Las 8 combinaciones canónicas
- **C2 (Dante Méndez) gana con posterior ≈ 1.0 en las 8 combinaciones**, bajo ambos priors.
- La identificación completa (con genética) es **robusta a la convención** elegida: la genética
  domina ~31 órdenes de magnitud y colapsa la masa en C2 en todos los casos.

### 2. Validación contra el ground-truth (`tablas_resumen_combinaciones.csv`)
- `log10_LR_total`: **48/48 ✓** (coincide exacto).
- `posterior_completa`: **48/48 ✓** bajo ambos priors.
- `posterior_sin_genetica`: coincide **48/48 con prior UNIFORME** y solo 22/48 con demográfico.
  → **El laboratorio armó su ground-truth con prior uniforme.** (Detalle metodológico a declarar.)

### 3. Aporte de la genética (divergencia KL)
- La genética agrega entre **0.85 y 1.07 bits** según la combinación.
- Aporte **moderado en información**: aunque concentra la masa en C2, la posterior sin genética
  ya favorecía a C2/C4, así que el "movimiento" relativo no es enorme.
- El KL es algo mayor bajo prior uniforme (la genética tiene más trabajo cuando se parte sin
  información demográfica).

### 4. Sensibilidad al peso λ de la genética (umbral 0.95)
- **Con λ = 0 (sin genética): NINGUNA combinación supera el umbral.** El ganador queda en ~0.50.
  → Sin genética **no hay identificación positiva**.
- La identificación positiva (> 0.95) aparece recién desde **λ = 0.3** y se mantiene hasta λ = 1.
- ⚠️ **Bajo prior uniforme + OSINT moderada (B2), a λ = 0 el ganador es C4, no C2.** La genética
  es la que da vuelta el resultado hacia C2.

## Conclusión forense sugerida

La identificación de **C2 (Dante Méndez)** es **robusta** a la convención y al prior, **siempre
que se le dé peso a la línea genética (λ ≥ 0.3)**. Sin embargo, la conclusión es **dependiente de
la genética**: sin ella, antropometría + OSINT no alcanzan el umbral de 0.95 y, en algunos
escenarios, ni siquiera coinciden en el candidato más probable.

Recomendación: declarar **identificación positiva de C2**, dejando explícito en el dictamen que
la conclusión se apoya de forma decisiva en la línea genética (el caso del PDF advierte
justamente sobre identificaciones sostenidas "sólo con la genética entera").

---

## Pendientes / posibles próximos pasos
- Desagregar la antropometría en sub-componentes (sexo, edad, IPM) como subred — el LR_sexo = 1.9
  es constante y no discrimina (se cancela en la normalización).
- Armar el diagrama del DAG (Naive Bayes) para la presentación.
- Borrador del dictamen / PPT (defensa final: 23/06/2026).
