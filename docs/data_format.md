# OpenNutriTracker Data Format Specification

## Overview
OpenNutriTracker uses CSV (Comma-Separated Values) format for data import and export. The file format is designed to store detailed nutritional information for each meal entry.

## File Format
- Encoding: UTF-8
- Delimiter: Comma (,)
- Line endings: \n
- First row: Header row (required)
- Date format: YYYY-MM-DD
- Decimal separator: Period (.)
- Text fields containing commas must be escaped

## Column Structure
The order of columns is fixed and must match the following structure:

| Column                | Type    | Description                                         | Required | Notes                                      |
| --------------------- | ------- | --------------------------------------------------- | -------- | ------------------------------------------ |
| ID                    | String  | Unique identifier for the intake                    | Yes      |                                            |
| Date                  | Date    | Date of the meal (YYYY-MM-DD)                       | Yes      |                                            |
| Meal Type             | String  | Type of meal (breakfast/lunch/dinner/snack)         | Yes      |                                            |
| Food Name             | String  | Name of the food item                               | Yes      |                                            |
| Brands                | String  | Brand names (if any)                                | No       |                                            |
| Amount                | Number  | Quantity consumed                                   | Yes      |                                            |
| Unit                  | String  | Unit of measurement                                 | Yes      |                                            |
| Energy per 100        | Number  | Energy in kcal per 100g (solids) or 100ml (liquids) | Yes      |                                            |
| Carbs per 100         | Number  | Carbohydrates in g per 100g/ml                      | Yes      |                                            |
| Fats per 100          | Number  | Fats in g per 100g/ml                               | Yes      |                                            |
| Proteins per 100      | Number  | Proteins in g per 100g/ml                           | Yes      |                                            |
| Sugars per 100        | Number  | Sugars in g per 100g/ml                             | No       |                                            |
| Saturated Fat per 100 | Number  | Saturated fats in g per 100g/ml                     | No       |                                            |
| Fiber per 100         | Number  | Fiber in g per 100g/ml                              | No       |                                            |
| Total Calories        | Number  | Total calories for portion                          | No       | Derived from Energy per 100 * Amount/100   |
| Total Carbs           | Number  | Total carbohydrates for portion                     | No       | Derived from Carbs per 100 * Amount/100    |
| Total Fats            | Number  | Total fats for portion                              | No       | Derived from Fats per 100 * Amount/100     |
| Total Proteins        | Number  | Total proteins for portion                          | No       | Derived from Proteins per 100 * Amount/100 |
| Barcode               | String  | Product barcode                                     | No       |                                            |
| Product URL           | String  | URL to product details                              | No       |                                            |
| Thumbnail Image URL   | String  | URL to product thumbnail                            | No       |                                            |
| Main Image URL        | String  | URL to main product image                           | No       |                                            |
| Serving Quantity      | Number  | Standard serving quantity                           | No       |                                            |
| Serving Unit          | String  | Unit for serving size                               | No       |                                            |
| Serving Size          | String  | Human-readable serving size                         | No       |                                            |
| Source                | String  | Data source (OFF/FDC/CUSTOM)                        | Yes      |                                            |
| Is Liquid             | Boolean | Whether the food is liquid (true/false)             | No       | Derived from Unit                          |

## Example Row
```csv
12345,2024-02-20,BREAKFAST,Whole Milk,Brand X,240,ml,42,3.4,1.0,3.3,0,0.6,0,101,8.2,2.4,7.9,5449000000996,https://example.com,https://example.com/thumb.jpg,https://example.com/main.jpg,240,ml,"240 ml (1 cup)",OFF,true
```

## Import Requirements
- File must be in CSV format
- Must include header row matching export format
- All required fields must be present
- Date format must be YYYY-MM-DD
- Numeric values must use period (.) as decimal separator
- Source must be one of: OFF, FDC, or CUSTOM
- Boolean values must be "true" or "false"
- Nutritional values are provided per 100g for solid foods and per 100ml for liquid foods

## Notes
- Total values (calories, carbs, fats, proteins) are optional as they can be calculated from per 100g/ml values
- Is Liquid field is optional as it can be determined from the Unit field
- Empty optional fields should be left blank (consecutive commas)
- Text fields containing commas must be enclosed in double quotes
- URLs should be properly encoded
- IDs must be unique within the file
