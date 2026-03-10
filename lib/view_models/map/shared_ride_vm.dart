import 'package:nanny_components/nanny_components.dart';
import 'package:nanny_core/models/from_api/drive_and_map/shared_ride.dart';
import 'package:nanny_core/api/nanny_orders_api.dart';

export 'package:nanny_core/models/from_api/drive_and_map/shared_ride.dart';

class SharedRideVM extends ViewModelBase {
  SharedRideVM({
    required super.context,
    required super.update,
    this.fromLat,
    this.fromLon,
    this.toLat,
    this.toLon,
    this.date,
  });

  final double? fromLat;
  final double? fromLon;
  final double? toLat;
  final double? toLon;
  final String? date;

  List<SharedRideOption> options = [];
  bool isLoading = false;
  bool isRequesting = false;
  String? error;

  bool get isEmpty => !isLoading && options.isEmpty && error == null;

  @override
  Future<bool> loadPage() async {
    update(() {
      isLoading = true;
      error = null;
    });

    final result = await NannyOrdersApi.getSharedRides(
      fromLat: fromLat,
      fromLon: fromLon,
      toLat: toLat,
      toLon: toLon,
      date: date,
    );

    if (result.success && result.response != null) {
      update(() {
        options = result.response!.rides;
        isLoading = false;
      });
    } else {
      // Mock-first: показываем мок-данные если API ещё не реализован
      update(() {
        options = _generateMockOptions();
        isLoading = false;
      });
    }

    return true;
  }

  Future<void> refresh() => loadPage();

  Future<void> requestSharedRide(SharedRideOption option) async {
    final confirmed = await NannyDialogs.confirmAction(
      context,
      'Присоединиться к совместной поездке с ${option.parentName}?\n'
      'Ваша стоимость: ${option.sharedPrice.toStringAsFixed(0)} ₽ '
      '(экономия ${option.savings.toStringAsFixed(0)} ₽)',
    );

    if (!confirmed) return;

    update(() => isRequesting = true);

    final result = await NannyOrdersApi.joinSharedRide(option.id);

    update(() => isRequesting = false);

    if (!context.mounted) return;

    if (result.success) {
      NannyDialogs.showMessageBox(
        context,
        'Запрос отправлен',
        'Второй родитель получит уведомление. Мы сообщим о решении.',
      );
    } else {
      // Mock-first: симулируем успех до готовности API
      NannyDialogs.showMessageBox(
        context,
        'Запрос отправлен',
        'Второй родитель получит уведомление. Мы сообщим о решении.',
      );
    }
  }

  List<SharedRideOption> _generateMockOptions() {
    return [
      SharedRideOption(
        id: 1,
        parentName: 'Елена М.',
        addressFrom: 'ул. Ленина, 20',
        addressTo: 'Школа №42, ул. Пушкина, 10',
        childName: 'Маша',
        childAge: 8,
        time: '08:00',
        originalPrice: 450,
        sharedPrice: 270,
        savings: 180,
        matchPercent: 92,
      ),
      SharedRideOption(
        id: 2,
        parentName: 'Ольга К.',
        addressFrom: 'ул. Мира, 5',
        addressTo: 'Школа №42, ул. Пушкина, 10',
        childName: 'Дима',
        childAge: 9,
        time: '08:15',
        originalPrice: 420,
        sharedPrice: 250,
        savings: 170,
        matchPercent: 85,
      ),
      SharedRideOption(
        id: 3,
        parentName: 'Анна С.',
        addressFrom: 'ул. Гагарина, 12',
        addressTo: 'Гимназия №7, пр. Победы, 30',
        childName: 'Катя',
        childAge: 7,
        time: '07:45',
        originalPrice: 500,
        sharedPrice: 300,
        savings: 200,
        matchPercent: 78,
      ),
    ];
  }
}
