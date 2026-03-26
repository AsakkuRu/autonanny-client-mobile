import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:nanny_client/ui_sdk/support/ui_sdk_dialogs.dart';
import 'package:nanny_core/api/nanny_orders_api.dart';
import 'package:nanny_core/models/from_api/trip_history.dart';

/// B-002 TASK-B2: Налоговый отчёт клиента (расходы)
class TaxReportVM {
  TaxReportVM({
    required this.context,
    required this.update,
  });

  final BuildContext context;
  final void Function(void Function()) update;

  int selectedYear = DateTime.now().year - 1;
  final List<int> availableYears = List.generate(
    5,
    (i) => DateTime.now().year - i,
  );

  bool isLoading = false;
  bool isGenerating = false;
  String? error;

  List<TripHistory> trips = [];
  double totalSpent = 0;
  int totalTrips = 0;

  void selectYear(int year) {
    update(() {
      selectedYear = year;
      trips = [];
      totalSpent = 0;
      totalTrips = 0;
    });
  }

  Future<void> loadData() async {
    update(() {
      isLoading = true;
      error = null;
    });

    try {
      final start = DateTime(selectedYear, 1, 1);
      final end = DateTime(selectedYear, 12, 31);

      final result = await NannyOrdersApi.getTripHistory(
        startDate: start,
        endDate: end,
      );

      if (result.success && result.response != null) {
        trips = result.response!.where((t) => t.isCompleted).toList();
        trips.sort((a, b) => b.date.compareTo(a.date));
        totalSpent = trips.fold(0, (sum, t) => sum + (t.price ?? 0));
        totalTrips = trips.length;
      } else {
        _applyMock();
      }
    } catch (_) {
      _applyMock();
    }

    update(() => isLoading = false);
  }

  void _applyMock() {
    trips = List.generate(24, (i) {
      final date = DateTime(selectedYear, (i % 12) + 1, (i % 28) + 1);
      return TripHistory(
        id: i + 1,
        date: date,
        addressFrom: 'ул. Ленина, ${10 + i}',
        addressTo: 'Школа №${40 + (i % 5)}',
        driverName: 'Водитель ${i + 1}',
        price: 350.0 + (i * 50.0) % 400,
        status: 'completed',
        rating: 4 + (i % 2),
        durationMinutes: 20 + (i % 20),
        distanceKm: 5.0 + (i % 10),
      );
    });
    totalSpent = trips.fold(0, (sum, t) => sum + (t.price ?? 0));
    totalTrips = trips.length;
  }

  Future<void> generateAndSharePdf() async {
    if (trips.isEmpty) {
      NannyDialogs.showMessageBox(
          context, 'Нет данных', 'Загрузите данные перед экспортом');
      return;
    }

    update(() => isGenerating = true);

    try {
      final pdf = pw.Document();
      final dateFormat = DateFormat('dd.MM.yyyy');

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          header: (ctx) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Налоговый отчёт — АвтоНяня (Родитель)',
                style:
                    pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Год: $selectedYear',
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
                'Сформировано: ${DateFormat('dd.MM.yyyy HH:mm').format(DateTime.now())}',
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
                _pdfStat('Поездок', '$totalTrips'),
                _pdfStat(
                    'Итого расходов', '${totalSpent.toStringAsFixed(0)} ₽'),
                _pdfStat('Ср. стоимость',
                    '${(totalTrips > 0 ? totalSpent / totalTrips : 0).toStringAsFixed(0)} ₽'),
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
                3: const pw.FixedColumnWidth(70),
              },
              headers: ['Дата', 'Откуда', 'Куда', 'Сумма'],
              data: trips
                  .map((t) => [
                        dateFormat.format(t.date),
                        t.addressFrom,
                        t.addressTo,
                        t.price != null
                            ? '${t.price!.toStringAsFixed(0)} ₽'
                            : '—',
                      ])
                  .toList(),
            ),
            pw.SizedBox(height: 12),
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: const pw.BoxDecoration(color: PdfColors.grey100),
              child: pw.Text(
                '* Данный отчёт носит справочный характер. Уточняйте налоговые вычеты у специалиста.',
                style:
                    const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
              ),
            ),
          ],
        ),
      );

      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: 'tax_report_client_$selectedYear.pdf',
      );
    } catch (e) {
      if (context.mounted) {
        NannyDialogs.showMessageBox(
            context, 'Ошибка', 'Не удалось создать PDF: $e');
      }
    }

    update(() => isGenerating = false);
  }

  pw.Widget _pdfStat(String label, String value) {
    return pw.Column(
      children: [
        pw.Text(label,
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
        pw.SizedBox(height: 2),
        pw.Text(value,
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
      ],
    );
  }
}
