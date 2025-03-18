import json
import os
from datetime import datetime, timedelta

# Constants
DEFAULT_YIELD_PER_PLANT = 0.5  # Default yield in pounds per plant

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
    """Calculate straight-line depreciation for the report year with prorating."""
    start_year = start_date.year
    end_date = start_date.replace(year=start_year + amortization_years)
    if report_date < start_date or report_date >= end_date:
        return 0.0
    annual_depreciation = amount / amortization_years
    if report_date.year == start_year:
        days_in_year = (datetime(start_year + 1, 1, 1) - datetime(start_year, 1, 1)).days
        days_active = (datetime(start_year + 1, 1, 1) - start_date).days
        return annual_depreciation * (days_active / days_in_year)
    elif report_date.year == end_date.year - 1:
        days_in_year = (end_date - datetime(end_date.year, 1, 1)).days
        return annual_depreciation * (days_in_year / 365)
    return annual_depreciation

def calculate_double_declining_balance(amount, amortization_years, start_date, report_date):
    """Calculate double-declining balance depreciation for the report year."""
    rate = 2 / amortization_years
    book_value = amount
    current_date = start_date
    while current_date < report_date:
        depreciation = book_value * rate
        book_value -= depreciation
        current_date += timedelta(days=365)
        if current_date >= report_date:
            days_in_year = 365
            days_active = (report_date - (current_date - timedelta(days=365))).days
            return depreciation * (days_active / days_in_year)
    return 0.0

def get_user_inputs():
    """Collect detailed user inputs for the report."""
    previous_data = {}
    if os.path.exists("virginia_hobby_gardening_report_data.json"):
        try:
            with open("virginia_hobby_gardening_report_data.json", "r") as f:
                previous_data = json.load(f)
        except json.JSONDecodeError:
            print("Corrupted JSON file. Starting fresh.")
    
    investments = previous_data.get("investments", [])
    last_report_date = previous_data.get("last_report_date", "2024-12-31")
    last_variable_costs = previous_data.get("last_variable_costs", {"electricity": 0.0, "water": 0.0, "nutrients": 0.0})
    last_num_plants = previous_data.get("last_num_plants", 300)
    last_yield_per_plant = previous_data.get("last_yield_per_plant", DEFAULT_YIELD_PER_PLANT)
    
    print("Enter the report date range (start and end dates):")
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
        method = input("Depreciation method (straight-line or double-declining): ").lower()
        while method not in ["straight-line", "double-declining"]:
            method = input("Please choose 'straight-line' or 'double-declining': ").lower()
        investments.append({
            "amount": amount,
            "start_date": start_date.strftime("%Y-%m-%d"),
            "amortization_years": amortization_years,
            "method": method
        })
    
    print("Enter variable costs by category (default values from previous report):")
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
        if inv["method"] == "straight-line":
            depreciation = calculate_straight_line_depreciation(inv["amount"], inv["amortization_years"], start_date, report_date)
        elif inv["method"] == "double-declining":
            depreciation = calculate_double_declining_balance(inv["amount"], inv["amortization_years"], start_date, report_date)
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

def generate_html_report(investments, report_date, variable_costs, num_plants, yield_per_plant, amortized_fixed, total_annual_costs, cost_per_plant, cost_per_pound):
    """Generate an HTML report with detailed cost breakdowns, sales combinations, and projections."""
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
        <h2>Hobby Goals and Sales Purpose</h2>
        <p>The primary goal of this aquaponics hobby is to explore and develop sustainable gardening practices. Sales of produce and plants are conducted solely to cover the costs associated with maintaining and expanding the hobby, and not for the purpose of generating profit. This approach ensures compliance with the Virginia exemption for licensing by selling at or below cost, accounting for the significant investments in infrastructure.</p>
        <h2>Fixed Costs</h2>
        <table>
            <tr><th>Start Date</th><th>Amount</th><th>Amortization Years</th><th>Method</th><th>Annual Depreciation</th><th>Cumulative Depreciation</th></tr>
    """
    cumulative_depreciation_total = 0.0
    for inv in investments:
        start_date = datetime.strptime(inv["start_date"], "%Y-%m-%d")
        if inv["method"] == "straight-line":
            annual_depreciation = calculate_straight_line_depreciation(inv["amount"], inv["amortization_years"], start_date, report_date)
            cumulative_depreciation = min((report_date - start_date).days / 365 * (inv["amount"] / inv["amortization_years"]), inv["amount"])
        else:
            annual_depreciation = calculate_double_declining_balance(inv["amount"], inv["amortization_years"], start_date, report_date)
            book_value = inv["amount"]
            current_date = start_date
            while current_date < report_date:
                depreciation = book_value * (2 / inv["amortization_years"])
                book_value -= depreciation
                current_date += timedelta(days=365)
            cumulative_depreciation = inv["amount"] - max(book_value, 0)
        cumulative_depreciation_total += cumulative_depreciation
        html_content += f"""
            <tr>
                <td>{inv['start_date']}</td>
                <td>${inv['amount']:,.2f}</td>
                <td>{inv['amortization_years']}</td>
                <td>{inv['method']}</td>
                <td>${annual_depreciation:,.2f}</td>
                <td>${cumulative_depreciation:,.2f}</td>
            </tr>
        """
    html_content += f"""
        </table>
        <p><strong>Total Annual Fixed Costs:</strong> ${amortized_fixed:,.2f}</p>
        <h2>Variable Costs</h2>
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
        <p><strong>Total Variable Costs:</strong> ${sum(variable_costs.values()):,.2f}</p>
        <h2>Total Costs</h2>
        <p><strong>Total Annual Costs:</strong> ${total_annual_costs:,.2f}</p>
        <p><strong>Number of Plants:</strong> {num_plants}</p>
        <p><strong>Cost per Plant:</strong> ${cost_per_plant:,.2f}</p>
        <p><strong>Cost per Pound:</strong> ${cost_per_pound:,.2f} (assuming {yield_per_plant} lbs/plant)</p>
    """

    # Sales Combinations Table
    html_content += f"""
        <h2>Permissible Sales Combinations</h2>
        <p>The following table shows combinations of plant and produce sales that equal the total annual costs of ${total_annual_costs:,.2f}, ensuring sales remain at cost per the absorption costing methodology.</p>
        <table>
            <tr><th>Plants Sold</th><th>Revenue from Plants</th><th>Pounds Sold</th><th>Revenue from Produce</th><th>Total Revenue</th></tr>
    """
    combinations = [
        (num_plants, 0),  # All plants, no produce
        (int(num_plants * 0.75), int(num_plants * yield_per_plant * 0.25)),
        (int(num_plants * 0.5), int(num_plants * yield_per_plant * 0.5)),
        (int(num_plants * 0.25), int(num_plants * yield_per_plant * 0.75)),
        (0, int(num_plants * yield_per_plant))  # No plants, all produce
    ]
    for plants_sold, pounds_sold in combinations:
        if plants_sold > 0 and pounds_sold > 0:
            revenue_plants = (total_annual_costs * plants_sold) / (plants_sold + (pounds_sold / yield_per_plant))
            revenue_pounds = total_annual_costs - revenue_plants
        elif plants_sold > 0:
            revenue_plants = total_annual_costs
            revenue_pounds = 0
        else:
            revenue_plants = 0
            revenue_pounds = total_annual_costs
        html_content += f"""
            <tr>
                <td>{plants_sold}</td>
                <td>${revenue_plants:,.2f}</td>
                <td>{pounds_sold}</td>
                <td>${revenue_pounds:,.2f}</td>
                <td>${revenue_plants + revenue_pounds:,.2f}</td>
            </tr>
        """
    html_content += "</table>"

    # 20-Year Projection Table
    projection_data = []
    for i in range(1, 21):
        future_date = report_date + timedelta(days=365.25 * i)
        amortized_fixed_future = calculate_amortized_fixed_costs(investments, future_date)
        projected_variable_costs = sum(variable_costs.values()) * (1 + 0.03)**i
        total_annual_costs_future = amortized_fixed_future + projected_variable_costs
        cost_per_plant_future = total_annual_costs_future / num_plants if num_plants > 0 else 0
        total_pounds = num_plants * yield_per_plant
        cost_per_pound_future = total_annual_costs_future / total_pounds if total_pounds > 0 else 0
        projection_data.append({
            "year": future_date.year,
            "projected_variable_costs": projected_variable_costs,
            "amortized_fixed_future": amortized_fixed_future,
            "total_annual_costs_future": total_annual_costs_future,
            "cost_per_plant_future": cost_per_plant_future,
            "cost_per_pound_future": cost_per_pound_future
        })

    projection_rows = ""
    for data in projection_data:
        projection_rows += f"""
        <tr>
            <td>{data['year']}</td>
            <td>${data['projected_variable_costs']:,.2f}</td>
            <td>${data['amortized_fixed_future']:,.2f}</td>
            <td>${data['total_annual_costs_future']:,.2f}</td>
            <td>${data['cost_per_plant_future']:,.2f}</td>
            <td>${data['cost_per_pound_future']:,.2f}</td>
        </tr>
        """

    html_content += f"""
    <h2>20-Year Cost Projection (Assuming 3% Annual Inflation on Variable Costs)</h2>
    <p>This table projects future costs assuming variable costs increase by 3% annually, with fixed costs based on current investments.</p>
    <table>
        <tr><th>Year</th><th>Projected Variable Costs</th><th>Amortized Fixed Costs</th><th>Total Annual Costs</th><th>Cost per Plant</th><th>Cost per Pound</th></tr>
        {projection_rows}
    </table>
    </body>
    </html>
    """

    with open(f"virginia_hobby_gardening_report_{report_date.strftime('%Y%m%d')}.html", "w") as f:
        f.write(html_content)

def main():
    """Main function to run the script."""
    investments, start_date, end_date, variable_costs, num_plants, yield_per_plant = get_user_inputs()
    current_date = start_date
    while current_date <= end_date:
        amortized_fixed = calculate_amortized_fixed_costs(investments, current_date)
        total_annual_costs = calculate_total_annual_costs(amortized_fixed, variable_costs)
        cost_per_plant = calculate_cost_per_plant(total_annual_costs, num_plants)
        cost_per_pound = calculate_cost_per_pound(total_annual_costs, num_plants, yield_per_plant)
        generate_html_report(investments, current_date, variable_costs, num_plants, yield_per_plant, amortized_fixed, total_annual_costs, cost_per_plant, cost_per_pound)
        current_date += timedelta(days=365.25)
    
    report_data = {
        "investments": investments,
        "last_variable_costs": variable_costs,
        "last_num_plants": num_plants,
        "last_yield_per_plant": yield_per_plant,
        "last_report_date": end_date.strftime("%Y-%m-%d")
    }
    with open("virginia_hobby_gardening_report_data.json", "w") as f:
        json.dump(report_data, f)

if __name__ == "__main__":
    main()