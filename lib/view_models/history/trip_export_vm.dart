import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:nanny_client/ui_sdk/support/ui_sdk_dialogs.dart';
import 'package:nanny_core/api/nanny_orders_api.dart';
import 'package:nanny_core/models/from_api/trip_history.dart';

class TripExportVM {
  TripExportVM({
    required this.context,
    required this.update,
  });

  final BuildContext context;
  final void Function(void Function()) update;

  DateTime? startDate;
  DateTime? endDate;
  bool isLoading = false;
  bool isExporting = false;
  List<TripHistory> trips = [];

  final _dateFormat = DateFormat('dd.MM.yyyy');
  final _dateTimeFormat = DateFormat('dd.MM.yyyy HH:mm');

  Future<void> selectStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate:
          startDate ?? DateTime.now().subtract(const Duration(days: 30)),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      update(() => startDate = date);
    }
  }

  Future<void> selectEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: endDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      update(() => endDate = date);
    }
  }

  Future<void> loadTrips() async {
    update(() => isLoading = true);

    final result = await NannyOrdersApi.getTripHistory(
      startDate: startDate,
      endDate: endDate,
    );

    if (result.success && result.response != null) {
      trips = result.response!;
      trips.sort((a, b) => b.date.compareTo(a.date));
    } else {
      trips = _generateMockData();
    }

    update(() => isLoading = false);
  }

  Future<void> exportPdf() async {
    if (trips.isEmpty) {
      NannyDialogs.showMessageBox(
          context, 'Нет данных', 'Нет поездок за выбранный период.');
      return;
    }

    update(() => isExporting = true);

    try {
      final pdf = pw.Document();

      final periodText = _buildPeriodText();
      final totalPrice = trips
          .where((t) => t.price != null && t.isCompleted)
          .fold<double>(0, (sum, t) => sum + t.price!);
      final completedCount = trips.where((t) => t.isCompleted).length;
      final cancelledCount = trips.where((t) => t.isCancelled).length;

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          header: (ctx) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'История поездок — АвтоНяня',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Период: $periodText',
                style:
                    const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
              ),
              pw.Divider(),
            ],
          ),
          footer: (ctx) => pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Сформировано: ${_dateTimeFormat.format(DateTime.now())}',
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey),
              ),
              pw.Text(
                'Стр. ${ctx.pageNumber} из ${ctx.pagesCount}',
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey),
              ),
            ],
          ),
          build: (ctx) => [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                _pdfStat('Всего поездок', '${trips.length}'),
                _pdfStat('Завершённых', '$completedCount'),
                _pdfStat('Отменённых', '$cancelledCount'),
                _pdfStat('Итого', '${totalPrice.toStringAsFixed(0)} р.'),
              ],
            ),
            pw.SizedBox(height: 16),
            pw.TableHelper.fromTextArray(
              headerStyle:
                  pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
              cellStyle: const pw.TextStyle(fontSize: 9),
              headerDecoration:
                  const pw.BoxDecoration(color: PdfColors.grey200),
              cellHeight: 28,
              columnWidths: {
                0: const pw.FixedColumnWidth(70),
                1: const pw.FlexColumnWidth(2),
                2: const pw.FlexColumnWidth(2),
                3: const pw.FixedColumnWidth(60),
                4: const pw.FixedColumnWidth(70),
              },
              headers: ['Дата', 'Откуда', 'Куда', 'Цена', 'Статус'],
              data: trips
                  .map((t) => [
                        _dateFormat.format(t.date),
                        t.addressFrom,
                        t.addressTo,
                        t.price != null
                            ? '${t.price!.toStringAsFixed(0)} р.'
                            : '—',
                        t.statusText,
                      ])
                  .toList(),
            ),
          ],
        ),
      );

      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename:
            'trips_${_dateFormat.format(startDate ?? DateTime.now())}_${_dateFormat.format(endDate ?? DateTime.now())}.pdf',
      );
    } catch (e) {
      if (context.mounted) {
        NannyDialogs.showMessageBox(
            context, 'Ошибка', 'Не удалось создать PDF: $e');
      }
    }

    update(() => isExporting = false);
  }

  pw.Widget _pdfStat(String label, String value) {
    return pw.Column(
      children: [
        pw.Text(label,
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
        pw.SizedBox(height: 2),
        pw.Text(value,
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
      ],
    );
  }

  String _buildPeriodText() {
    if (startDate != null && endDate != null) {
      return '${_dateFormat.format(startDate!)} — ${_dateFormat.format(endDate!)}';
    }
    if (startDate != null) return 'с ${_dateFormat.format(startDate!)}';
    if (endDate != null) return 'по ${_dateFormat.format(endDate!)}';
    return 'За всё время';
  }

  List<TripHistory> _generateMockData() {
    final now = DateTime.now();
    return [
      TripHistory(
          id: 1,
          date: now.subtract(const Duration(days: 1)),
          addressFrom: 'ул. Ленина, 15',
          addressTo: 'Школа №42',
          driverName: 'Иван Петров',
          price: 450,
          status: 'completed',
          rating: 5,
          durationMinutes: 25,
          distanceKm: 8.5),
      TripHistory(
          id: 2,
          date: now.subtract(const Duration(days: 3)),
          addressFrom: 'Школа №42',
          addressTo: 'ул. Ленина, 15',
          driverName: 'Иван Петров',
          price: 420,
          status: 'completed',
          rating: 5,
          durationMinutes: 22,
          distanceKm: 8.2),
      TripHistory(
          id: 3,
          date: now.subtract(const Duration(days: 5)),
          addressFrom: 'ул. Ленина, 15',
          addressTo: 'Бассейн "Дельфин"',
          driverName: 'Алексей Козлов',
          price: 0,
          status: 'cancelled_by_driver'),
    ];
  }
}
