"""
Environmental Metrics and Thermal Comfort Calculations
"""

def compute_heat_index(temp_c: float, humidity: float) -> float:
    """
    Calculate approximate Heat Index in Celsius based on Steadman and Rothfusz regression.
    """
    tf = (temp_c * 9.0 / 5.0) + 32.0
    rh = humidity

    # Steadman simple formula
    hi_f = 0.5 * (tf + 61.0 + ((tf - 68.0) * 1.2) + (rh * 0.094))

    if hi_f >= 80.0:
        # Full Rothfusz regression
        hi_f = (
            -42.379
            + 2.04901523 * tf
            + 10.14333127 * rh
            - 0.22475541 * tf * rh
            - 0.00683783 * (tf ** 2)
            - 0.05481717 * (rh ** 2)
            + 0.00122874 * (tf ** 2) * rh
            + 0.00085282 * tf * (rh ** 2)
            - 0.00000199 * (tf ** 2) * (rh ** 2)
        )

    hi_c = (hi_f - 32.0) * 5.0 / 9.0
    return round(hi_c, 1)


def evaluate_comfort(temp: float, hum: float, temp_diff: float) -> tuple[str, str]:
    """Return comfort assessment and status summary."""
    if 21.0 <= temp <= 26.0 and 40.0 <= hum <= 60.0:
        comfort = "Ideal Comfort Zone (ASHRAE Standard 55)"
    elif temp > 28.0:
        comfort = "Warm / Elevated Thermal Load"
    elif temp < 19.0:
        comfort = "Cool / Below Neutral Zone"
    elif hum > 65.0:
        comfort = "Humid / Potential Stuffiness"
    elif hum < 35.0:
        comfort = "Dry Air / Respiratory Caution"
    else:
        comfort = "Acceptable Indoor Conditions"

    if temp_diff < -2.0:
        summary = f"Indoor environment is {abs(temp_diff):.1f}°C cooler than outside."
    elif temp_diff > 2.0:
        summary = f"Indoor environment is {temp_diff:.1f}°C warmer than outside."
    else:
        summary = "Indoor and outdoor temperatures are closely balanced."

    return comfort, summary
