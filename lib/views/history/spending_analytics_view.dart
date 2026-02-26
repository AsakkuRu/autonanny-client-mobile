import 'package:flutter/material.dart';
import 'package:nanny_client/view_models/history/spending_analytics_vm.dart';
import 'package:nanny_components/nanny_components.dart';

class SpendingAnalyticsView extends StatefulWidget {
  const SpendingAnalyticsView({super.key});

  @override
  State<SpendingAnalyticsView> createState() => _SpendingAnalyticsViewState();
}

class _SpendingAnalyticsViewState extends State<SpendingAnalyticsView> {
  late SpendingAnalyticsVM vm;

  @override
  void initState() {
    super.initState();
    vm = SpendingAnalyticsVM(context: context, update: setState);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text(
          'Аналитика расходов',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: FutureLoader(
        future: vm.loadRequest,
        completeView: (context, data) {
          if (vm.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          return RefreshIndicator(
            onRefresh: () async => vm.reloadPage(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPeriodSelector(),
                  const SizedBox(height: 16),
                  _buildSummaryCards(),
                  const SizedBox(height: 20),
                  _buildMonthlyChart(),
                  const SizedBox(height: 20),
                  _buildDriverBreakdown(),
                ],
              ),
            ),
          );
        },
        errorView: (context, error) => ErrorView(errorText: error.toString()),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: vm.periods.map((period) {
          final isSelected = vm.selectedPeriod == period;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(
                period,
                style: TextStyle(
                  fontSize: 13,
                  color: isSelected ? Colors.white : Colors.black87,
                ),
              ),
              selected: isSelected,
              onSelected: (_) => vm.changePeriod(period),
              backgroundColor: Colors.grey[200],
              selectedColor: NannyTheme.primary,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Row(
      children: [
        Expanded(child: _summaryCard('Всего', '${vm.totalSpent.toStringAsFixed(0)} ₽', Icons.wallet, NannyTheme.primary)),
        const SizedBox(width: 8),
        Expanded(child: _summaryCard('Поездок', '${vm.totalTrips}', Icons.directions_car, Colors.green)),
        const SizedBox(width: 8),
        Expanded(child: _summaryCard('Средняя', '${vm.averageTrip.toStringAsFixed(0)} ₽', Icons.analytics, Colors.orange)),
      ],
    );
  }

  Widget _summaryCard(String label, String value, IconData icon, Color color) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyChart() {
    if (vm.monthlySpendings.isEmpty) return const SizedBox.shrink();

    final maxAmount = vm.monthlySpendings
        .fold<double>(0, (max, s) => s.amount > max ? s.amount : max);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Расходы по месяцам',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 180,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: vm.monthlySpendings.map((s) {
                  final barHeight = maxAmount > 0 ? (s.amount / maxAmount) * 150 : 0.0;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            '${s.amount.toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            height: barHeight,
                            decoration: BoxDecoration(
                              color: NannyTheme.primary,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            s.label,
                            style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDriverBreakdown() {
    if (vm.driverSpendings.isEmpty) return const SizedBox.shrink();

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Расходы по водителям',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            // Pie chart substitute — horizontal bars
            ...vm.driverSpendings.map((ds) {
              final percent = vm.totalSpent > 0 ? (ds.total / vm.totalSpent) : 0.0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: ds.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              ds.name,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        Text(
                          '${ds.total.toStringAsFixed(0)} ₽ (${ds.tripCount} поездок)',
                          style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: percent,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation(ds.color),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              );
            }),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Итого',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                Text(
                  '${vm.totalSpent.toStringAsFixed(0)} ₽',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: NannyTheme.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
