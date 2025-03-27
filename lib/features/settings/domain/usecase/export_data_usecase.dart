import 'dart:io';
import 'package:opennutritracker/features/meal_detail/presentation/bloc/meal_detail_bloc.dart';
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

    // Enhanced header row with all relevant fields
    csv.writeln([
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
    ].join(','));

    for (var intake in allIntakes) {
      String exportUnit = intake.unit;
      if (intake.unit == UnitDropdownItem.serving.toString() &&
          intake.meal.servingUnit != null) {
        exportUnit = intake.meal.servingUnit!;
      } else if (intake.unit == UnitDropdownItem.gml.toString()) {
        exportUnit = intake.meal.isLiquid ? 'ml' : 'g';
      }

      csv.writeln([
        _escapeCSVField(intake.id),
        intake.dateTime.toString().split(' ')[0],
        intake.type.toString().split('.').last,
        _escapeCSVField(intake.meal.name ?? ''),
        _escapeCSVField(intake.meal.brands ?? ''),
        intake.amount,
        _escapeCSVField(exportUnit),
        intake.meal.nutriments.energyKcal100,
        intake.meal.nutriments.carbohydrates100,
        intake.meal.nutriments.fat100,
        intake.meal.nutriments.proteins100,
        intake.meal.nutriments.sugars100 ?? '',
        intake.meal.nutriments.saturatedFat100 ?? '',
        intake.meal.nutriments.fiber100 ?? '',
        intake.totalKcal,
        intake.totalCarbsGram,
        intake.totalFatsGram,
        intake.totalProteinsGram,
        _escapeCSVField(intake.meal.code ?? ''),
        _escapeCSVField(intake.meal.url ?? ''),
        _escapeCSVField(intake.meal.thumbnailImageUrl ?? ''),
        _escapeCSVField(intake.meal.mainImageUrl ?? ''),
        intake.meal.servingQuantity ?? '',
        _escapeCSVField(intake.meal.servingUnit ?? ''),
        _escapeCSVField(intake.meal.servingSize ?? ''),
        intake.meal.source.toString().split('.').last,
        intake.meal.isLiquid ? 'true' : 'false'
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
