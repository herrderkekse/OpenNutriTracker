import 'dart:io';
import 'dart:developer' as developer;
import 'package:csv/csv.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/domain/usecase/add_intake_usecase.dart';
import 'package:opennutritracker/core/utils/id_generator.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';

class ImportDataUsecase {
  final AddIntakeUsecase _addIntakeUsecase;

  ImportDataUsecase(this._addIntakeUsecase);

  Future<void> importFoodData(String filePath) async {
    try {
      final input = File(filePath).readAsStringSync();
      developer.log('Reading CSV file: $filePath');
      developer.log('File contents: $input'); // Debug log to see raw content

      // Configure CSV parser to handle different line endings
      final csvConverter = CsvToListConverter(
        shouldParseNumbers:
            false, // Parse numbers manually to avoid precision issues
        eol: '\n', // Explicitly set line ending
      );

      final fields = csvConverter.convert(input);
      developer.log('Number of rows (including header): ${fields.length}');

      if (fields.isEmpty) {
        throw Exception('CSV file is empty');
      }

      // Log headers to verify CSV structure
      developer.log('CSV Headers: ${fields[0]}');

      // Skip header row
      for (var i = 1; i < fields.length; i++) {
        final row = fields[i];
        developer.log('Processing row $i: $row');

        final date = DateTime.parse(row[0].toString().trim());
        final mealType = IntakeTypeEntity.values.firstWhere(
          (type) =>
              type.toString().split('.').last.toLowerCase() ==
              row[1].toString().toLowerCase(),
        );

        final intake = IntakeEntity(
          dateTime: date,
          type: mealType,
          meal: MealEntity(
            code: IdGenerator.getUniqueID(),
            name: row[2].toString(),
            url: null,
            mealQuantity: row[3].toString(),
            mealUnit: row[4].toString(),
            servingQuantity: null,
            servingUnit: row[4].toString(),
            servingSize: '',
            nutriments: MealNutrimentsEntity(
              energyKcal100: double.parse(row[5].toString()),
              carbohydrates100: double.parse(row[6].toString()),
              fat100: double.parse(row[7].toString()),
              proteins100: double.parse(row[8].toString()),
              sugars100: null,
              saturatedFat100: null,
              fiber100: null,
            ),
            source: MealSourceEntity.custom,
          ),
          amount: double.parse(row[3].toString()),
          unit: row[4].toString(),
          id: IdGenerator.getUniqueID(),
        );

        developer.log(
            'Created IntakeEntity: ${intake.id} - ${intake.meal.name} - ${intake.dateTime}');

        await _addIntakeUsecase.addIntake(intake);
        developer.log('Successfully added intake to database');
      }

      developer.log('Import completed successfully');
    } catch (e, stackTrace) {
      developer.log('Error during import: $e\n$stackTrace');
      rethrow;
    }
  }
}
