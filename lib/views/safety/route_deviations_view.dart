import 'package:flutter/material.dart';
import 'package:nanny_client/view_models/safety/route_deviations_vm.dart';
import 'package:nanny_components/nanny_components.dart';
import 'package:intl/intl.dart';

class RouteDeviationsView extends StatefulWidget {
  final int? orderId;

  const RouteDeviationsView({super.key, this.orderId});

  @override
  State<RouteDeviationsView> createState() => _RouteDeviationsViewState();
}

class _RouteDeviationsViewState extends State<RouteDeviationsView> {
  late RouteDeviationsVM vm;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    vm = RouteDeviationsVM(
      context: context,
      update: setState,
      filterOrderId: widget.orderId,
    );
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      vm.loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text(
          'История отклонений',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: FutureLoader(
        future: vm.loadRequest,
        completeView: (context, _) {
          if (vm.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (vm.error != null) {
            return _buildErrorState();
          }

          if (vm.deviations.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: vm.refresh,
            color: NannyTheme.primary,
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: vm.deviations.length + (vm.hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == vm.deviations.length) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                return _buildDeviationCard(vm.deviations[index]);
              },
            ),
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
            Icon(Icons.route, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'Отклонений не зафиксировано',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Все поездки прошли по запланированному маршруту',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            const Text(
              'Не удалось загрузить данные',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: vm.refresh,
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: const Text('Повторить', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: NannyTheme.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviationCard(RouteDeviation deviation) {
    final dateFmt = DateFormat('dd.MM.yyyy, HH:mm');
    final meters = deviation.deviationMeters.toStringAsFixed(0);
    final severity = _severity(deviation.deviationMeters);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: severity.color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.warning_amber_rounded, color: severity.color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Отклонение на $meters м',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                      Text(
                        dateFmt.format(deviation.timestamp),
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: severity.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    severity.label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: severity.color,
                    ),
                  ),
                ),
              ],
            ),
            if (deviation.description != null) ...[
              const SizedBox(height: 10),
              Text(
                deviation.description!,
                style: TextStyle(fontSize: 13, color: Colors.grey[700]),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.receipt_long, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  'Заказ #${deviation.orderId}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  _SeverityInfo _severity(double meters) {
    if (meters >= 1000) {
      return _SeverityInfo(color: Colors.red, label: 'Критичное');
    } else if (meters >= 500) {
      return _SeverityInfo(color: Colors.orange, label: 'Значительное');
    } else {
      return _SeverityInfo(color: Colors.amber[700]!, label: 'Незначительное');
    }
  }
}

class _SeverityInfo {
  final Color color;
  final String label;
  _SeverityInfo({required this.color, required this.label});
}
