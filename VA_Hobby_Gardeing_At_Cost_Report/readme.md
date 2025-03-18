# Aquaponics Cost Report Script

This Python script generates a detailed cost report for an aquaponics hobby using absorption costing. It helps hobbyists track costs accurately and ensures compliance with licensing by selling at or below cost.

## Features and Strengths

- **Absorption Costing**: Allocates both fixed and variable costs to production units, ensuring all expenses are absorbed into the cost per unit.
- **Precise Date Handling**: Amortizes investments based on exact start dates and prorates depreciation for partial years, improving accuracy.
- **Multiple Depreciation Methods**: Supports straight-line and double-declining balance methods, offering flexibility for different asset types.
- **Detailed Variable Costs**: Allows input of variable costs by category (e.g., electricity, water, nutrients) for transparent tracking and analysis.
- **Multi-Year Reporting**: Generates reports for a specified date range in one run, streamlining long-term cost analysis.
- **Robust Error Handling**: Uses try-except blocks to manage file operation errors and invalid dates, enhancing reliability.
- **Configurable Yield**: Lets users set the yield per plant, adapting to various plants and growing conditions.
- **Cumulative Depreciation**: Tracks and reports cumulative depreciation for each investment, aiding in asset management.
- **Data Persistence**: Stores historical data in a JSON file, maintaining continuity across reports.
- **User-Friendly Inputs**: Validates inputs with defaults where appropriate, ensuring ease of use and data integrity.

## Usage

1. Run the script and enter or update investment details (start date, amount, amortization period, depreciation method), variable costs by category, yield per plant, and plant numbers.
2. Specify the report date or date range (start and end dates) to generate the cost report.
3. Review the HTML report for a detailed cost breakdown, including depreciation and cumulative totals.

## Requirements

- Python 3.x
- Standard library only (no external dependencies).

## License

This project is licensed under the MIT License.