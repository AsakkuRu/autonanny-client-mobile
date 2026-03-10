import 'package:nanny_components/nanny_components.dart';
import 'package:nanny_core/api/nanny_orders_api.dart';
import 'package:nanny_core/models/from_api/drive_and_map/route_deviation.dart';

export 'package:nanny_core/models/from_api/drive_and_map/route_deviation.dart';

class RouteDeviationsVM extends ViewModelBase {
  RouteDeviationsVM({
    required super.context,
    required super.update,
    this.filterOrderId,
  });

  final int? filterOrderId;

  List<RouteDeviation> deviations = [];
  bool isLoading = false;
  String? error;
  int _offset = 0;
  static const int _pageSize = 20;
  bool hasMore = true;

  @override
  Future<bool> loadPage() async {
    _offset = 0;
    hasMore = true;
    update(() {
      isLoading = true;
      error = null;
      deviations = [];
    });

    final result = await NannyOrdersApi.getRouteDeviations(
      orderId: filterOrderId,
      offset: 0,
      limit: _pageSize,
    );

    if (result.success && result.response != null) {
      update(() {
        deviations = result.response!.deviations;
        hasMore = deviations.length == _pageSize;
        _offset = deviations.length;
        isLoading = false;
      });
    } else {
      // Mock-first: показываем мок если API недоступен
      update(() {
        deviations = _generateMockDeviations();
        hasMore = false;
        isLoading = false;
      });
    }

    return true;
  }

  Future<void> loadMore() async {
    if (!hasMore || isLoading) return;

    final result = await NannyOrdersApi.getRouteDeviations(
      orderId: filterOrderId,
      offset: _offset,
      limit: _pageSize,
    );

    if (result.success && result.response != null) {
      final newItems = result.response!.deviations;
      update(() {
        deviations.addAll(newItems);
        hasMore = newItems.length == _pageSize;
        _offset += newItems.length;
      });
    }
  }

  Future<void> refresh() => loadPage();

  List<RouteDeviation> _generateMockDeviations() {
    final now = DateTime.now();
    return [
      RouteDeviation(
        id: 1,
        orderId: 101,
        driverId: 55,
        deviationMeters: 750,
        timestamp: now.subtract(const Duration(hours: 2, minutes: 30)),
        driverLat: 55.7558,
        driverLon: 37.6173,
        expectedLat: 55.7560,
        expectedLon: 37.6180,
        description: 'Водитель отклонился от маршрута на 750 м',
      ),
      RouteDeviation(
        id: 2,
        orderId: 98,
        driverId: 55,
        deviationMeters: 520,
        timestamp: now.subtract(const Duration(days: 1, hours: 1)),
        driverLat: 55.7610,
        driverLon: 37.6290,
        expectedLat: 55.7620,
        expectedLon: 37.6250,
        description: 'Водитель отклонился от маршрута на 520 м',
      ),
    ];
  }
}
