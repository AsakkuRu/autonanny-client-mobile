import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nanny_client/view_models/home_vm.dart';
import 'package:nanny_client/views/pages/map.dart';
import 'package:nanny_client/views/pages/balance.dart';
import 'package:nanny_client/views/pages/graph.dart';
import 'package:nanny_client/views/pages/children_list.dart';
import 'package:nanny_client/views/history/trip_history_view.dart';
import 'package:nanny_client/views/support/support_chat_view.dart';
import 'package:nanny_client/views/support/complaint_view.dart';
import 'package:nanny_client/views/history/trip_export_view.dart';
import 'package:nanny_client/views/history/spending_analytics_view.dart';
import 'package:nanny_client/views/support/faq_view.dart';
import 'package:nanny_client/views/referral/referral_view.dart';
import 'package:nanny_client/views/map/shared_ride_view.dart';
import 'package:nanny_client/views/reg.dart';
import 'package:nanny_client/main.dart' show themeNotifier, localeNotifier;
import 'package:nanny_components/nanny_components.dart';
import 'package:nanny_components/base_views/view_models/pages/profile_vm.dart';
import 'package:nanny_core/nanny_core.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  late HomeVM vm;
  late List<Widget> pages;

  @override
  void initState() {
    super.initState();
    vm = HomeVM(context: context, update: setState);
    pages = [
      const ClientMapView(persistState: true),
      const GraphView(persistState: true),
      const BalanceView(persistState: true),
      ChatsView(
          persistState: false,
          onReturnFromChat: () => vm.refreshUnreadChatsCount()),
      _ClientProfileView(
        persistState: true,
        logoutView: WelcomeView(
          regView: const RegView(),
          loginPaths: NannyConsts.availablePaths,
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
        statusBarColor: Theme.of(context).scaffoldBackgroundColor));
    return DefaultTabController(
      initialIndex: 0,
      length: pages.length,
      child: Builder(builder: (context) {
        final controller = DefaultTabController.of(context);
        return Scaffold(
          body: TabBarView(
            physics: const NeverScrollableScrollPhysics(),
            children: pages,
          ),
          bottomNavigationBar: _ClientBottomNavBar(
            currentIndex: vm.currentIndex,
            unreadChatsCount: vm.unreadChatsCount,
            onTap: (index) {
              vm.indexChanged(index);
              controller.index = index;
              if (index == 1) {
                NannyGlobals.scheduleTabSelectedController.add(null);
              }
              if (index == 0) {
                Future.delayed(
                  const Duration(milliseconds: 100),
                  () => _setTransparentStatusBar(),
                );
              } else {
                SystemChrome.setSystemUIOverlayStyle(
                  SystemUiOverlayStyle(
                    statusBarColor: Theme.of(context).scaffoldBackgroundColor,
                    statusBarIconBrightness: Brightness.dark,
                    statusBarBrightness: Brightness.light,
                  ),
                );
              }
            },
          ),
        );
      }),
    );
  }

  Future _setTransparentStatusBar() async {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent, // Прозрачный статус бар
        statusBarIconBrightness: Brightness.dark, // Темные иконки
        statusBarBrightness: Brightness.light, // Для iOS (светлый статус бар)
      ),
    );
  }

  @override
  void dispose() {
    vm.dispose();
    super.dispose();
  }
}

class _ClientBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final int unreadChatsCount;
  final ValueChanged<int> onTap;

  const _ClientBottomNavBar({
    required this.currentIndex,
    required this.unreadChatsCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;
    final borderColor = Theme.of(context).dividerColor;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: 83,
          decoration: BoxDecoration(
            color: surface.withOpacity(0.97),
            border: Border(
              top: BorderSide(color: borderColor, width: 0.5),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _NavItem(
                label: "Главная",
                icon: Icons.directions_car_filled_rounded,
                index: 0,
                isActive: currentIndex == 0,
                onTap: onTap,
              ),
              _NavItem(
                label: "Расписание",
                icon: Icons.calendar_month_rounded,
                index: 1,
                isActive: currentIndex == 1,
                onTap: onTap,
              ),
              _NavItem(
                label: "Баланс",
                icon: Icons.wallet_rounded,
                index: 2,
                isActive: currentIndex == 2,
                onTap: onTap,
              ),
              _NavItem(
                label: "Чаты",
                icon: Icons.chat_rounded,
                index: 3,
                isActive: currentIndex == 3,
                onTap: onTap,
                badgeText: unreadChatsCount > 0
                    ? (unreadChatsCount > 99 ? '99+' : '$unreadChatsCount')
                    : null,
              ),
              _NavItem(
                label: "Профиль",
                icon: Icons.account_circle_rounded,
                index: 4,
                isActive: currentIndex == 4,
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
  final bool isActive;
  final ValueChanged<int> onTap;
  final String? badgeText;

  const _NavItem({
    required this.label,
    required this.icon,
    required this.index,
    required this.isActive,
    required this.onTap,
    this.badgeText,
  });

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final color = isActive ? NannyTheme.primary : onSurface.withOpacity(0.6);

    Widget iconWidget = Icon(icon, size: 24, color: color);
    if (badgeText != null) {
      iconWidget = Badge(
        isLabelVisible: true,
        label: Text(badgeText!),
        child: iconWidget,
      );
    }

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onTap(index),
        child: AnimatedScale(
          scale: isActive ? 0.96 : 1.0,
          duration: const Duration(milliseconds: 150),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Column(
                  children: [
                    iconWidget,
                    const SizedBox(height: 3),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                height: 4,
                width: 4,
                margin: const EdgeInsets.only(top: 2),
                decoration: BoxDecoration(
                  color: isActive ? NannyTheme.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClientProfileView extends StatefulWidget {
  final Widget logoutView;
  final bool persistState;

  const _ClientProfileView({
    required this.logoutView,
    this.persistState = false,
  });

  @override
  State<_ClientProfileView> createState() => _ClientProfileViewState();
}

class _ClientProfileViewState extends State<_ClientProfileView>
    with AutomaticKeepAliveClientMixin {
  late ProfileVM vm;

  @override
  void initState() {
    super.initState();
    vm = _ClientProfileVM(
      context: context,
      update: setState,
      logoutView: widget.logoutView,
    );

    vm.firstName = NannyUser.userInfo!.name;
    vm.lastName = NannyUser.userInfo!.surname;
  }

  @override
  Widget build(BuildContext context) {
    if (wantKeepAlive) super.build(context);

    return Scaffold(
      appBar: NannyAppBar.gradient(
        hasBackButton: false,
        title: "Профиль",
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            NannyTheme.primary,
            NannyTheme.primaryDark,
          ],
        ),
        leading: IconButton(
          onPressed: vm.navigateToAppSettings,
          icon: const Icon(Icons.settings),
          splashRadius: 26,
          color: Colors.white,
        ),
        actions: [
          IconButton(
            onPressed: vm.logout,
            icon: const Icon(Icons.exit_to_app_rounded),
            splashRadius: 26,
            color: Colors.white,
          )
        ],
      ),
      body: AdaptBuilder(
        builder: (context, size) {
          final user = NannyUser.userInfo;
          final name = user?.name ?? '';
          final surname = user?.surname ?? '';
          final initials = (name.isNotEmpty || surname.isNotEmpty)
              ? '${name.isNotEmpty ? name[0] : ''}${surname.isNotEmpty ? surname[0] : ''}'
              : 'A';

          return Column(
            children: [
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    ProfileImage(
                      url: user?.photoPath ?? '',
                      radius: 72,
                      initials: initials,
                      showOnlineDot: true,
                      onTap: vm.changeProfilePhoto,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$name $surname'.trim(),
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            TextMasks.phoneMask()
                                .maskText(user?.phone.substring(1) ?? ''),
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: NannyTheme.neutral500),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: NannyBottomSheet(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Личные данные',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        NannyTextForm(
                          isExpanded: true,
                          labelText: "Имя",
                          initialValue: vm.firstName,
                          onChanged: (text) => vm.firstName = text.trim(),
                        ),
                        const SizedBox(height: 12),
                        NannyTextForm(
                          isExpanded: true,
                          labelText: "Фамилия",
                          initialValue: vm.lastName,
                          onChanged: (text) => vm.lastName = text.trim(),
                        ),
                        const SizedBox(height: 12),
                        NannyTextForm(
                          isExpanded: true,
                          readOnly: true,
                          labelText: "Пароль",
                          initialValue: "••••••••",
                          onTap: vm.changePassword,
                        ),
                        const SizedBox(height: 12),
                        NannyTextForm(
                          isExpanded: true,
                          readOnly: true,
                          labelText: "Пин-код",
                          initialValue: "••••",
                          onTap: vm.changePincode,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Сервис и безопасность',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        _ProfileActionButton(
                          icon: Icons.child_care,
                          label: 'Мои дети',
                          onTap: vm.navigateToChildren,
                        ),
                        _ProfileActionButton(
                          icon: Icons.history,
                          label: 'История поездок',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const TripHistoryView(),
                            ),
                          ),
                        ),
                        _ProfileActionButton(
                          icon: Icons.support_agent,
                          label: 'Техподдержка',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SupportChatView(),
                            ),
                          ),
                        ),
                        _ProfileActionButton(
                          icon: Icons.help_outline,
                          label: 'Частые вопросы',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const FaqView(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Аналитика и документы',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        _ProfileActionButton(
                          icon: Icons.pie_chart_outline,
                          label: 'Аналитика расходов',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SpendingAnalyticsView(),
                            ),
                          ),
                        ),
                        _ProfileActionButton(
                          icon: Icons.picture_as_pdf,
                          label: 'Экспорт поездок PDF',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const TripExportView(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Совместные поездки и бонусы',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        _ProfileActionButton(
                          icon: Icons.people_outline,
                          label: 'Совместные поездки',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SharedRideView(),
                            ),
                          ),
                        ),
                        _ProfileActionButton(
                          icon: Icons.card_giftcard,
                          label: 'Реферальная программа',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ReferralView(),
                            ),
                          ),
                        ),
                        _ProfileActionButton(
                          icon: Icons.report_problem_outlined,
                          label: 'Подать жалобу',
                          iconColor: Colors.orange,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ComplaintView(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Настройки приложения',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        ValueListenableBuilder<ThemeMode>(
                          valueListenable: themeNotifier,
                          builder: (context, mode, _) {
                            final modes = [
                              ThemeMode.light,
                              ThemeMode.system,
                              ThemeMode.dark
                            ];
                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Theme.of(context).dividerColor,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.brightness_6,
                                          color: NannyTheme.primary),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Тема оформления',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  _ProfileSegmentRow(
                                    labels: const [
                                      'Светлая',
                                      'Авто',
                                      'Тёмная',
                                    ],
                                    selectedIndex: modes.indexOf(mode),
                                    onSelected: (i) =>
                                        themeNotifier.setThemeMode(modes[i]),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        ValueListenableBuilder<Locale>(
                          valueListenable: localeNotifier,
                          builder: (context, locale, _) {
                            final isRu = locale.languageCode == 'ru';
                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Theme.of(context).dividerColor,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.language,
                                          color: NannyTheme.primary),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Язык / Language',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  _ProfileSegmentRow(
                                    labels: const [
                                      'Русский',
                                      'English',
                                    ],
                                    selectedIndex: isRu ? 0 : 1,
                                    onSelected: (i) => localeNotifier
                                        .setLocale(i == 0 ? 'ru' : 'en'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: vm.saveChanges,
                            child: const Text("Сохранить изменения"),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  bool get wantKeepAlive => widget.persistState;
}

/// Сегментированный переключатель для профиля (тема, язык).
class _ProfileSegmentRow extends StatelessWidget {
  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const _ProfileSegmentRow({
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final trackColor = isDark ? const Color(0xFF2A2A3E) : NannyTheme.neutral100;
    final borderColor = isDark
        ? Theme.of(context).colorScheme.outline.withOpacity(0.3)
        : NannyTheme.neutral200;
    final unselectedTextColor = isDark
        ? Theme.of(context).colorScheme.onSurface
        : NannyTheme.neutral700;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: trackColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: List.generate(labels.length, (i) {
            final selected = i == selectedIndex;
            final isFirst = i == 0;
            final isLast = i == labels.length - 1;
            return Expanded(
              child: Material(
                color: selected ? NannyTheme.primary : Colors.transparent,
                borderRadius: BorderRadius.horizontal(
                  left: isFirst ? const Radius.circular(11) : Radius.zero,
                  right: isLast ? const Radius.circular(11) : Radius.zero,
                ),
                child: InkWell(
                  onTap: () => onSelected(i),
                  borderRadius: BorderRadius.horizontal(
                    left: isFirst ? const Radius.circular(11) : Radius.zero,
                    right: isLast ? const Radius.circular(11) : Radius.zero,
                  ),
                  child: Center(
                    child: Text(
                      labels[i],
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color:
                                selected ? Colors.white : unselectedTextColor,
                            fontWeight:
                                selected ? FontWeight.w600 : FontWeight.w500,
                          ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _ProfileActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? iconColor;
  final VoidCallback onTap;

  const _ProfileActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: Theme.of(context).dividerColor.withOpacity(0.5)),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: (iconColor ?? NannyTheme.primary).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: iconColor ?? NannyTheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: NannyTheme.neutral300,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClientProfileVM extends ProfileVM {
  _ClientProfileVM({
    required super.context,
    required super.update,
    required super.logoutView,
  });

  @override
  void navigateToChildren() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ChildrenListView()),
    );
  }
}
