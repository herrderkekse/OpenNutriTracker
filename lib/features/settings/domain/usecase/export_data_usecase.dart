import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:opennutritracker/core/domain/usecase/get_intake_usecase.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';

class ExportDataUsecase {
  final GetIntakeUsecase _getIntakeUsecase;

  ExportDataUsecase(this._getIntakeUsecase);

  Future<String> exportFoodData(DateTime startDate, DateTime endDate) async {
    // Get all intake data between dates
    List<IntakeEntity> allIntakes = [];

    // Iterate through each day in the date range
    for (DateTime date = startDate;
        date.isBefore(endDate.add(const Duration(days: 1)));
        date = date.add(const Duration(days: 1))) {
      final breakfast = await _getIntakeUsecase.getBreakfastIntakeByDay(date);
      final lunch = await _getIntakeUsecase.getLunchIntakeByDay(date);
      final dinner = await _getIntakeUsecase.getDinnerIntakeByDay(date);
      final snacks = await _getIntakeUsecase.getSnackIntakeByDay(date);

      allIntakes.addAll([...breakfast, ...lunch, ...dinner, ...snacks]);
    }

    // Create CSV data
    final StringBuffer csv = StringBuffer();

    // Add header row
    csv.writeln([
      'ID',
      'Date',
      'Meal Type',
      'Food Name',
      'Amount',
      'Unit',
      'Calories (kcal)',
      'Carbs (g)',
      'Fats (g)',
      'Proteins (g)'
    ].join(','));

    // Add data rows
    for (var intake in allIntakes) {
      csv.writeln([
        _escapeCSVField(intake.id),
        intake.dateTime.toString().split(' ')[0],
        intake.type.toString().split('.').last,
        _escapeCSVField(intake.meal.name ?? ''),
        intake.amount,
        _escapeCSVField(intake.unit),
        intake.totalKcal,
        intake.totalCarbsGram,
        intake.totalFatsGram,
        intake.totalProteinsGram
      ].join(','));
    }

    // Save to file
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
