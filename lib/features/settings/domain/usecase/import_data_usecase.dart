import 'dart:io';
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/data/data_source/intake_data_source.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/domain/usecase/add_intake_usecase.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/core/domain/usecase/add_tracked_day_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_kcal_goal_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_macro_goal_usecase.dart';

class ImportDataUsecase {
  final _log = Logger('ImportDataUsecase');
  final AddIntakeUsecase _addIntakeUsecase;
  final IntakeDataSource _intakeDataSource;
  final AddTrackedDayUsecase _addTrackedDayUsecase;
  final GetKcalGoalUsecase _getKcalGoalUsecase;
  final GetMacroGoalUsecase _getMacroGoalUsecase;

  // Column indices for CSV import
  static const int colId = 0;
  static const int colDate = 1;
  static const int colMealType = 2;
  static const int colName = 3;
  static const int colBrands = 4;
  static const int colAmount = 5;
  static const int colUnit = 6;
  static const int colEnergyKcal100 = 7;
  static const int colCarbs100 = 8;
  static const int colFat100 = 9;
  static const int colProteins100 = 10;
  static const int colSugars100 = 11;
  static const int colSaturatedFat100 = 12;
  static const int colFiber100 = 13;
  static const int colTotalKcal = 14;
  static const int colTotalCarbs = 15;
  static const int colTotalFats = 16;
  static const int colTotalProteins = 17;
  static const int colBarcode = 18;
  static const int colProductUrl = 19;
  static const int colThumbnailUrl = 20;
  static const int colMainImageUrl = 21;
  static const int colServingQuantity = 22;
  static const int colServingUnit = 23;
  static const int colServingSize = 24;
  static const int colSource = 25;
  static const int colIsLiquid = 26;

  static const int expectedColumnCount = 27;

  ImportDataUsecase(
    this._addIntakeUsecase,
    this._intakeDataSource,
    this._addTrackedDayUsecase,
    this._getKcalGoalUsecase,
    this._getMacroGoalUsecase,
  );

  Future<({int imported, int skipped, List<String> errors})> importFoodData(
      String filePath) async {
    final errors = <String>[];
    try {
      if (!await _isValidFileSize(filePath)) {
        throw Exception('File size exceeds maximum limit of 10MB');
      }

      final input = await File(filePath).readAsString();
      _log.fine('Reading CSV file: $filePath');

      // Filter out empty lines first
      final lines = input
          .split(RegExp(r'\r?\n'))
          .where((line) => line.trim().isNotEmpty)
          .toList();

      if (lines.isEmpty) {
        throw Exception('CSV file is empty');
      }

      final headerRow = _parseCSVLine(lines[0]);
      _validateHeaderRow(headerRow);

      int imported = 0;
      int skipped = 0;

      // Process data rows (skip header)
      for (var i = 1; i < lines.length; i++) {
        try {
          final row = _parseCSVLine(lines[i]);
          if (!_isValidRow(row)) {
            // header is row 0
            errors.add('Row $i: Invalid data format');
            skipped++;
            continue;
          }

          final importResult = await _processRow(row);
          if (importResult) {
            imported++;
          } else {
            skipped++;
          }
        } catch (e) {
          errors.add('Row ${i + 1}: ${e.toString()}');
          _log.severe('Error processing row ${i + 1}: $e');
          skipped++;
        }
      }

      return (imported: imported, skipped: skipped, errors: errors);
    } catch (e) {
      _log.severe('Failed to import data: $e');
      errors.add(e.toString());
      return (imported: 0, skipped: 0, errors: errors);
    }
  }

  List<String> _parseCSVLine(String line) {
    List<String> fields = [];
    bool inQuotes = false;
    StringBuffer currentField = StringBuffer();

    for (int i = 0; i < line.length; i++) {
      if (line[i] == '"') {
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          // Handle escaped quotes
          currentField.write('"');
          i++;
        } else {
          // Toggle quote mode
          inQuotes = !inQuotes;
        }
      } else if (line[i] == ',' && !inQuotes) {
        // End of field
        fields.add(currentField.toString());
        currentField.clear();
      } else {
        currentField.write(line[i]);
      }
    }

    // Add the last field
    fields.add(currentField.toString());

    return fields.map((field) => field.trim()).toList();
  }

  void _validateHeaderRow(List<dynamic> header) {
    final expectedHeaders = [
      'ID',
      'Date',
      'Meal Type',
      'Food Name',
      'Brands',
      'Amount',
      'Unit',
      'Energy per 100g/ml (kcal)',
      'Carbs per 100g/ml (g)',
      'Fats per 100g/ml (g)',
      'Proteins per 100g/ml (g)',
      'Sugars per 100g/ml (g)',
      'Saturated Fat per 100g/ml (g)',
      'Fiber per 100g/ml (g)',
      'Total Calories (kcal)',
      'Total Carbs (g)',
      'Total Fats (g)',
      'Total Proteins (g)',
      'Barcode',
      'Product URL',
      'Thumbnail Image URL',
      'Main Image URL',
      'Serving Quantity',
      'Serving Unit',
      'Serving Size',
      'Source',
      'Is Liquid'
    ];

    if (header.length != expectedHeaders.length) {
      throw Exception(
          'Invalid header row: expected ${expectedHeaders.length} columns, got ${header.length}');
    }

    for (var i = 0; i < expectedHeaders.length; i++) {
      if (header[i].toString().trim() != expectedHeaders[i]) {
        throw Exception(
            'Invalid header: expected "${expectedHeaders[i]}" at column $i, got "${header[i]}"');
      }
    }
  }

  Future<bool> _processRow(List<dynamic> row) async {
    final importId = row[colId].toString().trim();

    // Check if intake already exists
    final existingIntake = await _intakeDataSource.getIntakeById(importId);
    if (existingIntake != null) {
      _log.fine('Skipping existing intake with ID: $importId');
      return false;
    }

    final date = DateTime.parse(row[colDate].toString().trim());
    final mealType = IntakeTypeEntity.values.firstWhere(
      (type) =>
          type.toString().split('.').last.toLowerCase() ==
          row[colMealType].toString().toLowerCase(),
    );

    final intake = IntakeEntity(
      id: importId,
      dateTime: date,
      type: mealType,
      meal: MealEntity(
        code: row[colBarcode].toString().isEmpty
            ? importId
            : row[colBarcode].toString(),
        name: row[colName].toString(),
        brands: row[colBrands].toString().isEmpty
            ? null
            : row[colBrands].toString(),
        url: row[colProductUrl].toString().isEmpty
            ? null
            : row[colProductUrl].toString(),
        mealQuantity: row[colAmount].toString(),
        mealUnit: row[colUnit].toString(),
        servingQuantity: row[colServingQuantity].toString().isEmpty
            ? null
            : double.tryParse(row[colServingQuantity].toString()),
        servingUnit: row[colServingUnit].toString().isEmpty
            ? null
            : row[colServingUnit].toString(),
        servingSize: row[colServingSize].toString().isEmpty
            ? ''
            : row[colServingSize].toString(),
        thumbnailImageUrl: row[colThumbnailUrl].toString().isEmpty
            ? null
            : row[colThumbnailUrl].toString(),
        mainImageUrl: row[colMainImageUrl].toString().isEmpty
            ? null
            : row[colMainImageUrl].toString(),
        nutriments: MealNutrimentsEntity(
          energyKcal100: double.parse(row[colEnergyKcal100].toString()),
          carbohydrates100: double.parse(row[colCarbs100].toString()),
          fat100: double.parse(row[colFat100].toString()),
          proteins100: double.parse(row[colProteins100].toString()),
          sugars100: row[colSugars100].toString().isEmpty
              ? null
              : double.tryParse(row[colSugars100].toString()),
          saturatedFat100: row[colSaturatedFat100].toString().isEmpty
              ? null
              : double.tryParse(row[colSaturatedFat100].toString()),
          fiber100: row[colFiber100].toString().isEmpty
              ? null
              : double.tryParse(row[colFiber100].toString()),
        ),
        source: _parseSource(row[colSource].toString()),
      ),
      amount: double.parse(row[colAmount].toString()),
      unit: row[colUnit].toString(),
    );

    _log.fine(
        'Created IntakeEntity: ${intake.id} - ${intake.meal.name} - ${intake.dateTime}');

    await _addIntakeUsecase.addIntake(intake);
    await _updateTrackedDay(intake, date);
    return true;
  }

  Future<void> _updateTrackedDay(
      IntakeEntity intakeEntity, DateTime day) async {
    final hasTrackedDay = await _addTrackedDayUsecase.hasTrackedDay(day);
    if (!hasTrackedDay) {
      final totalKcalGoal = await _getKcalGoalUsecase.getKcalGoal();
      final totalCarbsGoal =
          await _getMacroGoalUsecase.getCarbsGoal(totalKcalGoal);
      final totalFatGoal =
          await _getMacroGoalUsecase.getFatsGoal(totalKcalGoal);
      final totalProteinGoal =
          await _getMacroGoalUsecase.getProteinsGoal(totalKcalGoal);

      await _addTrackedDayUsecase.addNewTrackedDay(
          day, totalKcalGoal, totalCarbsGoal, totalFatGoal, totalProteinGoal);
    }

    await _addTrackedDayUsecase.addDayCaloriesTracked(
        day, intakeEntity.totalKcal);
    await _addTrackedDayUsecase.addDayMacrosTracked(
      day,
      carbsTracked: intakeEntity.totalCarbsGram,
      fatTracked: intakeEntity.totalFatsGram,
      proteinTracked: intakeEntity.totalProteinsGram,
    );
  }

  MealSourceEntity _parseSource(String source) {
    switch (source.toLowerCase()) {
      case 'off':
        return MealSourceEntity.off;
      case 'fdc':
        return MealSourceEntity.fdc;
      case 'custom':
        return MealSourceEntity.custom;
      default:
        return MealSourceEntity.custom;
    }
  }

  Future<bool> _isValidFileSize(String path) async {
    final file = File(path);
    final size = await file.length();
    //somewhat arbitrary limit, but too large files may cause issues
    //TODO: idealiy implement pagination or streaming
    return size <= 10 * 1024 * 1024; // 10MB limit
  }

  bool _isValidRow(List<String> row) {
    if (row.length != expectedColumnCount) return false;

    // Validate date
    try {
      final date = DateTime.parse(row[colDate].trim());
      if (date.isAfter(DateTime.now())) return false;
    } catch (_) {
      return false;
    }

    // Validate numeric values
    for (final col in [
      colAmount,
      colEnergyKcal100,
      colCarbs100,
      colFat100,
      colProteins100
    ]) {
      final value = double.tryParse(row[col]);
      if (value == null || value < 0) return false;
    }

    return true;
  }
}
