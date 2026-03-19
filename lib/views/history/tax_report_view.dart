import 'package:flutter/material.dart';
import 'package:nanny_client/view_models/history/tax_report_vm.dart';
import 'package:nanny_components/nanny_components.dart';

/// B-002 TASK-B2: Экран налогового отчёта клиента
class TaxReportView extends StatefulWidget {
  const TaxReportView({super.key});

  @override
  State<TaxReportView> createState() => _TaxReportViewState();
}

class _TaxReportViewState extends State<TaxReportView> {
  late TaxReportVM vm;

  @override
  void initState() {
    super.initState();
    vm = TaxReportVM(context: context, update: setState);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NannyTheme.background,
      appBar: const NannyAppBar.light(
        title: 'Отчёт для налоговой',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildYearSelector(),
            const SizedBox(height: 20),
            if (vm.trips.isNotEmpty) _buildSummaryCards(),
            if (vm.trips.isNotEmpty) ...[
              const SizedBox(height: 20),
              _buildTripsList(),
            ],
            const SizedBox(height: 20),
            _buildLoadButton(),
            if (vm.trips.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildExportButton(),
            ],
            const SizedBox(height: 16),
            _buildDisclaimer(),
          ],
        ),
      ),
    );
  }

  Widget _buildYearSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: NannyTheme.shadow.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Налоговый год',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            value: vm.selectedYear,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            items: vm.availableYears
                .map((y) => DropdownMenuItem(value: y, child: Text('$y год')))
                .toList(),
            onChanged: (year) {
              if (year != null) vm.selectYear(year);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Row(
      children: [
        Expanded(
          child: _kpiCard('Поездок', '${vm.totalTrips}', Icons.directions_car, Colors.blue),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _kpiCard('Расходов', '${vm.totalSpent.toStringAsFixed(0)} ₽', Icons.payments, NannyTheme.primary),
        ),
      ],
    );
  }

  Widget _kpiCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
          ),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildTripsList() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: NannyTheme.shadow.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Поездки за год', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
          const Divider(height: 1),
          ...vm.trips.take(20).map((t) => ListTile(
            dense: true,
            leading: const Icon(Icons.directions_car, color: NannyTheme.primary, size: 20),
            title: Text(
              '${t.addressFrom} → ${t.addressTo}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13),
            ),
            subtitle: Text(
              '${t.date.day}.${t.date.month}.${t.date.year}',
              style: const TextStyle(fontSize: 11),
            ),
            trailing: t.price != null
                ? Text(
                    '${t.price!.toStringAsFixed(0)} ₽',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  )
                : null,
          )),
          if (vm.trips.length > 20)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                'И ещё ${vm.trips.length - 20} поездок в PDF-отчёте',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLoadButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: vm.isLoading ? null : vm.loadData,
        icon: vm.isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.cloud_download, color: Colors.white),
        label: Text(
          vm.isLoading ? 'Загрузка...' : 'Загрузить данные за ${vm.selectedYear}',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: NannyTheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildExportButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: vm.isGenerating ? null : vm.generateAndSharePdf,
        icon: vm.isGenerating
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.picture_as_pdf, color: Colors.white),
        label: Text(
          vm.isGenerating ? 'Формирование PDF...' : 'Скачать PDF-отчёт',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepOrange,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildDisclaimer() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: Colors.amber[700], size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Данный отчёт носит справочный характер. Расходы на детский транспорт могут учитываться как налоговый вычет. Уточняйте у специалиста.',
              style: TextStyle(fontSize: 12, color: Colors.amber[900]),
            ),
          ),
        ],
      ),
    );
  }
}
