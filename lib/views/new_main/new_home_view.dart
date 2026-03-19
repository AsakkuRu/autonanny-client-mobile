import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nanny_client/view_models/home_vm.dart';
import 'package:nanny_client/view_models/new_main/active_trip/active_trip_session_store.dart';
import 'package:nanny_client/views/new_main/active_trip/active_trip_screen.dart';
import 'package:nanny_client/views/new_main/new_client_map_view.dart';
import 'package:nanny_client/views/new_main/profile/client_profile_v2_view.dart';
import 'package:nanny_client/views/pages/balance.dart';
import 'package:nanny_client/views/pages/graph.dart';
import 'package:nanny_client/views/reg.dart';
import 'package:nanny_components/nanny_components.dart';
import 'package:nanny_components/styles/new_design_app.dart';
import 'package:nanny_core/api/nanny_orders_api.dart';
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

class _NewHomeViewState extends State<NewHomeView>
    with WidgetsBindingObserver {
  late HomeVM vm;
  late List<Widget> pages;

  bool _hasActiveTrip = false;
  String? _activeToken;
  Timer? _pollTimer;
  StreamSubscription? _chatSocketSub;

  @override
  void initState() {
    super.initState();
    vm = HomeVM(
      context: context,
      update: setState,
      onChatSocketReady: subscribeToChatSocketAfterInit,
    );
    pages = [
      const NewClientMapView(),
      const GraphView(persistState: true),
      const BalanceView(persistState: true),
      ChatsView(
        persistState: false,
        onReturnFromChat: () => vm.refreshUnreadChatsCount(),
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

  // Вызывается из HomeVM после того, как initChatSocket() завершился
  // и NannyGlobals.chatsSocket гарантированно подключён.
  void subscribeToChatSocketAfterInit() {
    _chatSocketSub?.cancel();
    _chatSocketSub = NannyGlobals.chatsSocket.stream.listen((data) {
      try {
        final json = jsonDecode(data);
        if (json is Map<String, dynamic> && json['event'] == 'trip_started') {
          final token = json['token'];
          if (token is String && token.isNotEmpty && mounted) {
            setState(() { _hasActiveTrip = true; _activeToken = token; });
          } else {
            _checkActiveTrip();
          }
        }
      } catch (_) {}
    });
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!_hasActiveTrip) _checkActiveTrip();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _checkActiveTrip();
  }

  Future<void> _checkActiveTrip() async {
    if (!mounted) return;
    try {
      final cached = await ActiveTripSessionStore.load();
      if (cached != null && cached.token.isNotEmpty) {
        if (mounted) setState(() { _hasActiveTrip = true; _activeToken = cached.token; });
        return;
      }
      final res = await NannyOrdersApi.getCurrentOrder();
      if (!mounted) return;
      if (res.success && res.response != null) {
        // Ответ бэкенда: {status, message, data: {orders: [...]}}
        // res.response — Dio Response, .data — декодированное тело JSON
        final body = res.response!.data;
        final nested = body is Map ? body['data'] : null;
        final orders = nested is Map ? nested['orders'] : null;
        if (orders is List) {
          for (final rawOrder in orders) {
            if (rawOrder is! Map) continue;
            final status = rawOrder['id_status'];
            final statusId = status is num ? status.toInt() : int.tryParse('$status');
            final orderToken = rawOrder['token'];
            if (statusId == null || statusId == 2 || statusId == 3 || statusId == 11) continue;
            if (orderToken is String && orderToken.isNotEmpty) {
              if (mounted) setState(() { _hasActiveTrip = true; _activeToken = orderToken; });
              return;
            }
          }
        }
      }
      if (mounted) setState(() { _hasActiveTrip = false; _activeToken = null; });
    } catch (e, st) {
      debugPrint('[ActiveTrip] _checkActiveTrip error: $e\n$st');
    }
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
    _chatSocketSub?.cancel();
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
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ));

    return PopScope(
      // На вкладке "Главная" (0) разрешаем стандартный pop (выход из приложения).
      // На любой другой вкладке перехватываем "Назад" и идём на вкладку 0.
      canPop: vm.currentIndex == 0,
      onPopInvoked: (didPop) {
        if (!didPop) {
          _onTabTap(context, 0);
        }
      },
      child: Scaffold(
        backgroundColor: NDT.screenBg,
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
                child: _ActiveTripBanner(onTap: _openActiveTrip),
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
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: NDT.sheetBg.withOpacity(0.97),
            border: Border(
              top: BorderSide(color: NDT.neutral200, width: 0.5),
            ),
          ),
          padding: EdgeInsets.fromLTRB(
            NDT.sp8,
            NDT.sp8,
            NDT.sp8,
            MediaQuery.of(context).padding.bottom + NDT.sp8,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _NavItem(
                label: 'Главная',
                icon: Icons.directions_car_filled_rounded,
                index: 0,
                currentIndex: currentIndex,
                onTap: onTap,
              ),
              _NavItem(
                label: 'Расписание',
                icon: Icons.calendar_month_rounded,
                index: 1,
                currentIndex: currentIndex,
                onTap: onTap,
              ),
              _NavItem(
                label: 'Баланс',
                icon: Icons.wallet_rounded,
                index: 2,
                currentIndex: currentIndex,
                onTap: onTap,
              ),
              _NavItem(
                label: 'Чаты',
                icon: Icons.chat_rounded,
                index: 3,
                currentIndex: currentIndex,
                onTap: onTap,
                badgeCount: unreadChatsCount,
              ),
              _NavItem(
                label: 'Профиль',
                icon: Icons.account_circle_rounded,
                index: 4,
                currentIndex: currentIndex,
                onTap: onTap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final int index;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final int badgeCount;

  const _NavItem({
    required this.label,
    required this.icon,
    required this.index,
    required this.currentIndex,
    required this.onTap,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = currentIndex == index;
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 58,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isActive ? NDT.primary100 : Colors.transparent,
                    borderRadius: NDT.brMd,
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: isActive ? NDT.primary : NDT.neutral400,
                  ),
                ),
                if (badgeCount > 0)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 3,
                        vertical: 1,
                      ),
                      decoration: const BoxDecoration(
                        color: NDT.danger,
                        borderRadius: NDT.brFull,
                      ),
                      child: Text(
                        badgeCount > 99 ? '99+' : '$badgeCount',
                        style: NDT.caption.copyWith(
                          color: NDT.neutral0,
                          fontSize: 8,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                style: NDT.caption.copyWith(
                  color: isActive ? NDT.primary : NDT.neutral400,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Баннер активной поездки ─────────────────────────────────────────────────

class _ActiveTripBanner extends StatelessWidget {
  final VoidCallback onTap;

  const _ActiveTripBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: NDT.ctaGradient,
          borderRadius: NDT.brFull,
          boxShadow: NDT.cardShadow,
        ),
        child: Row(
          children: [
            const Icon(
              Icons.directions_car_rounded,
              size: 16,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Поездка в процессе',
                style: NDT.labelM.copyWith(color: Colors.white),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 12,
              color: Colors.white70,
            ),
          ],
        ),
      ),
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
