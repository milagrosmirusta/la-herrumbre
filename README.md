# Caso A — La Herrumbre
### Identificación forense bayesiana · Causa 1872/2024

**Taller Integrador de Inferencia Bayesiana**  
Maestría en Minería de Datos, FCEN, UBA · Defensa: 23/06/2026  
**Página web del caso:** <https://herrumbrev2.netlify.app/>

---

## El caso

El 14 de enero de 2024, en el paraje El Bajo (Partido de La Herrumbre, Provincia de Buenos Aires) se recuperaron restos óseos humanos parcialmente degradados. El Laboratorio Forense Municipal procesó las muestras y la Fiscalía Departamental delimitó el espacio de hipótesis a cinco candidatos compatibles tras un cribado demográfico.

Se encarga un dictamen pericial bayesiano sobre seis hipótesis:

| Hipótesis | Descripción |
|-----------|-------------|
| H₀        | Los restos no corresponden a ninguno de los cinco candidatos |
| H₁ – H₅  | Los restos corresponden al candidato C1, C2, C3, C4 o C5 respectivamente |

---

## Líneas de evidencia

El análisis combina tres líneas bajo el supuesto de independencia condicional dado Hᵢ (los LR se multiplican; en escala log, se suman):

**Línea A — Antropométrica:** compatibilidad de los restos con el sexo, la edad estimada y el intervalo post-mortem (IPM) de cada candidato.

**Línea B — Fuentes abiertas (OSINT):** testimonios, registros municipales y actividad en redes sociales.

**Línea G — Genética:** verosimilitudes STR (Short Tandem Repeats) por pares, pre-computadas sobre la base poblacional del registro civil.

El Laboratorio entrega los cocientes de verosimilitud (LR) ya calculados en dos convenciones por línea: estricta (A1, B1, G1) y moderada (A2, B2, G2). La convención activa se declara en `src/scripts/00_setup_convenciones.R`.

---

## Estructura del repositorio

```
La-Herrumbre/
├── README.md
│
├── docs/                                  # Datos fuente (descargados del sitio)
│   ├── tablas_A_antropometrica.csv        # LR antropométrico (conv. A1 y A2)
│   ├── tablas_B_osint.csv                 # LR fuentes abiertas (conv. B1 y B2)
│   ├── tablas_G_robustez.csv              # LR genético efectivo (conv. G1 y G2)
│   ├── tablas_resumen_combinaciones.csv   # Resumen 8 combinaciones (laboratorio)
│   ├── base_poblacional.csv               # Distribución STR de la población
│   ├── perfiles_candidatos.csv            # Perfiles de los cinco candidatos
│   ├── tabla_parientes.csv                # Pedigrees declarados
│   ├── desgrabados_radio.csv              # Datos crudos de fuentes abiertas
│   └── guia_caso_A_Herrumbre.pdf          # Guía oficial del caso
│
└── src/
    ├── scripts/                           # Scripts de análisis
    │   ├── 00_setup_convenciones.R        # ← PARÁMETROS MODIFICABLES AQUÍ
    │   ├── 01_evolucion_posterior.R       # Posterior conv. elegida + 8 combinaciones
    │   ├── 02_evolucion_posterior_progresiva.R  # 3 etapas (A → A+B → A+B+G)
    │   ├── 03_kl_genetica.R               # Aporte informacional KL de la genética
    │   ├── 04_sensibilidad_lambda.R       # Sensibilidad al peso λ de la genética
    │   ├── 05_tabla_pericial.R            # Tabla pericial final (CSV + imagen PNG)
    │   └── _ejecutar_todo.R               # Corre los 5 scripts en orden
    │
    └── resultados/                        # Generado automáticamente por los scripts
        ├── 01a_posterior_convencion_elegida.csv
        ├── 01b_sensibilidad_8combinaciones.csv
        ├── 02_evolucion_progresiva.csv
        ├── 03_kl_genetica.csv
        ├── 04_sensibilidad_lambda.csv
        ├── 05_tabla_pericial.csv
        └── graficos/
            ├── 02a_etapa1_antropometria.png
            ├── 02b_etapa2_antrop_osint.png
            ├── 02c_etapa3_completa.png
            ├── 02d_evolucion_barras_apiladas.png
            ├── 03_kl_genetica.png
            ├── 04_sensibilidad_lambda.png
            └── 05_tabla_pericial.png
```

---

## Cómo reproducir el análisis

**Requisitos:** R ≥ 4.0 con los paquetes `tidyverse` y `gridExtra`.

```r
# Desde RStudio o terminal, con working directory en src/scripts/
setwd("src/scripts")
source("_ejecutar_todo.R")
```

Los resultados se escriben en `src/resultados/` y los gráficos en `src/resultados/graficos/`.

### Cambiar la convención

Editar únicamente `src/scripts/00_setup_convenciones.R`:

```r
CONVENCION_A <- "A1"   # "A1" (estricta) o "A2" (moderada)
CONVENCION_B <- "B1"   # "B1" (estricta) o "B2" (moderada)
CONVENCION_G <- "G1"   # "G1" (estricta) o "G2" (moderada)
```

El cambio se propaga automáticamente a todos los scripts al volver a ejecutar `_ejecutar_todo.R`.

---

*Ejercicio didáctico con datos simulados. La Herrumbre, sus habitantes, la Oficina Municipal y el Laboratorio Forense son construcciones ficticias.*
