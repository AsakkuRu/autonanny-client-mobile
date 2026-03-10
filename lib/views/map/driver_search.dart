import 'package:flutter/material.dart';
import 'package:nanny_client/view_models/map/drive_search_vm.dart';
import 'package:nanny_components/nanny_components.dart';

class DriverSearchView extends StatefulWidget {
  const DriverSearchView({super.key, required this.token});

  final String token;

  @override
  State<DriverSearchView> createState() => _DriverSearchViewState();
}

class _DriverSearchViewState extends State<DriverSearchView> {
  late DriveSearchVM vm;

  @override
  void initState() {
    super.initState();
    vm = DriveSearchVM(
      context: context,
      update: setState,
      token: widget.token,
    );
  }

  @override
  void dispose() {
    vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureLoader(
      future: vm.loadRequest,
      completeView: (context, data) {
        if (!data) {
          return const ErrorView(errorText: "Не удалось загрузить данные!");
        }

        return Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    vm.driverFound ? Icons.check_circle : Icons.search,
                    size: 64,
                    color: vm.driverFound ? Colors.green : NannyTheme.primary,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    vm.statusText,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  if (vm.isSearching) const LinearProgressIndicator(),
                  if (vm.driverLocation != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      'Координаты водителя: ${vm.driverLocation!['lat']?.toStringAsFixed(4)}, ${vm.driverLocation!['lon']?.toStringAsFixed(4)}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                  const SizedBox(height: 30),
                  if (vm.isSearching)
                    ElevatedButton(
                      onPressed: vm.cancelSearch,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: const Text('Отменить поиск'),
                    ),
                  if (!vm.isSearching && !vm.driverFound)
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Назад'),
                    ),
                  if (vm.driverFound)
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Закрыть'),
                    ),
                ],
              ),
            ),
            // TASK-B11: Баннер срочного заказа «На замену»
            if (vm.isUrgentReplacement)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  color: Colors.orange.shade600,
                  child: Row(
                    children: [
                      const Icon(Icons.swap_horiz, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Водитель на замену',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            if (vm.urgentReason != null)
                              Text(
                                vm.urgentReason!,
                                style: const TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                          ],
                        ),
                      ),
                      if (vm.urgentMultiplier != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'x${vm.urgentMultiplier!.toStringAsFixed(1)}',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

            // TASK-C6: Bottom sheet с альтернативными тарифами
            if (vm.showAlternatives)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _buildAlternativesSheet(),
              ),
          ],
        );
      },
        errorView: (context, error) => ErrorView(errorText: error.toString()),
    );
  }

  Widget _buildAlternativesSheet() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).padding.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Водителей этого класса нет',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Попробуйте другой класс авто',
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: vm.dismissAlternatives,
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...vm.alternatives.map((alt) => _buildAlternativeTile(alt)),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: vm.dismissAlternatives,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                side: BorderSide(color: Colors.grey[300]!),
              ),
              child: const Text('Продолжить ожидание'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlternativeTile(alt) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: NannyTheme.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.directions_car, color: NannyTheme.primary),
        ),
        title: Text(
          alt.tariffName,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        subtitle: Text(
          'Ожидание ~${alt.estimatedWaitMinutes} мин',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${alt.price.toStringAsFixed(0)} ₽',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            GestureDetector(
              onTap: vm.isSwitchingTariff ? null : () => vm.switchTariff(alt),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: NannyTheme.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: vm.isSwitchingTariff
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text(
                        'Выбрать',
                        style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
