---

editor_options: 
  markdown: 
    wrap: 72
---

# La Herrumbre — Caso Práctico Bayesiano

**Defensa:** 23/06/2026 \| **Causa:** 1872/2024 \| **Objetivo:** Identificación forense de restos óseos mediante inferencia bayesiana discreta

**Página web**: <https://herrumbrev2.netlify.app/>

------------------------------------------------------------------------

## El caso en una línea

Combinar tres líneas de evidencia (antropometría, OSINT, genética) con el Teorema de Bayes para identificar a quién pertenecen unos restos hallados en la zona rural de Buenos Aires. Seis hipótesis: H₀ (ninguno) + 5 candidatos.

------------------------------------------------------------------------

## Estructura del repositorio

```         
La-Herrumbre/
├── README.md                          
│
├── combinaciones_canonicas/
│   ├── combinaciones_canonicas.R      
│   ├── aporte_genetica_KL.R           
│   ├── sensibilidad_lambda.R         
│   ├── RESUMEN.md                    
│   └── salidas/
│       ├── resumen_8_combinaciones.csv
│       ├── aporte_genetica_KL.csv
│       ├── sensibilidad_lambda_*.csv
│       ├── validacion_vs_groundtruth.csv
│       └── grafico_*.png              (3 gráficos)
│
├── tablas_A_antropometrica.csv        (LR antropométrico)
├── tablas_B_osint.csv                 (LR OSINT)
├── tablas_G_robustez.csv              (LR genético efectivo)
├── tablas_resumen_combinaciones.csv   (ground-truth para validación)
├── desgrabados_radio.csv              (evidencia OSINT auxiliar)
│
└── Prior Demográfica - Tres Líneas.R  (análisis exploratorio inicial)
```

------------------------------------------------------------------------

## Flujo de trabajo

### PASO 1–2: Contexto y decisiones metodológicas

**Estado:** Implícito en los scripts.

- Candidatos: C1–C5 descritos en la guía
- Restos: Sexo M, edad 35–50 años, IPM sept–nov 2023
- Convenciones elegidas: **A1+B1+G1** (justificación por confirmarse)
  - A1: antropometría estricta (σ edad = 5 años, IPM riguroso)
  - B1: OSINT estricta (factor descuento = 0.6)
  - G1: robustez genética estricta (β diferenciados por grado)

------------------------------------------------------------------------

### PASO 3–4: Cargar datos y calcular posterior

**Estado:** Completado. Script: `combinaciones_canonicas.R`

- Carga 3 CSVs → calcula log-LR total por combinación
- Usa log-sum-exp para evitar overflow (10²⁸)
- Normaliza una sola vez al final
- Salida: tabla con P(H\|E) bajo prior uniforme y demográfico

**Resultado clave:** C2 (Dante Méndez) ≈ 1.0 en todas las 8 combinaciones.

------------------------------------------------------------------------

### PASO 5: Aporte informacional de la genética

**Estado:** Completado. Script: `aporte_genetica_KL.R`

- Calcula posterior sin genética: P(H\|A,B)
- Divergencia KL: ¿cuánta información aportó la genética?
- Resultado: KL = 0.85–1.07 bits según combinación (aporte moderado pero decisivo)

------------------------------------------------------------------------

### PASO 6: Sensibilidad

**Estado:** Completado. Script: `sensibilidad_lambda.R`

**6.1 Prior:** Uniforme vs. demográfico → C2 gana en ambos

**6.2 Peso λ de la genética:** - λ = 0 (sin genética): C2 ≈ 0.53, NO supera 0.95 - λ = 0.3–0.7: transición gradual - λ = 1.0 (con genética): C2 ≈ 1.0

**6.3 Todas las 8 combinaciones:** C2 gana siempre (con genética)

------------------------------------------------------------------------

### PASO 7: Evolución de las creencias (P₁, P₂, P₃) + Análisis de Robustez

**Estado:** ✅ Completado. Script: `evolucion_posteriores.py`

Progresión de actualización bayesiana:
- **P₁:** Posterior solo con antropometría → C2 ≈ 45.8%
- **P₂:** Posterior con antropometría + OSINT → C2 ≈ 55.6%
- **P₃ (Con hermanos):** Posterior completa → C2 ≈ 1.000
- **P₃ (Sin hermanos):** Si los hermanos NO son válidos → **C4 ≈ 1.000** (C2 colapsa)

**HALLAZGO CRÍTICO:** La conclusión depende 100% de la validez de los hermanos de C2. Si los hermanos (ID0383, ID0384) resultan NO ser genéticamente compatibles con C2, entonces **C4 (Federico Almada) se convierte en el candidato identificado**.

Salida: `evolucion_posteriores.csv` + dos gráficos de evolución

------------------------------------------------------------------------

### PASO 8: Decisión forense final

**Estado:** Análisis técnico en RESUMEN.md. Falta narrativa formal.

**Umbral de decisión:** P(C2) \> 0.95 bajo: - ✅ Prior uniforme + A1+B1+G1 - ✅ Prior demográfico + A1+B1+G1 - ✅ Todas las 8 combinaciones - ✅ λ ≥ 0.3

------------------------------------------------------------------------

##  Cómo correr los scripts

``` bash
cd combinaciones_canonicas/
Rscript combinaciones_canonicas.R    # Genera resumen_8_combinaciones.csv
Rscript aporte_genetica_KL.R         # Genera aporte_genetica_KL.csv
Rscript sensibilidad_lambda.R        # Genera sensibilidad_lambda_*.csv
```

Los gráficos se guardan automáticamente en `salidas/`.

------------------------------------------------------------------------

## Hallazgos principales

### Conclusión técnica
- **C2 (Dante Méndez) es identificado con posteridad ≈ 1.0** bajo la combinación elegida (A1+B1+G1) y ambos priors.
- **La genética es decisiva:** sin ella, C2 ≈ 0.53 (bajo umbral). Con genética, domina \~31 órdenes de magnitud.
- **Robustez a convenciones:** identificación se mantiene en todas las 8 combinaciones.

### ⚠️ Hallazgo crítico de sensibilidad
- **La conclusión es FRÁGIL:** Depende 100% de la validez de los hermanos de C2 (ID0383, ID0384).
- **Escenario alternativo:** Si los hermanos NO son válidos → **C4 (Federico Almada) = 1.000** (C2 colapsa a 10⁻¹²)
- **Recomendación forense:** Verificar filiación civil de C2 antes de dictar. Declarar explícitamente en dictamen que la conclusión supone validez de hermanos.

### Validación
- **Ground-truth:** posterior_completa coincide en 48/48 casos con datos del laboratorio.

------------------------------------------------------------------------

**Última actualización:** 10/06/2026 — Análisis de robustez completado
