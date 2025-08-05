import numpy as np
from scipy.integrate import solve_ivp

# inputs
length_ft = 7
width_ft = 3.8
depth_ft = 3.5
T_air = 68
T_final = 101
wind_mph = 0
insulation_thickness_in = 0.19  # including fiberglass thickness

T_initial = T_air

def f_to_c(T_f):
    return (T_f - 32) * 5 / 9

def sat_vapor_pressure_psi(T_f):
    T_c = f_to_c(T_f)
    p_hpa = 6.1094 * np.exp(17.625 * T_c / (T_c + 243.04))
    return p_hpa * 0.0145038  # Convert hPa to psi

def heat_loss_per_sqft_top(T_w, T_air, RH, wind_mph, covered=False, epsilon=0.9, sigma=1.713e-9):
    if covered:
        k_cover = 0.02  # Btu/hr·ft·°F (polystyrene)
        d_cover = 0.25  # 3 inches
        return k_cover * (T_w - T_air) / d_cover
    # Uncovered: Evap + Conv + Rad
    h_cv = 1 + 0.3 * wind_mph
    # Evap
    p_w = sat_vapor_pressure_psi(T_w)
    p_a = sat_vapor_pressure_psi(T_air)
    dp = p_w - RH * p_a
    K_E = 0.14 * h_cv
    L_v = 1050  # Btu/lb
    Q_e = L_v * K_E * dp
    # Conv
    Q_cv = h_cv * (T_w - T_air)
    # Rad (indoor, to air temp)
    T_w_r = T_w + 460
    T_air_r = T_air + 460
    Q_rad = epsilon * sigma * (T_w_r**4 - T_air_r**4)
    return Q_e + Q_cv + Q_rad

def heat_loss_per_sqft_sides_bottom(T_w, T_air, insulation_thickness_in):
    k_foam = 0.02  # Btu/hr·ft·°F
    insulation_thickness_in = max(insulation_thickness_in, 0.1875)  # Minimum 0.1875 inches
    insulation_thickness_ft = insulation_thickness_in / 12  # Convert to feet
    return k_foam * (T_w - T_air) / insulation_thickness_ft

# Constants
density_lb_gal = 8.345
cp_btu_lb_f = 1.0
RH = 0.5
btu_per_hr_per_w = 3.412142
gal_to_ft3 = 0.133681

def calculate_heating_time(P_watts, length_ft, width_ft, depth_ft, insulation_thickness_in, covered=False):
    if insulation_thickness_in < 0.1875:
        print(f"Warning: Insulation thickness {insulation_thickness_in:.4f} in is below minimum 0.1875 in; using 0.1875 in.")
    P_btu_hr = P_watts * btu_per_hr_per_w
    A_top_ft2 = length_ft * width_ft
    A_sides_bottom_ft2 = 2 * length_ft * depth_ft + 2 * width_ft * depth_ft + length_ft * width_ft
    volume_ft3 = length_ft * width_ft * depth_ft
    gallons = volume_ft3 / gal_to_ft3
    mass_lb = gallons * density_lb_gal
    C_btu_f = mass_lb * cp_btu_lb_f
    
    def dT_dt(t, T):
        T = T[0]
        Q_loss_top = heat_loss_per_sqft_top(T, T_air, RH, wind_mph, covered)
        Q_loss_sb = heat_loss_per_sqft_sides_bottom(T, T_air, insulation_thickness_in)
        Q_loss_total = Q_loss_top * A_top_ft2 + Q_loss_sb * A_sides_bottom_ft2
        return [(P_btu_hr - Q_loss_total) / C_btu_f]
    
    def event_reach_final(t, T):
        return T[0] - T_final
    event_reach_final.terminal = True
    event_reach_final.direction = 1
    
    sol = solve_ivp(dT_dt, [0, 100], [T_initial], events=event_reach_final, rtol=1e-5, atol=1e-5)
    if sol.success:
        return sol.t[-1]
    return None

# Run calculations with default dimensions and insulation thickness
for P_watts in [5500, 11000]:
    for covered in [False, True]:
        time_hours = calculate_heating_time(P_watts, length_ft, width_ft, depth_ft, insulation_thickness_in, covered)
        if time_hours:
            status = "Covered" if covered else "Uncovered"
            print(f"Air/Initial Temp: {T_initial}F, Desired Temp: {T_final}F, Heater: {P_watts} W, {status}, Insulation: {max(insulation_thickness_in, 0.1875):.2f} in, Gallons: {length_ft * width_ft * depth_ft / gal_to_ft3:.1f}, Time to heat: {time_hours:.2f} hours")
        else:
            print(f"Air/Initial Temp: {T_initial}F, Desired Temp: {T_final}F, Heater: {P_watts} W, {status}, Insulation: {max(insulation_thickness_in, 0.1875):.2f} in, Gallons: {length_ft * width_ft * depth_ft / gal_to_ft3:.1f}, Failed to reach 98°F.")