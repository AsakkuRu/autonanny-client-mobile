# AutoNanny Client App — CLAUDE.md

Flutter-приложение родителя. Package: `nanny_client`, версия 0.2.90.

## Структура

```
autonanny-client-mobile-wc/
├── lib/
│   ├── main.dart                    # Инициализация, routing, back-button handler
│   ├── view_models/                 # State management (ViewModelBase)
│   │   ├── home_vm.dart
│   │   ├── new_main/                # Главный экран, активная поездка
│   │   ├── pages/                   # Страницы профиля, баланса, истории
│   │   └── map/                     # Карта, маршруты
│   └── views/
│       ├── new_main/                # Главный экран (NewHomeView), активная поездка
│       ├── pages/                   # Второстепенные экраны
│       └── reg.dart / home.dart     # Регистрация / корневой роутинг
├── nanny_core/                      # Shared API + модели
│   └── lib/
│       ├── nanny_core.dart          # Barrel-экспорт всего
│       ├── api/                     # HTTP клиенты (DioRequest, NannyUsersApi, ...)
│       ├── constants.dart           # NannyConsts (URL, ключи, buildFileUrl)
│       ├── models/                  # Dart-модели (from_api/, ...)
│       ├── map_services/            # LocationService, NannyMapUtils, RouteManager
│       └── nanny_search_delegate.dart
└── nanny_components/                # Shared UI
    └── lib/
        ├── nanny_components.dart    # Barrel-экспорт
        ├── dialogs/loading.dart     # LoadScreen
        ├── styles/                  # NDT (NannyDesignTokens), NannyTheme
        │   ├── new_design_app.dart  # NDT — основная дизайн-система
        │   └── new_design_driver.dart
        ├── widgets/
        │   ├── map/
        │   │   └── full_screen_map_address_picker.dart  # Карта-пикер адреса
        │   └── sos_button.dart
        └── base_views/
            └── view_models/view_model_base.dart
```

## Паттерн ViewModel

```dart
class MyVM extends ViewModelBase {
  MyVM({required super.context, required super.update});

  String someData = '';

  @override
  Future<bool> loadPage() async {
    final res = await NannyUsersApi.getSomeData();
    if (!res.success) return false;
    someData = res.response!.value;
    return true;
  }
}

// Использование в StatefulWidget:
class MyView extends StatefulWidget { ... }
class _MyViewState extends State<MyView> {
  late MyVM vm;

  @override
  void initState() {
    super.initState();
    vm = MyVM(context: context, update: setState);
  }

  @override
  Widget build(BuildContext context) {
    return FutureLoader(
      future: vm.loadRequest,
      completeView: (context, _) => /* UI с vm.someData */,
    );
  }
}
```

## Паттерн API-запроса

```dart
// В nanny_core/lib/api/nanny_users_api.dart
static Future<ApiResponse<MyModel>> getMyData() async {
  return RequestBuilder<MyModel>().create(
    dioRequest: DioRequest.dio.get("/users/my_endpoint"),
    onSuccess: (response) => MyModel.fromJson(response.data),
  );
}

// Использование:
final res = await NannyUsersApi.getMyData();
if (res.success && res.response != null) {
  final data = res.response!;
}
```

## Ключевые экраны и VM

| Экран | VM | Назначение |
|-------|----|-----------|
| `new_main/new_home_view.dart` | `home_vm.dart` | Корневой экран с TabBar |
| `new_main/new_client_main_panel.dart` | `new_client_main_vm.dart` | Главная: выбор адресов, тариф, поиск водителя |
| `new_main/active_trip/active_trip_screen.dart` | `active_trip_vm.dart` | Активная поездка, WebSocket |
| `pages/balance.dart` | — | Баланс и история операций |
| `pages/children_list.dart` | — | Список детей |
| `pages/graph_create.dart` | — | Создание расписания |
| `new_main/profile/client_profile_v2_view.dart` | — | Профиль клиента |

## Общие утилиты (nanny_core)

```dart
// URL для файлов/фото
NannyConsts.buildFileUrl(photoPath)  // null если path пустой, http as-is, иначе "$domen/files/$path"

// Адреса
NannyMapUtils.simplifyAddress(fullAddress)    // укорачивает адрес для показа
NannyMapUtils.buildStreetAddress(geocodeResult)  // строит читаемый адрес из GeocodeResult
NannyMapUtils.filterGeocodeData(response)     // фильтрует reverse geocoding

// Поиск адреса
showSearch<GeocodeResult?>(
  context: context,
  delegate: NannySearchDelegate(
    onSearch: (q) => GoogleMapApi.geocode(address: q),
    onResponse: (r) => r.response?.geocodeResults,
    tileBuilder: (data, close) => ListTile(
      title: Text(NannyMapUtils.buildStreetAddress(data)),
      onTap: close,
    ),
  ),
)

// Полноэкранный пикер адреса на карте
Navigator.push<AddressData>(context, MaterialPageRoute(
  builder: (_) => const FullScreenMapAddressPicker(),
))
```

## Дизайн-система (NDT)

Все стили берутся из `NDT` (`nanny_components/lib/styles/new_design_app.dart`):

```dart
// Типографика
NDT.h1, NDT.h2, NDT.h3
NDT.bodyL, NDT.bodyM, NDT.bodyS
NDT.labelM, NDT.sectionCaption

// Цвета
NDT.primary, NDT.primary100
NDT.neutral0 (белый), NDT.neutral100...NDT.neutral900 (чёрный)
NDT.danger

// Скругления
NDT.brFull, NDT.brXl, NDT.brLg, NDT.brMd

// Отступы (spacing)
NDT.sp2, NDT.sp4, NDT.sp8, NDT.sp10, NDT.sp12, NDT.sp14, NDT.sp16, NDT.sp20, NDT.sp24

// Декоратор карточки
NDT.cardDecoration

// Градиент кнопки
NDT.ctaGradient
```

Кнопки и диалоги:
```dart
NdPrimaryButton(label: 'Текст', onTap: () {})
NannyDialogs.showMessageBox(context, 'Заголовок', 'Сообщение')
NannyDialogs.confirmAction(context, 'Вы уверены?', confirmText: 'Да', cancelText: 'Нет')
LoadScreen.showLoad(context, true/false)  // показать/скрыть спиннер
```

## Навигация

```dart
// Обычный переход
Navigator.push(context, MaterialPageRoute(builder: (_) => SomeView()))
Navigator.pop(context)  // или с результатом: Navigator.pop(context, result)

// Из ViewModel (унаследованы от ViewModelBase):
vm.navigateToView(SomeView())
vm.slideNavigateToView(SomeView())
vm.popView()
```

## Активная поездка — WebSocket

`ActiveTripVM` слушает WebSocket через `DriveSearchSocket(token)`. Статусы:
- `2` → Водитель отменил (clear session, statusText = 'Водитель отменил поездку')
- `3` → Клиент отменил (clear session)
- `11` → Поездка завершена (clear session)
- `13/5` → Водитель едет
- `6/7` → Водитель прибыл
- `14/15` → Поездка началась (закрыть QR-диалог через `onTripStarted`)

## Импорты — быстрая шпаргалка

```dart
// Всё из nanny_core (NannyMapUtils, NannySearchDelegate, NannyConsts, DioRequest, ...)
import 'package:nanny_core/nanny_core.dart';

// Конкретные модели (если нужно явно)
import 'package:nanny_core/models/from_api/drive_and_map/address_data.dart';
import 'package:nanny_core/models/from_api/drive_and_map/geocoding_data.dart';
import 'package:nanny_core/api/google_map_api.dart';

// Всё из nanny_components (NDT, NdPrimaryButton, FutureLoader, NannyDialogs, ...)
import 'package:nanny_components/nanny_components.dart';
import 'package:nanny_components/styles/new_design_app.dart';  // NDT

// Пикер адреса на карте
import 'package:nanny_components/widgets/map/full_screen_map_address_picker.dart';

// LoadScreen
import 'package:nanny_components/dialogs/loading.dart';
```
