import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:opennutritracker/core/data/data_source/intake_data_source.dart';
import 'package:opennutritracker/core/domain/usecase/add_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/add_tracked_day_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_macro_goal_usecase.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/calendar_day_bloc.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/diary_bloc.dart';
import 'package:opennutritracker/features/home/presentation/bloc/home_bloc.dart';
import 'package:opennutritracker/features/settings/domain/usecase/import_data_usecase.dart';
import 'package:opennutritracker/generated/l10n.dart';

import '../../domain/usecase/get_kcal_goal_usecase.dart';

class ImportDialog extends StatelessWidget {
  const ImportDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(S.of(context).settingsImportDataDialogTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(S.of(context).settingsImportDataDialogContent),
          const SizedBox(height: 16),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(S.of(context).dialogCancelLabel),
        ),
        TextButton(
          onPressed: () => _handleImport(context),
          child: Text(S.of(context).dialogOKLabel),
        ),
      ],
    );
  }

  Future<void> _handleImport(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result != null && result.files.single.path != null) {
        await _processImport(context, result.files.single.path!);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).errorImportingData)),
        );
      }
    }
  }

  Future<void> _processImport(BuildContext context, String filePath) async {
    final importDataUsecase = ImportDataUsecase(
      locator<AddIntakeUsecase>(),
      locator<IntakeDataSource>(),
      locator<AddTrackedDayUsecase>(),
      locator<GetKcalGoalUsecase>(),
      locator<GetMacroGoalUsecase>(),
    );

    if (!context.mounted) return;

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final importResult = await importDataUsecase.importFoodData(filePath);

      if (!context.mounted) return;

      // Close loading dialog and import dialog
      Navigator.of(context).pop(); // Close loading dialog
      Navigator.of(context).pop(); // Close import dialog

      // Show results
      if (importResult.errors.isNotEmpty) {
        await _showErrorDialog(context, importResult);
      } else {
        _showSuccessMessage(context, importResult);
      }

      _refreshViews();
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        Navigator.of(context).pop(); // Close import dialog

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).errorImportingData)),
        );
      }
    }
  }

  Future<void> _showErrorDialog(BuildContext context,
      ({int imported, int skipped, List<String> errors}) importResult) {
    return showDialog(
      context: context,
      builder: (context) => _ImportErrorDialog(importResult: importResult),
    );
  }

  void _showSuccessMessage(BuildContext context,
      ({int imported, int skipped, List<String> errors}) importResult) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${S.of(context).importSuccessMessage} '
          '(${importResult.imported} ${S.of(context).itemsImportedLabel})',
        ),
      ),
    );
  }

  void _refreshViews() {
    locator<HomeBloc>().add(const LoadItemsEvent());
    locator<DiaryBloc>().add(const LoadDiaryYearEvent());
    locator<CalendarDayBloc>().add(LoadCalendarDayEvent(DateTime.now()));
  }
}

class _ImportErrorDialog extends StatelessWidget {
  final ({int imported, int skipped, List<String> errors}) importResult;

  const _ImportErrorDialog({required this.importResult});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
          maxWidth: MediaQuery.of(context).size.width * 0.9,
        ),
        child: IntrinsicHeight(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  S.of(context).importErrorsTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${S.of(context).importSummaryLabel}:\n'
                        '${S.of(context).importedLabel}: ${importResult.imported}\n'
                        '${S.of(context).skippedLabel}: ${importResult.skipped}\n'
                        '${S.of(context).errorsLabel}: ${importResult.errors.length}\n\n'
                        '${S.of(context).detailedErrorsLabel}:',
                      ),
                      const SizedBox(height: 8),
                      ...importResult.errors.map(
                        (error) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text('• $error'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(S.of(context).dialogOKLabel),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
