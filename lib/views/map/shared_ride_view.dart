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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text(
          'Совместные поездки',
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

          if (vm.options.isEmpty) {
            return _buildEmptyState();
          }

          return Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: Colors.blue.withOpacity(0.05),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Совместная поездка позволяет разделить стоимость с другим родителем на похожем маршруте.',
                        style: TextStyle(fontSize: 13, color: Colors.blue[800]),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: vm.options.length,
                  itemBuilder: (context, index) =>
                      _buildOptionCard(vm.options[index]),
                ),
              ),
            ],
          );
        },
        errorView: (context, error) => ErrorView(errorText: error.toString()),
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
            Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'Нет подходящих совместных поездок',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Мы автоматически найдём родителей с похожими маршрутами и предложим объединить поездки.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard(SharedRideOption option) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: NannyTheme.primary.withOpacity(0.1),
                      child: Text(
                        option.parentName[0],
                        style: TextStyle(
                          color: NannyTheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          option.parentName,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${option.childName}, ${option.childAge} лет',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _matchColor(option.matchPercent).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
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
            _routeRow(Icons.circle, option.addressFrom, NannyTheme.primary, 10),
            Container(
              margin: const EdgeInsets.only(left: 4),
              height: 16,
              width: 2,
              color: Colors.grey[300],
            ),
            _routeRow(Icons.location_on, option.addressTo, Colors.red, 16),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.schedule, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'Отправление: ${option.time}',
                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
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
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          '${option.originalPrice.toStringAsFixed(0)} ₽',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[500],
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '-${option.savings.toStringAsFixed(0)} ₽',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.green,
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: NannyTheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  child: const Text(
                    'Присоединиться',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
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
