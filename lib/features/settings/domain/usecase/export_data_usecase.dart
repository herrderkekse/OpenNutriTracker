import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';
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
    List<List<dynamic>> rows = [];
    
    // Add header row
    rows.add([
      'Date',
      'Meal Type',
      'Food Name',
      'Amount',
      'Unit',
      'Calories (kcal)',
      'Carbs (g)',
      'Fats (g)',
      'Proteins (g)'
    ]);

    // Add data rows
    for (var intake in allIntakes) {
      rows.add([
        intake.dateTime.toString().split(' ')[0],
        intake.type.toString().split('.').last,
        intake.meal.name,
        intake.amount,
        intake.unit,
        intake.totalKcal,
        intake.totalCarbsGram,
        intake.totalFatsGram,
        intake.totalProteinsGram
      ]);
    }

    // Convert to CSV
    String csv = const ListToCsvConverter().convert(rows);

    // Save to file
    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'food_diary_${DateTime.now().millisecondsSinceEpoch}.csv';
    final file = File('${directory.path}/$fileName');
    await file.writeAsString(csv);

    return file.path;
  }
}