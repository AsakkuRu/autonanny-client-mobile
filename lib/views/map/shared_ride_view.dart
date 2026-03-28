import 'package:autonanny_ui_core/autonanny_ui_core.dart';
import 'package:flutter/material.dart';
import 'package:nanny_client/view_models/map/shared_ride_vm.dart';
import 'package:nanny_components/nanny_components.dart';

class SharedRideView extends StatefulWidget {
  const SharedRideView({super.key});

  @override
  State<SharedRideView> createState() => _SharedRideViewState();
}

class _SharedRideViewState extends State<SharedRideView> {
  late SharedRideVM vm;

  @override
  void initState() {
    super.initState();
    vm = SharedRideVM(context: context, update: setState);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NannyTheme.background,
      appBar: const NannyAppBar.light(
        title: 'Совместные поездки',
      ),
      body: FutureLoader(
        future: vm.loadRequest,
        completeView: (context, data) {
          if (vm.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (vm.error != null) {
            return _buildErrorState(vm.error!);
          }

          if (vm.isEmpty) {
            return _buildEmptyState();
          }

          return Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: NannyTheme.primary.withValues(alpha: 0.04),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline,
                        color: NannyTheme.primary, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Совместная поездка позволяет разделить стоимость с другим родителем на похожем маршруте.',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: NannyTheme.neutral700),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: vm.refresh,
                  color: NannyTheme.primary,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: vm.options.length,
                    itemBuilder: (context, index) =>
                        _buildOptionCard(vm.options[index]),
                  ),
                ),
              ),
            ],
          );
        },
        errorView: (context, error) => ErrorView(errorText: error.toString()),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline,
                size: 64, color: NannyTheme.danger),
            const SizedBox(height: 16),
            Text(
              'Не удалось загрузить поездки',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: NannyTheme.neutral500),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: vm.refresh,
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: const Text(
                'Повторить',
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: NannyTheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.people_outline,
                size: 64, color: NannyTheme.neutral300),
            const SizedBox(height: 16),
            Text(
              'Нет подходящих совместных поездок',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Мы автоматически найдём родителей с похожими маршрутами и предложим объединить поездки.',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: NannyTheme.neutral500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard(SharedRideOption option) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: NannyTheme.shadow.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    AutonannyAvatar(
                      initials: option.parentName.isNotEmpty
                          ? option.parentName[0]
                          : 'Р',
                      size: 36,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          option.parentName,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          '${option.childName}, ${option.childAge} лет',
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(color: NannyTheme.neutral600),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _matchColor(option.matchPercent)
                            .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${option.matchPercent}% совпадение',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _matchColor(option.matchPercent),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _routeRow(
                Icons.circle, option.addressFrom, NannyTheme.primary, 10),
            Container(
              margin: const EdgeInsets.only(left: 4),
              height: 16,
              width: 2,
              color: NannyTheme.neutral200,
            ),
            _routeRow(Icons.location_on, option.addressTo,
                NannyTheme.danger, 16),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.schedule,
                    size: 14, color: NannyTheme.neutral600),
                const SizedBox(width: 4),
                Text(
                  'Отправление: ${option.time}',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: NannyTheme.neutral600),
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${option.sharedPrice.toStringAsFixed(0)} ₽',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    Row(
                      children: [
                        Text(
                          '${option.originalPrice.toStringAsFixed(0)} ₽',
                          style: const TextStyle(
                            fontSize: 13,
                            color: NannyTheme.neutral400,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: NannyTheme.success.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '-${option.savings.toStringAsFixed(0)} ₽',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: NannyTheme.success,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: vm.isRequesting
                      ? null
                      : () => vm.requestSharedRide(option),
                  child: const Text('Присоединиться'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _routeRow(IconData icon, String text, Color color, double iconSize) {
    return Row(
      children: [
        Icon(icon, size: iconSize, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Color _matchColor(int percent) {
    if (percent >= 85) return Colors.green;
    if (percent >= 70) return Colors.orange;
    return Colors.red;
  }
}
