import 'dart:io';
import 'dart:developer' as developer;
import 'package:csv/csv.dart';
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
  final AddIntakeUsecase _addIntakeUsecase;
  final IntakeDataSource _intakeDataSource;
  final AddTrackedDayUsecase _addTrackedDayUsecase;
  final GetKcalGoalUsecase _getKcalGoalUsecase;
  final GetMacroGoalUsecase _getMacroGoalUsecase;

  ImportDataUsecase(
    this._addIntakeUsecase,
    this._intakeDataSource,
    this._addTrackedDayUsecase,
    this._getKcalGoalUsecase,
    this._getMacroGoalUsecase,
  );

  Future<void> importFoodData(String filePath) async {
    try {
      final input = File(filePath).readAsStringSync();
      developer.log('Reading CSV file: $filePath');
      developer.log('File contents: $input');

      final csvConverter = CsvToListConverter(
        shouldParseNumbers: false,
        eol: '\n',
      );

      final fields = csvConverter.convert(input);
      developer.log('Number of rows (including header): ${fields.length}');

      if (fields.isEmpty) {
        throw Exception('CSV file is empty');
      }

      developer.log('CSV Headers: ${fields[0]}');

      int imported = 0;
      int skipped = 0;

      // Skip header row
      for (var i = 1; i < fields.length; i++) {
        final row = fields[i];
        developer.log('Processing row $i: $row');

        final importId = row[0].toString().trim();

        // Check if intake already exists
        final existingIntake = await _intakeDataSource.getIntakeById(importId);
        if (existingIntake != null) {
          developer.log('Skipping existing intake with ID: $importId');
          skipped++;
          continue;
        }

        final date = DateTime.parse(row[1].toString().trim());
        final mealType = IntakeTypeEntity.values.firstWhere(
          (type) =>
              type.toString().split('.').last.toLowerCase() ==
              row[2].toString().toLowerCase(),
        );

        final intake = IntakeEntity(
          id: importId,
          dateTime: date,
          type: mealType,
          meal: MealEntity(
            code: importId,
            name: row[3].toString(),
            url: null,
            mealQuantity: row[4].toString(),
            mealUnit: row[5].toString(),
            servingQuantity: null,
            servingUnit: row[5].toString(),
            servingSize: '',
            nutriments: MealNutrimentsEntity(
              energyKcal100: double.parse(row[6].toString()),
              carbohydrates100: double.parse(row[7].toString()),
              fat100: double.parse(row[8].toString()),
              proteins100: double.parse(row[9].toString()),
              sugars100: null,
              saturatedFat100: null,
              fiber100: null,
            ),
            source: MealSourceEntity.custom,
          ),
          amount: double.parse(row[4].toString()),
          unit: row[5].toString(),
        );

        developer.log(
            'Created IntakeEntity: ${intake.id} - ${intake.meal.name} - ${intake.dateTime}');

        await _addIntakeUsecase.addIntake(intake);
        await _updateTrackedDay(intake, date);
        imported++;
      }
    } catch (e) {
      throw Exception('Failed to import data: $e');
    }
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
    await _addTrackedDayUsecase.addDayMacrosTracked(day,
        carbsTracked: intakeEntity.totalCarbsGram,
        fatTracked: intakeEntity.totalFatsGram,
        proteinTracked: intakeEntity.totalProteinsGram);
  }
}
