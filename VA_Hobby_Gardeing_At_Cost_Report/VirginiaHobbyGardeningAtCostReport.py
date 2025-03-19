import json
import os
from datetime import datetime, timedelta
import requests
import configparser

# Constants
DEFAULT_YIELD_PER_PLANT = 0.5  # Default yield per plant in pounds
SERIES_ID = "FPCPITOTLZGUSA"   # FRED API series ID for inflation data

# Initialize configuration
config = configparser.ConfigParser()
script_dir = os.path.dirname(os.path.abspath(__file__))
config.read(os.path.join(script_dir, 'config.ini'))

# Retrieve or prompt for FRED API key
def get_api_key():
    if 'Config' in config and 'FRED_API_KEY' in config['Config']:
        return config['Config']['FRED_API_KEY']
    else:
        print("Config file not found or missing FRED_API_KEY. Please enter your API key:")
        return input().strip()

FRED_API_KEY = get_api_key()

### Helper Functions ###
def get_date_input(prompt, default=None):
    """Prompt user for a date in YYYY-MM-DD format."""
    while True:
        date_str = input(f"{prompt} (YYYY-MM-DD): ") or default
        try:
            return datetime.strptime(date_str, "%Y-%m-%d")
        except ValueError:
            print("Invalid date format. Please use YYYY-MM-DD.")

def get_float_input(prompt, default=None):
    """Prompt user for a non-negative float value."""
    while True:
        value_str = input(f"{prompt}: ") or default
        try:
            value = float(value_str)
            if value < 0:
                raise ValueError
            return value
        except ValueError:
            print("Please enter a non-negative number.")

def get_int_input(prompt, default=None):
    """Prompt user for a non-negative integer."""
    while True:
        value_str = input(f"{prompt}: ") or default
        try:
            value = int(value_str)
            if value < 0:
                raise ValueError
            return value
        except ValueError:
            print("Please enter a non-negative integer.")

### Depreciation Calculation Functions ###
def calculate_straight_line_depreciation(amount, amortization_years, start_date, report_date):
    """Calculate annual depreciation using straight-line method."""
    start_year = start_date.year
    end_date = start_date.replace(year=start_year + amortization_years)
    if report_date < start_date or report_date >= end_date:
        return 0.0
    return amount / amortization_years

def calculate_double_declining_balance(amount, amortization_years, start_date, report_date):
    """Calculate annual depreciation using double-declining balance method."""
    start_year = start_date.year
    end_date = start_date.replace(year=start_year + amortization_years)
    if report_date < start_date or report_date >= end_date:
        return 0.0
    years_elapsed = (report_date - start_date).days / 365.25
    rate = 2 / amortization_years
    if years_elapsed < 1:
        return amount * rate
    elif years_elapsed < amortization_years:
        remaining = amount
        for year in range(int(years_elapsed) + 1):
            annual_dep = remaining * rate
            remaining -= annual_dep
            if year == int(years_elapsed):
                return annual_dep if remaining > 0 else remaining + annual_dep
    return 0.0

### Data Fetching and Processing Functions ###
def fetch_inflation_data(api_key, series_id, start_date="1960-01-01"):
    """Fetch inflation data from FRED API."""
    url = f"https://api.stlouisfed.org/fred/series/observations?series_id={series_id}&api_key={api_key}&file_type=json&observation_start={start_date}"
    try:
        response = requests.get(url)
        response.raise_for_status()
        data = response.json()
        observations = data['observations']
        inflation_data = [(obs['date'][:4], float(obs['value'])) for obs in observations if obs['value'] != '.']
        return inflation_data
    except (requests.RequestException, KeyError, ValueError) as e:
        print(f"Error fetching inflation data: {e}")
        return []

def calculate_average_variable_costs(historical_data, current_year):
    """Calculate average variable costs from the past 5 years."""
    past_years = [data for data in historical_data if int(data['year']) < current_year]
    past_years = sorted(past_years, key=lambda x: x['year'], reverse=True)[:5]
    if not past_years:
        return None
    avg_costs = {}
    for category in past_years[0]['costs']:
        total = sum(year['costs'].get(category, 0) for year in past_years)
        avg_costs[category] = total / len(past_years)
    return avg_costs

def get_user_inputs():
    """Collect user inputs and load historical data."""
    json_path = os.path.join(script_dir, "virginia_hobby_gardening_report_data.json")
    previous_data = {}
    if os.path.exists(json_path):
        try:
            with open(json_path, "r") as f:
                previous_data = json.load(f)
        except json.JSONDecodeError:
            print("Corrupted JSON file. Starting fresh.")
    
    historical_variable_costs = previous_data.get("historical_variable_costs", [])
    investments = previous_data.get("investments", [])
    last_report_date = previous_data.get("last_report_date", "2024-12-31")
    last_num_plants = previous_data.get("last_num_plants", 300)
    last_yield_per_plant = previous_data.get("last_yield_per_plant", DEFAULT_YIELD_PER_PLANT)
    
    # Get date range
    start_date = get_date_input("Start date", last_report_date)
    end_date = get_date_input("End date", start_date.strftime("%Y-%m-%d"))
    if end_date < start_date:
        print("End date must be after start date.")
        return get_user_inputs()
    
    # Collect new investments
    num_new_investments = get_int_input("Number of new investments (default 0)", "0")
    for _ in range(num_new_investments):
        amount = get_float_input("Investment amount")
        inv_start_date = get_date_input("Investment start date")
        amortization_years = get_int_input("Amortization years")
        method = input("Depreciation method (s for straight-line, d for double-declining): ").lower()
        while method not in ['s', 'd', 'straight-line', 'double-declining']:
            method = input("Please choose 's' for straight-line or 'd' for double-declining: ").lower()
        method = 'straight-line' if method in ['s', 'straight-line'] else 'double-declining'
        investments.append({
            "amount": amount,
            "start_date": inv_start_date.strftime("%Y-%m-%d"),
            "amortization_years": amortization_years,
            "method": method
        })
    
    # Define variable cost categories
    if 'Config' in config and 'variable_cost_categories' in config['Config']:
        categories = [cat.strip() for cat in config['Config']['variable_cost_categories'].split(',')]
    else:
        categories = ["electricity", "water", "nutrients"]
    
    # Collect current year's variable costs
    print("Enter variable costs for the current year:")
    variable_costs = {}
    for category in categories:
        cost = get_float_input(f"{category.capitalize()} cost")
        variable_costs[category] = cost
    
    # Get plant and yield data
    num_plants = get_int_input(f"Number of plants (default {last_num_plants})", str(last_num_plants))
    yield_per_plant = get_float_input(f"Yield per plant in pounds (default {last_yield_per_plant})", str(last_yield_per_plant))
    
    return investments, start_date, end_date, variable_costs, num_plants, yield_per_plant, historical_variable_costs

### Cost Calculation Functions ###
def calculate_amortized_fixed_costs(investments, report_date):
    """Calculate total amortized fixed costs for a given report date."""
    total_amortized = 0.0
    for inv in investments:
        start_date = datetime.strptime(inv["start_date"], "%Y-%m-%d")
        if inv["method"] == "straight-line":
            depreciation = calculate_straight_line_depreciation(inv["amount"], inv["amortization_years"], start_date, report_date)
        else:
            depreciation = calculate_double_declining_balance(inv["amount"], inv["amortization_years"], start_date, report_date)
        total_amortized += depreciation
    return total_amortized

def calculate_total_annual_costs(amortized_fixed, variable_costs):
    """Calculate total annual costs combining fixed and variable costs."""
    return amortized_fixed + sum(variable_costs.values())

def calculate_cost_per_plant(total_annual_costs, num_plants):
    """Calculate cost per plant."""
    return total_annual_costs / num_plants if num_plants > 0 else 0

def calculate_cost_per_pound(total_annual_costs, num_plants, yield_per_plant):
    """Calculate cost per pound of yield."""
    total_pounds = num_plants * yield_per_plant
    return total_annual_costs / total_pounds if total_pounds > 0 else 0

### Report Generation ###
def generate_html_report(investments, report_date, variable_costs, num_plants, yield_per_plant, 
                        amortized_fixed, total_annual_costs, cost_per_plant, cost_per_pound, 
                        average_inflation_rate, latest_year, avg_variable_costs):
    """Generate an HTML report with current costs and 20-year projection."""
    html_content = f"""
    <!DOCTYPE html>
    <html>
    <head>
        <title>Aquaponics Cost Report {report_date.strftime('%Y-%m-%d')}</title>
        <style>
            table {{ border-collapse: collapse; width: 100%; margin-bottom: 20px; }}
            th, td {{ border: 1px solid black; padding: 8px; text-align: left; }}
            th {{ background-color: #f2f2f2; }}
            h2 {{ margin-top: 20px; }}
        </style>
    </head>
    <body>
        <h1>Aquaponics Cost Report - {report_date.strftime('%Y-%m-%d')}</h1>
        
        <h2>Fixed Costs</h2>
        <table>
            <tr><th>Start Date</th><th>Amount</th><th>Years</th><th>Method</th><th>Annual Depreciation</th></tr>
    """
    for inv in investments:
        start_date = datetime.strptime(inv["start_date"], "%Y-%m-%d")
        depreciation = (calculate_straight_line_depreciation if inv["method"] == "straight-line" 
                       else calculate_double_declining_balance)(inv["amount"], inv["amortization_years"], 
                                                                start_date, report_date)
        html_content += f"""
            <tr>
                <td>{inv['start_date']}</td>
                <td>${inv['amount']:,.2f}</td>
                <td>{inv['amortization_years']}</td>
                <td>{inv['method'].capitalize()}</td>
                <td>${depreciation:,.2f}</td>
            </tr>
        """
    html_content += f"""
        </table>
        <p><strong>Total Amortized Fixed Costs:</strong> ${amortized_fixed:,.2f}</p>
        
        <h2>Variable Costs (Current Year)</h2>
        <table>
            <tr><th>Category</th><th>Cost</th></tr>
    """
    for category, cost in variable_costs.items():
        html_content += f"""
            <tr>
                <td>{category.capitalize()}</td>
                <td>${cost:,.2f}</td>
            </tr>
        """
    html_content += f"""
        </table>
        <p><strong>Total Variable Costs (Current Year):</strong> ${sum(variable_costs.values()):,.2f}</p>
        
        <h2>Summary</h2>
        <p><strong>Total Annual Costs (Current Year):</strong> ${total_annual_costs:,.2f}</p>
        <p><strong>Cost per Plant:</strong> ${cost_per_plant:,.2f} ({num_plants} plants)</p>
        <p><strong>Cost per Pound:</strong> ${cost_per_pound:,.2f} ({yield_per_plant} lbs/plant)</p>
    """
    
    # 20-Year Projection
    inflation_note = (f"Projections use an average inflation rate of {average_inflation_rate*100:.2f}% "
                     f"based on data from 1960 to {latest_year}.") if latest_year else \
                     "Projections use a default inflation rate of 3%."
    html_content += f"""
        <h2>20-Year Cost Projection (Based on Average of Past 5 Years' Variable Costs)</h2>
        <p>{inflation_note}</p>
        <table>
            <tr><th>Year</th><th>Fixed Costs</th>
    """
    categories = list(avg_variable_costs.keys())
    for cat in categories:
        html_content += f"<th>{cat.capitalize()}</th>"
    html_content += "<th>Total Variable Costs</th><th>Total Annual Costs</th></tr>"
    
    for i in range(1, 21):
        future_date = report_date + timedelta(days=365.25 * i)
        amortized_fixed_future = calculate_amortized_fixed_costs(investments, future_date)
        projected_vars = {cat: avg_variable_costs[cat] * (1 + average_inflation_rate)**i for cat in categories}
        total_vars_future = sum(projected_vars.values())
        total_annual_future = amortized_fixed_future + total_vars_future
        html_content += f"""
            <tr>
                <td>{future_date.year}</td>
                <td>${amortized_fixed_future:,.2f}</td>
        """
        for cat in categories:
            html_content += f"<td>${projected_vars[cat]:,.2f}</td>"
        html_content += f"""
                <td>${total_vars_future:,.2f}</td>
                <td>${total_annual_future:,.2f}</td>
            </tr>
        """
    
    html_content += """
        </table>
    </body>
    </html>
    """
    
    # Save the report
    filename = f"virginia_hobby_gardening_report_{report_date.strftime('%Y%m%d')}.html"
    report_path = os.path.join(script_dir, filename)
    with open(report_path, "w") as f:
        f.write(html_content)
    print(f"Report generated: {filename}")

### Main Function ###
def main():
    """Orchestrate the aquaponics cost reporting process."""
    # Collect user inputs
    investments, start_date, end_date, variable_costs, num_plants, yield_per_plant, historical_variable_costs = get_user_inputs()
    
    # Append current year's variable costs to historical data
    current_year = start_date.year
    historical_variable_costs.append({"year": current_year, "costs": variable_costs})
    
    # Calculate average variable costs for projections
    avg_variable_costs = calculate_average_variable_costs(historical_variable_costs, current_year)
    if avg_variable_costs is None:
        print("No historical data available. Using current year's variable costs for projections.")
        avg_variable_costs = variable_costs.copy()
    
    # Fetch inflation data
    inflation_data = fetch_inflation_data(FRED_API_KEY, SERIES_ID)
    if inflation_data:
        inflation_rates = [rate for _, rate in inflation_data]
        average_inflation_rate = sum(inflation_rates) / len(inflation_rates) / 100  # Convert percentage to decimal
        latest_year = max([int(year) for year, _ in inflation_data])
    else:
        print("Failed to fetch inflation data. Using default 3.77% inflation rate.")
        average_inflation_rate = 0.0377
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
            average_inflation_rate, latest_year, avg_variable_costs
        )
        current_date += timedelta(days=365.25)
    
    # Save updated data to JSON
    report_data = {
        "historical_variable_costs": historical_variable_costs,
        "investments": investments,
        "last_num_plants": num_plants,
        "last_yield_per_plant": yield_per_plant,
        "last_report_date": end_date.strftime("%Y-%m-%d")
    }
    with open(os.path.join(script_dir, "virginia_hobby_gardening_report_data.json"), "w") as f:
        json.dump(report_data, f, indent=4)

if __name__ == "__main__":
    main()
