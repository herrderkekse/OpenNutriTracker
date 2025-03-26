import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:opennutritracker/core/domain/usecase/get_intake_usecase.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';

class ExportDataUsecase {
  final GetIntakeUsecase _getIntakeUsecase;

  ExportDataUsecase(this._getIntakeUsecase);

  Future<String> exportFoodData(DateTime startDate, DateTime endDate) async {
    List<IntakeEntity> allIntakes = [];

    for (DateTime date = startDate;
        date.isBefore(endDate.add(const Duration(days: 1)));
        date = date.add(const Duration(days: 1))) {
      final breakfast = await _getIntakeUsecase.getBreakfastIntakeByDay(date);
      final lunch = await _getIntakeUsecase.getLunchIntakeByDay(date);
      final dinner = await _getIntakeUsecase.getDinnerIntakeByDay(date);
      final snacks = await _getIntakeUsecase.getSnackIntakeByDay(date);

      allIntakes.addAll([...breakfast, ...lunch, ...dinner, ...snacks]);
    }

    final StringBuffer csv = StringBuffer();

    // Add header row
    csv.writeln([
      'ID',
      'Date',
      'Meal Type',
      'Food Name',
      'Amount',
      'Unit',
      'Energy per 100g (kcal)',
      'Carbs per 100g (g)',
      'Fats per 100g (g)',
      'Proteins per 100g (g)',
      'Total Calories (kcal)',
      'Total Carbs (g)',
      'Total Fats (g)',
      'Total Proteins (g)'
    ].join(','));

    for (var intake in allIntakes) {
      csv.writeln([
        _escapeCSVField(intake.id),
        intake.dateTime.toString().split(' ')[0],
        intake.type.toString().split('.').last,
        _escapeCSVField(intake.meal.name ?? ''),
        intake.amount,
        _escapeCSVField(intake.unit),
        intake.meal.nutriments.energyKcal100,
        intake.meal.nutriments.carbohydrates100,
        intake.meal.nutriments.fat100,
        intake.meal.nutriments.proteins100,
        intake.totalKcal,
        intake.totalCarbsGram,
        intake.totalFatsGram,
        intake.totalProteinsGram
      ].join(','));
    }

    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'food_diary_${DateTime.now().millisecondsSinceEpoch}.csv';
    final file = File('${directory.path}/$fileName');
    await file.writeAsString(csv.toString());

    return file.path;
  }

  String _escapeCSVField(String field) {
    // If the field contains commas, quotes, or newlines, wrap it in quotes
    if (field.contains(RegExp(r'[,"\n]'))) {
      // Replace any quotes with double quotes (CSV standard)
      field = field.replaceAll('"', '""');
      // Wrap the field in quotes
      return '"$field"';
    }
    return field;
  }
}
