import 'package:nanny_components/nanny_components.dart';

class SharedRideOption {
  final int id;
  final String parentName;
  final String addressFrom;
  final String addressTo;
  final String childName;
  final int childAge;
  final String time;
  final double originalPrice;
  final double sharedPrice;
  final double savings;
  final int matchPercent;

  const SharedRideOption({
    required this.id,
    required this.parentName,
    required this.addressFrom,
    required this.addressTo,
    required this.childName,
    required this.childAge,
    required this.time,
    required this.originalPrice,
    required this.sharedPrice,
    required this.savings,
    required this.matchPercent,
  });
}

class SharedRideVM extends ViewModelBase {
  SharedRideVM({
    required super.context,
    required super.update,
  });

  List<SharedRideOption> options = [];
  bool isLoading = true;
  bool isRequesting = false;

  @override
  Future<bool> loadPage() async {
    update(() => isLoading = true);

    // TODO: Replace with API call when backend is ready
    // final result = await NannyOrdersApi.getSharedRideOptions();
    await Future.delayed(const Duration(milliseconds: 800));
    options = _generateMockOptions();

    update(() => isLoading = false);
    return true;
  }

  Future<void> requestSharedRide(SharedRideOption option) async {
    final confirmed = await NannyDialogs.confirmAction(
      context,
      'Присоединиться к совместной поездке с ${option.parentName}?\n'
      'Ваша стоимость: ${option.sharedPrice.toStringAsFixed(0)} ₽ '
      '(экономия ${option.savings.toStringAsFixed(0)} ₽)',
    );

    if (!confirmed) return;

    update(() => isRequesting = true);

    // TODO: Replace with API call
    await Future.delayed(const Duration(seconds: 1));

    update(() => isRequesting = false);

    if (!context.mounted) return;
    NannyDialogs.showMessageBox(
      context,
      'Запрос отправлен',
      'Второй родитель получит уведомление. Мы сообщим о решении.',
    );
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
