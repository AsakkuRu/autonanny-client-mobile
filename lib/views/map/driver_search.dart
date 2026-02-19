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

        return Padding(
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
        );
      },
      errorView: (context, error) => ErrorView(errorText: error.toString()),
    );
  }
}
