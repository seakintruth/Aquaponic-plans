# Heating Water in a Fiberglass Tub: Calculation with Heat Losses

## Introduction
This document details the calculation of the time required to heat water from 72°F to 98°F in a fiberglass tub with a 5500W or 11000W heating element. The water volume is calculated from the tub's dimensions (default: length = 7 ft, width = 3.8 ft, depth = 3.5 ft). The tub has sides and bottom insulated with a combination of fiberglass and foam (total thickness in inches, minimum 0.1875 inches) and is located in a closet (indoor, 72°F air, 50% humidity, no wind). Heat losses occur from the top (via evaporation, convection, and radiation if uncovered, or conduction if covered with 3-inch polystyrene) and through the sides and bottom (conduction through the combined fiberglass and foam). The tub's dimensions and insulation thickness are configurable inputs.

## Assumptions
- **Tub Geometry**:
  - Default dimensions: Length = 7 ft, Width = 3.8 ft, Depth = 3.5 ft.
  - Volume: 7 × 3.8 × 3.5 ≈ 93.1 ft³ ≈ 696.2 gallons (1 ft³ = 7.48052 gallons).
  - Top area: 7 × 3.8 = 26.6 ft².
  - Side areas: 2 × (7 × 3.5) + 2 × (3.8 × 3.5) = 75.6 ft².
  - Bottom area: 7 × 3.8 = 26.6 ft².
  - Total sides + bottom: 102.2 ft².
- **Insulation**:
  - Sides/bottom: Combined fiberglass and foam with variable total thickness in inches (default 0.5 inches, minimum 0.1875 inches), effective \( k = 0.02 \, \text{Btu/hr·ft·°F} \).
  - Optional cover: 3-inch polystyrene (\( k = 0.02 \)).
- **Environment**:
  - Indoor closet: 72°F, 50% RH, 0 mph wind.
  - Radiation sink: Ambient air (no sky correction indoors).
- **Water**:
  - Volume: Calculated from dimensions (length × width × depth / 0.133681).
  - Density: 8.345 lb/gallon.
  - Specific heat: 1 Btu/lb·°F.
  - Heat capacity: Mass × specific heat.
- **Heater**: 5500W (18,771 Btu/hr) or 11000W (37,542 Btu/hr), 100% efficient.

## Physics and Formulas
The temperature rate of change is:
\[
\frac{dT}{dt} = \frac{P - Q_{\text{loss}}(T)}{C}
\]
- \( P \): Heater power (Btu/hr).
- \( C \): Heat capacity (mass × 1 Btu/lb·°F).
- \( Q_{\text{loss}}(T) \): Total heat loss (Btu/hr).

### Heat Losses
1. **Top (Uncovered)**:
   - **Evaporation**: \( q_e = 1050 \times (0.14 \times h_{cv}) \times (p_w - 0.5 \times p_a) \), \( h_{cv} = 1 \).
     - Vapor pressure: \( p(T) = 6.1094 \times \exp\left( \frac{17.625 \times T_C}{T_C + 243.04} \right) \times 0.0145038 \) psi.
   - **Convection**: \( q_{cv} = 1 \times (T_w - 72) \).
   - **Radiation**: \( q_r = 0.9 \times 1.713 \times 10^{-9} \times ((T_w + 460)^4 - (72 + 460)^4) \).
   - Total: \( q_{\text{top}} = q_e + q_{cv} + q_r \).

2. **Top (Covered)**:
   - Conduction: \( q_{\text{top}} = 0.02 \times (T_w - 72) / 0.25 = 0.08 \times (T_w - 72) \).

3. **Sides and Bottom**:
   - Conduction: \( q_{\text{sb}} = 0.02 \times (T_w - 72) / (\text{max(insulation_thickness_in, 0.1875)} / 12) \).

4. **Total Loss**:
   - Uncovered: \( Q_{\text{loss}} = q_{\text{top}} \times A_{\text{top}} + q_{\text{sb}} \times A_{\text{sides+bottom}} \).
   - Covered: \( Q_{\text{loss}} = 0.08 \times (T_w - 72) \times A_{\text{top}} + q_{\text{sb}} \times A_{\text{sides+bottom}} \).

## Python Implementation
The script below calculates the heating time, with tub dimensions and combined fiberglass/foam insulation thickness (in inches, minimum 0.1875 inches) as arguments to the `calculate_heating_time` function. The water volume is calculated from the dimensions. It runs for 5500W and 11000W heaters, covered and uncovered, using default dimensions of 7 ft × 3.8 ft × 3.5 ft and insulation thickness of 0.5 inches.