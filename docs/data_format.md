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
| Column                 | Type    | Description                                 | Required |
| ---------------------- | ------- | ------------------------------------------- | -------- |
| ID                     | String  | Unique identifier for the intake            | Yes      |
| Date                   | Date    | Date of the meal (YYYY-MM-DD)               | Yes      |
| Meal Type              | String  | Type of meal (breakfast/lunch/dinner/snack) | Yes      |
| Food Name              | String  | Name of the food item                       | Yes      |
| Brands                 | String  | Brand names (if any)                        | No       |
| Amount                 | Number  | Quantity consumed                           | Yes      |
| Unit                   | String  | Unit of measurement                         | Yes      |
| Energy per 100g        | Number  | Energy in kcal/100g                         | Yes      |
| Carbs per 100g         | Number  | Carbohydrates in g/100g                     | Yes      |
| Fats per 100g          | Number  | Fats in g/100g                              | Yes      |
| Proteins per 100g      | Number  | Proteins in g/100g                          | Yes      |
| Sugars per 100g        | Number  | Sugars in g/100g                            | No       |
| Saturated Fat per 100g | Number  | Saturated fats in g/100g                    | No       |
| Fiber per 100g         | Number  | Fiber in g/100g                             | No       |
| Total Calories         | Number  | Total calories for portion                  | Yes      |
| Total Carbs            | Number  | Total carbohydrates for portion             | Yes      |
| Total Fats             | Number  | Total fats for portion                      | Yes      |
| Total Proteins         | Number  | Total proteins for portion                  | Yes      |
| Barcode                | String  | Product barcode                             | No       |
| Product URL            | String  | URL to product details                      | No       |
| Thumbnail Image URL    | String  | URL to product thumbnail                    | No       |
| Main Image URL         | String  | URL to main product image                   | No       |
| Serving Quantity       | Number  | Standard serving quantity                   | No       |
| Serving Unit           | String  | Unit for serving size                       | No       |
| Serving Size           | String  | Human-readable serving size                 | No       |
| Source                 | String  | Data source (OFF/FDC/CUSTOM)                | Yes      |
| Is Liquid              | Boolean | Whether the food is liquid (true/false)     | No       |

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

## Notes
- Empty optional fields should be left blank (consecutive commas)
- Text fields containing commas must be enclosed in double quotes
- URLs should be properly encoded
- IDs must be unique within the file
