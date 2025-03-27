import 'package:flutter/material.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/core/domain/usecase/get_intake_usecase.dart';
import 'package:opennutritracker/features/settings/domain/usecase/export_data_usecase.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:share_plus/share_plus.dart';

class ExportDialog extends StatefulWidget {
  const ExportDialog({super.key});

  @override
  State<ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends State<ExportDialog> {
  DateTime startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime endDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(S.of(context).settingsExportDataDialogTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(S.of(context).settingsExportDataDialogContent),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => _selectDate(context, isStartDate: true),
                  child: Text(
                    'Start: ${_formatDate(startDate)}',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextButton(
                  onPressed: () => _selectDate(context, isStartDate: false),
                  child: Text(
                    'End: ${_formatDate(endDate)}',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(S.of(context).dialogCancelLabel),
        ),
        TextButton(
          onPressed: () => _handleExport(context),
          child: Text(S.of(context).dialogOKLabel),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return date.toLocal().toString().split(' ')[0];
  }

  Future<void> _selectDate(BuildContext context,
      {required bool isStartDate}) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? startDate : endDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          startDate = picked;
        } else {
          endDate = picked;
        }
      });
    }
  }

  Future<void> _handleExport(BuildContext context) async {
    try {
      final exportDataUsecase = ExportDataUsecase(locator<GetIntakeUsecase>());
      final filePath =
          await exportDataUsecase.exportFoodData(startDate, endDate);

      if (!context.mounted) return;
      Navigator.of(context).pop();

      await Share.shareXFiles(
        [XFile(filePath)],
        subject: 'Food Diary Export',
        sharePositionOrigin: Rect.fromLTWH(
          0,
          0,
          MediaQuery.of(context).size.width,
          MediaQuery.of(context).size.height / 2,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(S.of(context).errorExportingData),
        ),
      );
    }
  }
}
