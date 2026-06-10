#!/usr/bin/env python3
"""
ANÁLISIS BAYESIANO: Evolución de Posteriores
Caso: Identificación forense — La Herrumbre (Causa 1872/2024)

Análisis de tres etapas con escenario alternativo (robustez sin hermanos)
"""

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import warnings
warnings.filterwarnings('ignore')

# ============================================================================
# CONFIGURACIÓN
# ============================================================================

candidatos = ["H0", "C1", "C2", "C3", "C4", "C5"]
prior_uniforme = np.array([1/6] * 6)
prior_demografica = np.array([0.20, 0.18, 0.22, 0.12, 0.20, 0.08])

# ============================================================================
# 1. CARGAR DATOS
# ============================================================================

print("\n" + "="*70)
print("ANÁLISIS BAYESIANO: Evolución de Posteriores")
print("="*70 + "\n")

try:
    tablas_A = pd.read_csv("tablas_A_antropometrica.csv")
    tablas_B = pd.read_csv("tablas_B_osint.csv")
    tablas_G = pd.read_csv("tablas_G_robustez.csv")
    print("✓ Datos cargados exitosamente")
except FileNotFoundError as e:
    print(f"❌ Error: {e}")
    exit(1)

# Extraer logLR (convención A1+B1+G1)
logLR_A1 = np.concatenate(([0], tablas_A["A1_log10_LR"].values))
logLR_B1 = np.concatenate(([0], tablas_B["B1_log10_LR"].values))
logLR_G1 = np.concatenate(([0], tablas_G["G1_log10_LR_efectivo"].values))

print(f"\nLikelihood Ratios (escala log10):")
print(f"  Antropometría (A1): {logLR_A1}")
print(f"  OSINT (B1):         {logLR_B1}")
print(f"  Genética (G1):      {logLR_G1}")

# Validar
if len(logLR_A1) != 6 or len(logLR_B1) != 6 or len(logLR_G1) != 6:
    print(f"\n❌ Error: esperaba 6 hipótesis, pero tengo: A1: {len(logLR_A1)}, "
          f"B1: {len(logLR_B1)}, G1: {len(logLR_G1)}")
    exit(1)

# ============================================================================
# 2. FUNCIÓN PARA CALCULAR POSTERIOR
# ============================================================================

def calcular_posterior(logLR_A, logLR_B, logLR_G, prior):
    """
    Calcula posterior usando Theorem de Bayes en escala log.

    Posterior(H) ∝ Prior(H) × LR_A(H) × LR_B(H) × LR_G(H)

    En log: log_posterior = log_prior + log_LR_A + log_LR_B + log_LR_G
    """
    log_prior = np.log10(prior)
    log_LR_total = logLR_A + logLR_B + logLR_G
    log_posterior_unnorm = log_prior + log_LR_total

    # Log-sum-exp para normalización
    max_log = np.max(log_posterior_unnorm)
    log_posterior_unnorm_shifted = log_posterior_unnorm - max_log
    posterior_unnorm = 10 ** log_posterior_unnorm_shifted
    posterior = posterior_unnorm / np.sum(posterior_unnorm)

    return posterior

# ============================================================================
# 3. ETAPA 1: Solo Antropometría
# ============================================================================

print("\n" + "="*70)
print("ETAPA 1: Solo Antropometría (A1)")
print("="*70 + "\n")

P1 = calcular_posterior(logLR_A1, np.zeros(6), np.zeros(6), prior_demografica)
print(f"  H0: {P1[0]:.6e}")
print(f"  C1: {P1[1]:.6f} | C2: {P1[2]:.6f} | C3: {P1[3]:.6f}")
print(f"  C4: {P1[4]:.6f} | C5: {P1[5]:.6f}")

# ============================================================================
# 4. ETAPA 2: Antropometría + OSINT
# ============================================================================

print("\n" + "="*70)
print("ETAPA 2: Antropometría + OSINT (A1 + B1)")
print("="*70 + "\n")

P2 = calcular_posterior(logLR_A1, logLR_B1, np.zeros(6), prior_demografica)
print(f"  H0: {P2[0]:.6e}")
print(f"  C1: {P2[1]:.6f} | C2: {P2[2]:.6f} | C3: {P2[3]:.6f}")
print(f"  C4: {P2[4]:.6f} | C5: {P2[5]:.6f}")

# ============================================================================
# 5. ETAPA 3: Posterior Completa (CON hermanos)
# ============================================================================

print("\n" + "="*70)
print("ETAPA 3: Completa (Antropometría + OSINT + Genética A1+B1+G1)")
print("="*70 + "\n")

P3 = calcular_posterior(logLR_A1, logLR_B1, logLR_G1, prior_demografica)
print(f"  H0: {P3[0]:.6e}")
print(f"  C1: {P3[1]:.6f} | C2: {P3[2]:.6f} | C3: {P3[3]:.6f}")
print(f"  C4: {P3[4]:.6f} | C5: {P3[5]:.6f}")

# ============================================================================
# 6. ANÁLISIS ALTERNATIVO: Si hermanos de C2 NO son válidos
# ============================================================================

print("\n" + "="*70)
print("ANÁLISIS ALTERNATIVO: Si hermanos de C2 NO son válidos")
print("="*70 + "\n")

logLR_G1_alt = logLR_G1.copy()
logLR_G1_alt[2] = 0  # C2 (índice 2) = 0 en lugar de 28.5

print(f"Supuesto alternativo:")
print(f"  logLR_G original para C2: {logLR_G1[2]}")
print(f"  logLR_G alternativo para C2: {logLR_G1_alt[2]}")
print(f"  (Si los hermanos NO son genéticamente compatibles)\n")

P3_alt = calcular_posterior(logLR_A1, logLR_B1, logLR_G1_alt, prior_demografica)
print(f"ETAPA 3 ALTERNATIVA (si hermanos NO son válidos):")
print(f"  H0: {P3_alt[0]:.6e}")
print(f"  C1: {P3_alt[1]:.6f} | C2: {P3_alt[2]:.6f} | C3: {P3_alt[3]:.6f}")
print(f"  C4: {P3_alt[4]:.6f} | C5: {P3_alt[5]:.6f}\n")

# Comparación
print(f"COMPARACIÓN C2:")
print(f"  P3 (con hermanos): {P3[2]:.6f}")
print(f"  P3 (sin hermanos): {P3_alt[2]:.6f}")
print(f"  Diferencia:        {P3[2] - P3_alt[2]:.6f}\n")

if P3_alt[2] > 0.95:
    print("✅ ROBUSTEZ: C2 supera 0.95 INCLUSO SIN los hermanos.")
    print("   → La conclusión es SÓLIDA sin dependencia de hermanos.")
elif P3_alt[2] > 0.50:
    print(f"⚠️  DÉBIL ROBUSTEZ: C2 baja a {P3_alt[2]:.3f} sin hermanos.")
    print("   → La conclusión DEPENDE de la validez de los hermanos.")
else:
    print(f"❌ NO ROBUSTO: C2 cae bajo 0.50 sin hermanos.")
    print("   → La conclusión es FRÁGIL sin genética válida.")

# ============================================================================
# 7. CREAR TABLA DE RESULTADOS
# ============================================================================

print("\n" + "="*70)
print("TABLA: Evolución de Posteriores (Escenarios Actual y Alternativo)")
print("="*70 + "\n")

evolucion = pd.DataFrame({
    "Hipotesis": candidatos,
    "P1_solo_antrop": P1,
    "P2_antrop_osint": P2,
    "P3_completa_con_hermanos": P3,
    "P3_alternativa_sin_hermanos": P3_alt
})

print(evolucion.to_string(index=False))

# ============================================================================
# 8. GUARDAR TABLA
# ============================================================================

import os
if not os.path.exists("salidas"):
    os.makedirs("salidas")
    print("\n✓ Creada carpeta: salidas/")

output_path = "salidas/evolucion_posteriores.csv"
evolucion.to_csv(output_path, index=False)
print(f"✓ Tabla guardada: {output_path}")

# ============================================================================
# 9. HACER GRÁFICOS
# ============================================================================

print("\nGenerando gráficos...")

# Gráfico 1: Evolución principal
fig, ax = plt.subplots(figsize=(12, 6))

etapas = ["P₁: Solo Antrop.", "P₂: Antrop.+OSINT", "P₃: Con hermanos"]
x_pos = np.arange(len(etapas))
colors = plt.cm.Set2(np.linspace(0, 1, 6))

for i, (cand, color) in enumerate(zip(candidatos, colors)):
    y_vals = [P1[i], P2[i], P3[i]]
    ax.plot(x_pos, y_vals, marker='o', linewidth=2, markersize=8,
            label=cand, color=color)

ax.set_xlabel("Etapa de análisis", fontsize=12, fontweight='bold')
ax.set_ylabel("Probabilidad posterior", fontsize=12, fontweight='bold')
ax.set_title("Evolución de Creencias — A1+B1+G1, Prior Demográfico",
             fontsize=14, fontweight='bold')
ax.text(0.5, -0.15, "Cómo se actualiza la probabilidad posterior en tres etapas",
        transform=ax.transAxes, ha='center', fontsize=11, color='gray')
ax.set_xticks(x_pos)
ax.set_xticklabels(etapas)
ax.legend(loc='right')
ax.grid(True, alpha=0.3)
ax.set_ylim([0, 1.05])

plt.tight_layout()
png_path = "salidas/grafico_evolucion_posteriores.png"
plt.savefig(png_path, dpi=150, bbox_inches='tight')
print(f"✓ Gráfico guardado: {png_path}")
plt.close()

# Gráfico 2: Comparación C2 — con vs sin hermanos
fig, ax = plt.subplots(figsize=(9, 6))

escenarios = ["Con hermanos\n(logLR_G=28.5)", "Sin hermanos\n(logLR_G=0)"]
posteriors_c2 = [P3[2], P3_alt[2]]
colors_comp = ['#2ecc71', '#e74c3c']

bars = ax.bar(escenarios, posteriors_c2, color=colors_comp, alpha=0.8, width=0.5)

# Agregar etiquetas
for i, (bar, val) in enumerate(zip(bars, posteriors_c2)):
    ax.text(bar.get_x() + bar.get_width()/2, val + 0.02, f"{val:.6f}",
            ha='center', va='bottom', fontsize=11, fontweight='bold')

ax.set_ylabel("Probabilidad posterior (P3)", fontsize=12, fontweight='bold')
ax.set_title("Análisis de Robustez — C2 (Dante Méndez)",
             fontsize=14, fontweight='bold')
ax.text(0.5, -0.25, "¿C2 se mantiene >0.95 incluso sin los hermanos?",
        transform=ax.transAxes, ha='center', fontsize=11, color='gray')
ax.set_ylim([0, 1.05])
ax.grid(True, alpha=0.3, axis='y')

plt.tight_layout()
png_path_comp = "salidas/comparacion_C2_robustez.png"
plt.savefig(png_path_comp, dpi=150, bbox_inches='tight')
print(f"✓ Gráfico de robustez guardado: {png_path_comp}")
plt.close()

# ============================================================================
# RESUMEN FINAL
# ============================================================================

print("\n" + "="*70)
print("✅ ANÁLISIS COMPLETADO EXITOSAMENTE")
print("="*70 + "\n")

print("Archivos generados:")
print(f"  ✓ {output_path} (tabla con escenarios actual y alternativo)")
print(f"  ✓ {png_path} (gráfico de evolución P1→P2→P3)")
print(f"  ✓ {png_path_comp} (gráfico de robustez de C2)\n")

print("ANÁLISIS CLAVE:")
print("  • Escenario Actual: P3 con hermanos de C2 válidos (logLR_G = 28.5)")
print("  • Escenario Alternativo: P3 sin hermanos de C2 válidos (logLR_G = 0)")
print("  → Compara robustez: ¿C2 > 0.95 incluso sin hermanos?")
