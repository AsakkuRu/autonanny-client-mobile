import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nanny_client/ui_sdk/client_ui_sdk.dart';
import 'package:nanny_client/view_models/home_vm.dart';
import 'package:nanny_client/view_models/new_main/active_trip/active_trip_session_store.dart';
import 'package:nanny_client/views/new_main/active_trip/active_trip_screen.dart';
import 'package:nanny_client/views/new_main/new_client_map_view.dart';
import 'package:nanny_client/views/new_main/profile/client_profile_v2_view.dart';
import 'package:nanny_client/views/pages/balance.dart';
import 'package:nanny_client/views/pages/contracts_view.dart';
import 'package:nanny_client/views/rating/driver_rating_details_view.dart';
import 'package:nanny_client/views/reg.dart';
import 'package:nanny_components/base_views/views/pages/chats.dart';
import 'package:nanny_components/base_views/views/welcome.dart';
import 'package:nanny_core/api/nanny_orders_api.dart';
import 'package:nanny_core/api/web_sockets/unified_socket.dart';
import 'package:nanny_core/nanny_core.dart';

/// Новый корневой экран клиента.
/// Заменяет [HomeView] при включённом [NannyFeatureFlags.useNewHomeView].
/// Переиспользует [HomeVM] для логики подсчёта непрочитанных чатов.
/// Вкладки 1–4 пока используют прежние страницы, чтобы не ломать функционал.
class NewHomeView extends StatefulWidget {
  const NewHomeView({super.key});

  @override
  State<NewHomeView> createState() => _NewHomeViewState();
}

class _NewHomeViewState extends State<NewHomeView> with WidgetsBindingObserver {
  late HomeVM vm;
  late List<Widget> pages;

  bool _hasActiveTrip = false;
  String? _activeToken;
  ActiveTripBannerData? _activeTripBannerData;
  Timer? _pollTimer;
  StreamSubscription<Map<String, dynamic>>? _realtimeTripSub;
  static const Set<String> _activeTripInvalidationEvents = {
    'connected',
    'order.expired',
    'trip.assigned',
    'trip.status_changed',
    'trip.cancelled',
  };

  @override
  void initState() {
    super.initState();
    vm = HomeVM(
      context: context,
      update: setState,
      onRealtimeReady: subscribeToRealtimeAfterInit,
    );
    pages = [
      const NewClientMapView(),
      const ContractsView(persistState: true),
      const BalanceView(persistState: true),
      ChatsView(
        persistState: false,
        onReturnFromChat: () => vm.refreshUnreadChatsCount(),
        buildDriverRatingView: (driverId) =>
            DriverRatingDetailsView(driverId: driverId),
      ),
      _NewProfileView(
        logoutView: WelcomeView(
          regView: const RegView(),
          loginPaths: NannyConsts.availablePaths,
        ),
      ),
    ];
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkActiveTrip();
      _startPolling();
    });
  }

  // Вызывается из HomeVM после инициализации UnifiedSocket.
  void subscribeToRealtimeAfterInit() async {
    _realtimeTripSub?.cancel();
    try {
      final socket = UnifiedSocket.instance ?? await UnifiedSocket.connect();
      _realtimeTripSub = socket.events.listen((msg) {
        final event = msg['event']?.toString();
        if (event == null || !_activeTripInvalidationEvents.contains(event)) {
          return;
        }
        _handleActiveTripInvalidation(msg);
      });
    } catch (e, st) {
      debugPrint('[ActiveTrip] subscribeToRealtimeAfterInit error: $e\n$st');
    }
  }

  void _handleActiveTripInvalidation(Map<String, dynamic> msg) {
    if (!mounted) return;

    final data = msg['data'];
    final token = data is Map ? data['token'] : null;
    if (token is String && token.isNotEmpty) {
      setState(() {
        _hasActiveTrip = true;
        _activeToken = token;
        _activeTripBannerData ??= const ActiveTripBannerData(
          title: 'Активная поездка',
          subtitle: 'Открыть экран активной поездки',
        );
      });
      _checkActiveTrip();
      return;
    }

    _checkActiveTrip();
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!_hasActiveTrip) _checkActiveTrip();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkActiveTrip();
    }
  }

  Future<void> _checkActiveTrip() async {
    if (!mounted) return;
    try {
      final cached = await ActiveTripSessionStore.load();
      final res = await NannyOrdersApi.getCurrentOrder();
      if (res.success && res.response != null) {
        final body = res.response!.data;
        final activeOrder = _selectActiveOrder(
          body is Map ? body['orders'] : null,
          preferredToken: cached?.token,
          preferredOrderId: cached?.orderId,
        );
        if (activeOrder != null) {
          final orderToken = activeOrder['token']?.toString();
          if (orderToken != null && orderToken.isNotEmpty) {
            final resolvedStatusId = _preferMoreSpecificStatus(
              _toInt(activeOrder['id_status']),
              cached?.statusId,
            );
            await ActiveTripSessionStore.save(
              ActiveTripSessionData(
                token: orderToken,
                orderId: _toInt(activeOrder['id_order']),
                statusId: resolvedStatusId,
                chatId: _toInt(activeOrder['id_chat']),
              ),
            );
            if (!mounted) return;
            setState(() {
              _hasActiveTrip = true;
              _activeToken = orderToken;
              _activeTripBannerData = _buildActiveTripBannerData(
                activeOrder,
                cachedStatusId: cached?.statusId,
              );
            });
            return;
          }
        }
        await ActiveTripSessionStore.clear();
        if (!mounted) return;
        setState(() {
          _hasActiveTrip = false;
          _activeToken = null;
          _activeTripBannerData = null;
        });
        return;
      }

      if (cached != null && cached.token.isNotEmpty) {
        if (!mounted) return;
        setState(() {
          _hasActiveTrip = true;
          _activeToken = cached.token;
          _activeTripBannerData ??= const ActiveTripBannerData(
            title: 'Активная поездка',
            subtitle: 'Открыть экран активной поездки',
          );
        });
        return;
      }

      if (mounted) {
        setState(() {
          _hasActiveTrip = false;
          _activeToken = null;
          _activeTripBannerData = null;
        });
      }
    } catch (e, st) {
      debugPrint('[ActiveTrip] _checkActiveTrip error: $e\n$st');
    }
  }

  ActiveTripBannerData _buildActiveTripBannerData(
    Map<String, dynamic> activeOrder,
    {
    int? cachedStatusId,
  }) {
    final statusId = _preferMoreSpecificStatus(
      _toInt(activeOrder['id_status']),
      cachedStatusId,
    );
    final driver = activeOrder['driver'];
    final driverMap = driver is Map ? Map<String, dynamic>.from(driver) : null;
    final driverName = _driverName(driverMap);

    return ActiveTripBannerData(
      title: _activeTripTitle(statusId),
      subtitle: driverName.isNotEmpty
          ? '$driverName · открыть экран поездки'
          : _activeTripSubtitle(statusId),
      avatarImageUrl: driverMap?['photo']?.toString(),
      avatarInitials: _driverInitials(driverMap),
    );
  }

  int? _preferMoreSpecificStatus(int? apiStatusId, int? cachedStatusId) {
    if (apiStatusId == null) return cachedStatusId;
    if (cachedStatusId == null) return apiStatusId;

    return _statusProgressRank(cachedStatusId) > _statusProgressRank(apiStatusId)
        ? cachedStatusId
        : apiStatusId;
  }

  int _statusProgressRank(int? statusId) {
    return switch (statusId) {
      4 => 1,
      13 || 5 => 2,
      7 => 3,
      6 => 4,
      14 => 5,
      15 => 6,
      _ => 0,
    };
  }

  String _activeTripTitle(int? statusId) {
    return switch (statusId) {
      13 || 5 => 'Водитель едет к вам',
      6 || 7 => 'Водитель уже ожидает',
      14 || 15 => 'Поездка в процессе',
      4 || null => 'Ищем водителя',
      _ => 'Активная поездка',
    };
  }

  String _activeTripSubtitle(int? statusId) {
    return switch (statusId) {
      4 || null => 'Подбираем подходящего водителя для поездки',
      _ => 'Открыть экран активной поездки',
    };
  }

  String _driverName(Map<String, dynamic>? driver) {
    if (driver == null) return '';
    final surname = (driver['surname'] ?? '').toString().trim();
    final name = (driver['name'] ?? '').toString().trim();
    return [surname, name].where((part) => part.isNotEmpty).join(' ').trim();
  }

  String _driverInitials(Map<String, dynamic>? driver) {
    if (driver == null) return 'A';
    final surname = (driver['surname'] ?? '').toString().trim();
    final name = (driver['name'] ?? '').toString().trim();
    final first = surname.isNotEmpty ? surname.substring(0, 1) : '';
    final second = name.isNotEmpty ? name.substring(0, 1) : '';
    final initials = '$first$second'.toUpperCase();
    return initials.isEmpty ? 'A' : initials;
  }

  Map<String, dynamic>? _selectActiveOrder(
    dynamic rawOrders, {
    String? preferredToken,
    int? preferredOrderId,
  }) {
    if (rawOrders is! List) return null;

    final activeOrders = rawOrders.whereType<Map>().map((raw) {
      return Map<String, dynamic>.from(raw);
    }).where((order) {
      final statusId = _toInt(order['id_status']);
      return statusId != null &&
          statusId != 2 &&
          statusId != 3 &&
          statusId != 11;
    }).toList(growable: false);

    if (activeOrders.isEmpty) return null;

    if (preferredOrderId != null) {
      for (final order in activeOrders) {
        if (_toInt(order['id_order']) == preferredOrderId) return order;
      }
    }

    if (preferredToken != null && preferredToken.isNotEmpty) {
      for (final order in activeOrders) {
        final orderToken = order['token']?.toString();
        if (orderToken != null &&
            orderToken.isNotEmpty &&
            orderToken == preferredToken) {
          return order;
        }
      }
    }

    return activeOrders.first;
  }

  int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  Future<void> _openActiveTrip() async {
    final token = _activeToken;
    if (token == null || token.isEmpty) return;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ActiveTripScreen(token: token)),
    );
    _checkActiveTrip();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _realtimeTripSub?.cancel();
    vm.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _onTabTap(BuildContext context, int index) {
    vm.indexChanged(index);
    if (index == 1) {
      NannyGlobals.scheduleTabSelectedController.add(null);
    }
    if (index == 0) {
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
      );
    } else {
      SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
        statusBarColor: Theme.of(context).scaffoldBackgroundColor,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
    ));

    return PopScope(
      // На вкладке "Главная" (0) разрешаем стандартный pop (выход из приложения).
      // На любой другой вкладке перехватываем "Назад" и идём на вкладку 0.
      canPop: vm.currentIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _onTabTap(context, 0);
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Stack(
          children: [
            IndexedStack(
              index: vm.currentIndex,
              children: pages,
            ),
            if (_hasActiveTrip)
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                left: 16,
                right: 16,
                child: _ActiveTripBanner(
                  data: _activeTripBannerData ??
                      const ActiveTripBannerData(
                        title: 'Активная поездка',
                        subtitle: 'Открыть экран активной поездки',
                      ),
                  onTap: _openActiveTrip,
                ),
              ),
          ],
        ),
        bottomNavigationBar: _NewBottomNavBar(
          currentIndex: vm.currentIndex,
          unreadChatsCount: vm.unreadChatsCount,
          onTap: (index) => _onTabTap(context, index),
        ),
      ),
    );
  }
}

// ─── Нижняя навигация ────────────────────────────────────────────────────────

class _NewBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final int unreadChatsCount;
  final ValueChanged<int> onTap;

  const _NewBottomNavBar({
    required this.currentIndex,
    required this.unreadChatsCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AutonannyBottomNav(
      currentIndex: currentIndex,
      onTap: onTap,
      items: const [
        AutonannyBottomNavItem(
          label: 'Главная',
          icon: AutonannyIcon(AutonannyIcons.home),
          activeIcon: AutonannyIcon(AutonannyIcons.home),
        ),
        AutonannyBottomNavItem(
          label: 'Расписание',
          icon: AutonannyIcon(AutonannyIcons.calendar),
          activeIcon: AutonannyIcon(AutonannyIcons.calendar),
        ),
        AutonannyBottomNavItem(
          label: 'Баланс',
          icon: AutonannyIcon(AutonannyIcons.wallet),
          activeIcon: AutonannyIcon(AutonannyIcons.wallet),
        ),
        AutonannyBottomNavItem(
          label: 'Чаты',
          icon: AutonannyIcon(AutonannyIcons.chat),
          activeIcon: AutonannyIcon(AutonannyIcons.chat),
        ),
        AutonannyBottomNavItem(
          label: 'Профиль',
          icon: AutonannyIcon(AutonannyIcons.profile),
          activeIcon: AutonannyIcon(AutonannyIcons.profile),
        ),
      ].map((item) {
        if (item.label != 'Чаты') return item;
        return AutonannyBottomNavItem(
          label: item.label,
          icon: item.icon,
          activeIcon: item.activeIcon,
          badgeCount: unreadChatsCount,
        );
      }).toList(growable: false),
    );
  }
}

class _ActiveTripBanner extends StatelessWidget {
  final ActiveTripBannerData data;
  final VoidCallback onTap;

  const _ActiveTripBanner({required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ActiveTripBanner(
      data: data,
      onTap: onTap,
    );
  }
}

// ─── Страница профиля ────────────────────────────────────────────────────────

class _NewProfileView extends StatelessWidget {
  final Widget logoutView;

  const _NewProfileView({required this.logoutView});

  @override
  Widget build(BuildContext context) {
    return ClientProfileV2View(
      logoutView: logoutView,
    );
  }
}
