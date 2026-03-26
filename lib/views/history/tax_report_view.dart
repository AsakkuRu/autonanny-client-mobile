import 'package:flutter/material.dart';
import 'package:nanny_client/ui_sdk/client_ui_sdk.dart';
import 'package:nanny_client/view_models/history/tax_report_vm.dart';

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
    final colors = context.autonannyColors;

    return Scaffold(
      backgroundColor: colors.surfaceBase,
      appBar: AutonannyAppBar(
        title: 'Отчёт для налоговой',
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: AutonannyIcon(
            AutonannyIcons.chevronLeft,
            color: colors.textPrimary,
          ),
        ),
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
    final colors = context.autonannyColors;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: AutonannyRadii.brXl,
        boxShadow: AutonannyShadows.card,
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
            initialValue: vm.selectedYear,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
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
          child: _kpiCard(
            'Поездок',
            '${vm.totalTrips}',
            Icons.directions_car,
            context.autonannyColors.statusInfo,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _kpiCard(
            'Расходов',
            '${vm.totalSpent.toStringAsFixed(0)} ₽',
            Icons.payments,
            context.autonannyColors.actionPrimary,
          ),
        ),
      ],
    );
  }

  Widget _kpiCard(String label, String value, IconData icon, Color color) {
    final colors = context.autonannyColors;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: AutonannyRadii.brLg,
        boxShadow: AutonannyShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: colors.textTertiary),
          ),
        ],
      ),
    );
  }

  Widget _buildTripsList() {
    final colors = context.autonannyColors;

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: AutonannyRadii.brXl,
        boxShadow: AutonannyShadows.card,
      ),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Поездки за год',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
          const Divider(height: 1),
          ...vm.trips.take(20).map(
                (t) => ListTile(
                  dense: true,
                  leading: Icon(
                    Icons.directions_car,
                    color: colors.actionPrimary,
                    size: 20,
                  ),
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
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        )
                      : null,
                ),
              ),
          if (vm.trips.length > 20)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                'И ещё ${vm.trips.length - 20} поездок в PDF-отчёте',
                style: TextStyle(fontSize: 12, color: colors.textTertiary),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLoadButton() {
    return AutonannyButton(
      label: vm.isLoading
          ? 'Загрузка...'
          : 'Загрузить данные за ${vm.selectedYear}',
      isLoading: vm.isLoading,
      leading: vm.isLoading
          ? null
          : const AutonannyIcon(
              AutonannyIcons.inbox,
              color: Colors.white,
            ),
      onPressed: vm.isLoading ? null : vm.loadData,
    );
  }

  Widget _buildExportButton() {
    return AutonannyButton(
      label: vm.isGenerating ? 'Формирование PDF...' : 'Скачать PDF-отчёт',
      isLoading: vm.isGenerating,
      variant: AutonannyButtonVariant.secondary,
      leading: vm.isGenerating
          ? null
          : AutonannyIcon(
              AutonannyIcons.document,
              color: context.autonannyColors.actionPrimary,
            ),
      onPressed: vm.isGenerating ? null : vm.generateAndSharePdf,
    );
  }

  Widget _buildDisclaimer() {
    final colors = context.autonannyColors;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.statusWarningSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.statusWarning.withValues(alpha: 0.24)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: colors.statusWarning, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Данный отчёт носит справочный характер. Расходы на детский транспорт могут учитываться как налоговый вычет. Уточняйте у специалиста.',
              style: TextStyle(fontSize: 12, color: colors.statusWarning),
            ),
          ),
        ],
      ),
    );
  }
}
