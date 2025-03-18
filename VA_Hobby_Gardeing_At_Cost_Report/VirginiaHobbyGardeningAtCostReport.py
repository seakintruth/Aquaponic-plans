import json
import os
from datetime import datetime, timedelta
import requests  # Required for FRED API calls
import configparser

# Constants
DEFAULT_YIELD_PER_PLANT = 0.5  # Default yield in pounds per plant
SERIES_ID = "FPCPITOTLZGUSA"  # Inflation rate series ID for FRED

# Initilize config data
def get_api_key():
    config = configparser.ConfigParser()
    script_dir = os.path.dirname(os.path.abspath(__file__))
    config.read(os.path.join(script_dir, 'config.ini'))
    if 'Config' in config and 'FRED_API_KEY' in config['Config']:
        return config['Config']['FRED_API_KEY']
    else:
        print("Config file not found or missing FRED_API_KEY. Please enter your API key:")
        return input().strip()

FRED_API_KEY = get_api_key()

# Helper Functions
def get_date_input(prompt, default=None):
    """Prompt for a date with error handling."""
    while True:
        date_str = input(f"{prompt} (YYYY-MM-DD): ") or default
        try:
            return datetime.strptime(date_str, "%Y-%m-%d")
        except ValueError:
            print("Invalid date format. Please use YYYY-MM-DD.")

def get_float_input(prompt, default=None):
    """Prompt for a float value with error handling."""
    while True:
        value_str = input(f"{prompt}: ") or default
        try:
            value = float(value_str)
            if value < 0:
                raise ValueError
            return value
        except ValueError:
            print("Please enter a positive number.")

def get_int_input(prompt, default=None):
    """Prompt for an integer value with error handling."""
    while True:
        value_str = input(f"{prompt}: ") or default
        try:
            value = int(value_str)
            if value <= 0:
                raise ValueError
            return value
        except ValueError:
            print("Please enter a positive integer.")

def calculate_straight_line_depreciation(amount, amortization_years, start_date, report_date):
    """Calculate straight-line depreciation for the report year."""
    start_year = start_date.year
    end_date = start_date.replace(year=start_year + amortization_years)
    if report_date < start_date or report_date >= end_date:
        return 0.0
    annual_depreciation = amount / amortization_years
    return annual_depreciation

def fetch_inflation_data(api_key, series_id, start_date="1960-01-01"):
    """Fetch historical inflation data from FRED API."""
    url = f"https://api.stlouisfed.org/fred/series/observations?series_id={series_id}&api_key={api_key}&file_type=json&observation_start={start_date}"
    try:
        response = requests.get(url)
        response.raise_for_status()  # Raises an exception for HTTP errors
        data = response.json()
        observations = data['observations']
        # Extract year and inflation rate, skipping missing values ('.')
        inflation_data = [(obs['date'][:4], float(obs['value'])) for obs in observations if obs['value'] != '.']
        return inflation_data
    except requests.exceptions.RequestException as e:
        print(f"Error fetching inflation data: {e}")
        return []
    except (KeyError, ValueError) as e:
        print(f"Error parsing inflation data: {e}")
        return []

def get_user_inputs():
    """Collect user inputs for the report."""
    previous_data = {}
    if os.path.exists("aquaponics_report_data.json"):
        try:
            with open("aquaponics_report_data.json", "r") as f:
                previous_data = json.load(f)
        except json.JSONDecodeError:
            print("Corrupted JSON file. Starting fresh.")
    
    investments = previous_data.get("investments", [])
    last_report_date = previous_data.get("last_report_date", "2024-12-31")
    last_variable_costs = previous_data.get("last_variable_costs", {"electricity": 0.0, "water": 0.0, "nutrients": 0.0})
    last_num_plants = previous_data.get("last_num_plants", 300)
    last_yield_per_plant = previous_data.get("last_yield_per_plant", DEFAULT_YIELD_PER_PLANT)
    
    print("Enter the report date range:")
    start_date = get_date_input("Start date", last_report_date)
    end_date = get_date_input("End date", start_date.strftime("%Y-%m-%d"))
    if end_date < start_date:
        print("End date must be after start date.")
        return get_user_inputs()
    
    num_new_investments = get_int_input("Number of new investments (default 0)", "0")
    for _ in range(num_new_investments):
        amount = get_float_input("Investment amount")
        start_date = get_date_input("Investment start date")
        amortization_years = get_int_input("Amortization years")
        investments.append({
            "amount": amount,
            "start_date": start_date.strftime("%Y-%m-%d"),
            "amortization_years": amortization_years,
            "method": "straight-line"  # Assuming straight-line for simplicity
        })
    
    print("Enter variable costs (default from previous report):")
    variable_costs = {}
    for category in ["electricity", "water", "nutrients"]:
        default = last_variable_costs.get(category, 0.0)
        cost = get_float_input(f"{category.capitalize()} cost (default ${default:.2f})", str(default))
        variable_costs[category] = cost
    
    num_plants = get_int_input(f"Number of plants (default {last_num_plants})", str(last_num_plants))
    yield_per_plant = get_float_input(f"Yield per plant in pounds (default {last_yield_per_plant})", str(last_yield_per_plant))
    
    return investments, start_date, end_date, variable_costs, num_plants, yield_per_plant

def calculate_amortized_fixed_costs(investments, report_date):
    """Calculate total amortized fixed costs for the report year."""
    total_amortized = 0.0
    for inv in investments:
        start_date = datetime.strptime(inv["start_date"], "%Y-%m-%d")
        depreciation = calculate_straight_line_depreciation(inv["amount"], inv["amortization_years"], start_date, report_date)
        total_amortized += depreciation
    return total_amortized

def calculate_total_annual_costs(amortized_fixed, variable_costs):
    """Calculate total annual costs."""
    return amortized_fixed + sum(variable_costs.values())

def calculate_cost_per_plant(total_annual_costs, num_plants):
    """Calculate cost per plant."""
    return total_annual_costs / num_plants if num_plants > 0 else 0

def calculate_cost_per_pound(total_annual_costs, num_plants, yield_per_plant):
    """Calculate cost per pound."""
    total_pounds = num_plants * yield_per_plant
    return total_annual_costs / total_pounds if total_pounds > 0 else 0

def generate_html_report(investments, report_date, variable_costs, num_plants, yield_per_plant, amortized_fixed, total_annual_costs, cost_per_plant, cost_per_pound, average_inflation_rate, latest_year):
    """Generate an HTML report with cost projections using historical inflation data."""
    html_content = f"""
    <!DOCTYPE html>
    <html>
    <head>
        <title>Aquaponics Cost Report {report_date.strftime('%Y-%m-%d')}</title>
        <style>
            table {{ border-collapse: collapse; width: 100%; }}
            th, td {{ border: 1px solid black; padding: 8px; text-align: left; }}
            th {{ background-color: #f2f2f2; }}
        </style>
    </head>
    <body>
        <h1>Aquaponics Cost Report - {report_date.strftime('%Y-%m-%d')}</h1>
        <h2>Annual Costs</h2>
        <p><strong>Total Amortized Fixed Costs:</strong> ${amortized_fixed:,.2f}</p>
        <p><strong>Total Variable Costs:</strong> ${sum(variable_costs.values()):,.2f}</p>
        <p><strong>Total Annual Costs:</strong> ${total_annual_costs:,.2f}</p>
        <p><strong>Cost per Plant:</strong> ${cost_per_plant:,.2f} ({num_plants} plants)</p>
        <p><strong>Cost per Pound:</strong> ${cost_per_pound:,.2f} ({yield_per_plant} lbs/plant)</p>
    """
    
    # 20-Year Cost Projection
    if latest_year is not None:
        inflation_note = f"Projections use an average historical inflation rate of {average_inflation_rate*100:.2f}% based on data from 1960 to {latest_year}."
    else:
        inflation_note = "Projections use a default inflation rate of 3%."
    
    html_content += f"""
        <h2>20-Year Cost Projection</h2>
        <p>{inflation_note}</p>
        <table>
            <tr><th>Year</th><th>Projected Variable Costs</th><th>Fixed Costs</th><th>Total Annual Costs</th></tr>
    """
    for i in range(1, 21):
        future_date = report_date + timedelta(days=365.25 * i)
        amortized_fixed_future = calculate_amortized_fixed_costs(investments, future_date)
        projected_variable_costs = sum(variable_costs.values()) * (1 + average_inflation_rate)**i
        total_annual_costs_future = amortized_fixed_future + projected_variable_costs
        html_content += f"""
            <tr>
                <td>{future_date.year}</td>
                <td>${projected_variable_costs:,.2f}</td>
                <td>${amortized_fixed_future:,.2f}</td>
                <td>${total_annual_costs_future:,.2f}</td>
            </tr>
        """
    
    html_content += """
        </table>
    </body>
    </html>
    """
        
    script_dir = os.path.dirname(os.path.abspath(__file__))
    filename = f"virginia_hobby_gardening_report_{report_date.strftime('%Y%m%d')}.html"
    report_path = os.path.join(script_dir, filename)
    with open(report_path, "w") as f:
        f.write(html_content)
        
    print(f"Report generated: {filename}")

def main():
    """Main function to run the script."""
    investments, start_date, end_date, variable_costs, num_plants, yield_per_plant = get_user_inputs()
    
    # Fetch inflation data once
    inflation_data = fetch_inflation_data(FRED_API_KEY, SERIES_ID)
    if inflation_data:
        inflation_rates = [rate for year, rate in inflation_data]
        # Convert percentage to decimal for calculations
        average_inflation_rate = sum(inflation_rates) / len(inflation_rates) / 100
        latest_year = max([int(year) for year, rate in inflation_data])
    else:
        print("Failed to fetch inflation data. Using default 3% inflation rate.")
        average_inflation_rate = 0.03
        latest_year = None
    
    # Generate reports for each year in the date range
    current_date = start_date
    while current_date <= end_date:
        amortized_fixed = calculate_amortized_fixed_costs(investments, current_date)
        total_annual_costs = calculate_total_annual_costs(amortized_fixed, variable_costs)
        cost_per_plant = calculate_cost_per_plant(total_annual_costs, num_plants)
        cost_per_pound = calculate_cost_per_pound(total_annual_costs, num_plants, yield_per_plant)
        generate_html_report(
            investments, current_date, variable_costs, num_plants, yield_per_plant,
            amortized_fixed, total_annual_costs, cost_per_plant, cost_per_pound,
            average_inflation_rate, latest_year
        )
        current_date += timedelta(days=365.25)
    
    # Save user inputs for future runs
    report_data = {
        "investments": investments,
        "last_variable_costs": variable_costs,
        "last_num_plants": num_plants,
        "last_yield_per_plant": yield_per_plant,
        "last_report_date": end_date.strftime("%Y-%m-%d")
    }
    with open("aquaponics_report_data.json", "w") as f:
        json.dump(report_data, f)

if __name__ == "__main__":
    main()