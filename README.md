# Rocket Staging Optimizer
Optimizes 2-stage rocket designs for maximum payload fraction using the Tsiolkovsky rocket equation. Models delta-v budgets, mass ratios, and structural fractions across configurable engine parameters with an interactive MATLAB interface and 5-panel output visualization.

## Physics Model
- **Tsiolkovsky Rocket Equation:** $\Delta v = I_{sp} \cdot g_0 \cdot \ln(m_0/m_f)$
- **Payload fraction** computed as the product of both stage payload fractions
- **Structural mass fraction (epsilon)** accounts for tank and hardware dead weight per stage
- **Delta-v split sweep** across all possible stage 1/stage 2 distributions to find the global optimum

## Features
- Interactive command-line parameter input with defaults
- Optimal delta-v split and full mass breakdown at the optimum
- Single-stage-to-orbit (SSTO) reference comparison
- 5-panel output figure: payload fraction curve, liftoff mass, mass ratios, mass breakdown pie chart, and Isp sensitivity
- Flight summary printed to console on every run

## Requirements
- MATLAB (base installation — no toolboxes required)

## Usage
1. Clone the repo and open `rocket_staging_optimizer.m` in MATLAB
2. Press **Run** (or type `rocket_staging_optimizer` in the command window)
3. Enter parameters when prompted — press **Enter** to use the default value

## Parameters
| Parameter | Description | Units |
|---|---|---|
| Total delta-v | Mission velocity requirement | m/s |
| Payload mass | Mass of the payload to be delivered | kg |
| Stage 1 Isp | Stage 1 engine specific impulse | s |
| Stage 1 epsilon | Stage 1 structural mass fraction | — |
| Stage 2 Isp | Stage 2 engine specific impulse | s |
| Stage 2 epsilon | Stage 2 structural mass fraction | — |
| Sweep points | Number of delta-v split points evaluated | — |

## Example Presets

| Scenario | dv (m/s) | Payload (kg) | Isp1 (s) | eps1 | Isp2 (s) | eps2 |
|---|---|---|---|---|---|---|
| LEO (Falcon 9-like) | 9400 | 100 | 310 | 0.06 | 350 | 0.08 |
| Moon Mission | 12000 | 50 | 310 | 0.08 | 450 | 0.10 |
| Solid/Liquid Hybrid | 9400 | 75 | 280 | 0.10 | 450 | 0.08 |
| Small Sounding Rocket | 3000 | 10 | 280 | 0.12 | 300 | 0.15 |

> Keep structural fractions (eps) between 0.06 and 0.15. Values above 0.20 will produce infeasible solutions.

## Output
**Figure 1 — Optimization Results**
- Payload fraction vs delta-v split with optimum marker
- Total liftoff mass vs delta-v split
- Stage 1 and Stage 2 mass ratios across all splits
- Mass breakdown pie chart at optimum (propellant, structure, payload)
- Payload fraction sensitivity to Stage 2 Isp
