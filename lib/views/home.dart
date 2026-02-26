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
      const ChatsView(persistState: false),
      _ClientProfileView(
        persistState: true,
        logoutView: WelcomeView(
            regView: const RegView(), loginPaths: NannyConsts.availablePaths),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
        statusBarColor: Theme.of(context).scaffoldBackgroundColor));
    return DefaultTabController(
      initialIndex: 1,
      length: pages.length,
      child: Scaffold(
        body: TabBarView(
          physics: const NeverScrollableScrollPhysics(),
          children: pages,
        ),
        bottomNavigationBar: TabBar(
          onTap: (index) {
            vm.indexChanged(index);
            if (index == 0) {
              Future.delayed(
                const Duration(milliseconds: 100),
                () => _setTransparentStatusBar(),
              );
            }
          },
          labelColor: NannyTheme.primary,
          unselectedLabelColor: NannyTheme.darkGrey,
          indicatorColor: NannyTheme.primary,
          tabs: const [
            Tab(
              icon: Icon(
                Icons.directions_car_filled_rounded,
              ),
            ),
            Tab(
              icon: Icon(
                Icons.calendar_month_rounded,
              ),
            ),
            Tab(
              icon: Icon(
                Icons.wallet_rounded,
              ),
            ),
            Tab(
              icon: Icon(
                Icons.chat_rounded,
              ),
            ),
            Tab(
              icon: Icon(
                Icons.account_circle_rounded,
              ),
            ),
          ],
        ),
      ),
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
      appBar: NannyAppBar(
        title: "Профиль",
        color: NannyTheme.secondary,
        isTransparent: false,
        hasBackButton: false,
        leading: IconButton(
          onPressed: vm.navigateToAppSettings,
          icon: const Icon(Icons.settings),
          splashRadius: 30,
        ),
        actions: [
          IconButton(
            onPressed: vm.logout,
            icon: const Icon(Icons.exit_to_app_rounded),
            splashRadius: 30,
          )
        ],
      ),
      body: AdaptBuilder(
        builder: (context, size) {
          return Center(
            child: Column(
              children: [
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      ProfileImage(
                        url: NannyUser.userInfo!.photoPath,
                        radius: size.shortestSide * .3,
                        onTap: vm.changeProfilePhoto,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 5,
                              children: [
                                Text(
                                  NannyUser.userInfo!.name,
                                  style: Theme.of(context).textTheme.headlineSmall,
                                ),
                                Text(
                                  NannyUser.userInfo!.surname,
                                  style: Theme.of(context).textTheme.headlineSmall,
                                ),
                              ],
                            ),
                            Text(
                              TextMasks.phoneMask().maskText(
                                  NannyUser.userInfo!.phone.substring(1)),
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: NannyBottomSheet(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: [
                            const SizedBox(height: 20),
                            NannyTextForm(
                              isExpanded: true,
                              labelText: "Имя",
                              initialValue: vm.firstName,
                              onChanged: (text) => vm.firstName = text.trim(),
                            ),
                            const SizedBox(height: 20),
                            NannyTextForm(
                              isExpanded: true,
                              labelText: "Фамилия",
                              initialValue: vm.lastName,
                              onChanged: (text) => vm.lastName = text.trim(),
                            ),
                            const SizedBox(height: 20),
                            NannyTextForm(
                              isExpanded: true,
                              readOnly: true,
                              labelText: "Пароль",
                              initialValue: "••••••••",
                              onTap: vm.changePassword,
                            ),
                            const SizedBox(height: 20),
                            NannyTextForm(
                              isExpanded: true,
                              readOnly: true,
                              labelText: "Пин-код",
                              initialValue: "••••",
                              onTap: vm.changePincode,
                            ),
                            const SizedBox(height: 20),
                            // Кнопка "Мои дети"
                            OutlinedButton.icon(
                              onPressed: vm.navigateToChildren,
                              icon: const Icon(Icons.child_care),
                              label: const Text('Мои дети'),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 60),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                side: BorderSide(color: NannyTheme.primary),
                                foregroundColor: NannyTheme.primary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Кнопка "История поездок"
                            OutlinedButton.icon(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const TripHistoryView()),
                              ),
                              icon: const Icon(Icons.history),
                              label: const Text('История поездок'),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 60),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                side: BorderSide(color: NannyTheme.primary),
                                foregroundColor: NannyTheme.primary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Кнопка "Техподдержка"
                            OutlinedButton.icon(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const SupportChatView()),
                              ),
                              icon: const Icon(Icons.support_agent),
                              label: const Text('Техподдержка'),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 60),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                side: BorderSide(color: NannyTheme.primary),
                                foregroundColor: NannyTheme.primary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Кнопка "Аналитика расходов"
                            OutlinedButton.icon(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const SpendingAnalyticsView()),
                              ),
                              icon: const Icon(Icons.pie_chart_outline),
                              label: const Text('Аналитика расходов'),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 60),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                side: BorderSide(color: NannyTheme.primary),
                                foregroundColor: NannyTheme.primary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Кнопка "Экспорт PDF"
                            OutlinedButton.icon(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const TripExportView()),
                              ),
                              icon: const Icon(Icons.picture_as_pdf),
                              label: const Text('Экспорт поездок PDF'),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 60),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                side: BorderSide(color: NannyTheme.primary),
                                foregroundColor: NannyTheme.primary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Кнопка "FAQ"
                            OutlinedButton.icon(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const FaqView()),
                              ),
                              icon: const Icon(Icons.help_outline),
                              label: const Text('Частые вопросы'),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 60),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                side: BorderSide(color: NannyTheme.primary),
                                foregroundColor: NannyTheme.primary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Кнопка "Совместные поездки"
                            OutlinedButton.icon(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const SharedRideView()),
                              ),
                              icon: const Icon(Icons.people_outline),
                              label: const Text('Совместные поездки'),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 60),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                side: BorderSide(color: NannyTheme.primary),
                                foregroundColor: NannyTheme.primary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Кнопка "Реферальная программа"
                            OutlinedButton.icon(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const ReferralView()),
                              ),
                              icon: const Icon(Icons.card_giftcard),
                              label: const Text('Реферальная программа'),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 60),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                side: BorderSide(color: NannyTheme.primary),
                                foregroundColor: NannyTheme.primary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Кнопка "Подать жалобу"
                            OutlinedButton.icon(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const ComplaintView()),
                              ),
                              icon: const Icon(Icons.report_problem_outlined),
                              label: const Text('Подать жалобу'),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 60),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                side: const BorderSide(color: Colors.orange),
                                foregroundColor: Colors.orange,
                              ),
                            ),
                            const SizedBox(height: 20),
                            // Переключатель темы
                            ValueListenableBuilder<ThemeMode>(
                              valueListenable: themeNotifier,
                              builder: (context, mode, _) {
                                final modes = [ThemeMode.light, ThemeMode.system, ThemeMode.dark];
                                return Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.surface,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Theme.of(context).dividerColor,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.brightness_6, color: NannyTheme.primary),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Тема оформления',
                                            style: Theme.of(context).textTheme.titleMedium,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      SizedBox(
                                        width: double.infinity,
                                        child: ToggleButtons(
                                          isSelected: modes.map((m) => m == mode).toList(),
                                          onPressed: (index) {
                                            themeNotifier.setThemeMode(modes[index]);
                                          },
                                          borderRadius: BorderRadius.circular(8),
                                          selectedColor: Colors.white,
                                          fillColor: NannyTheme.primary,
                                          color: NannyTheme.primary,
                                          constraints: BoxConstraints(
                                            minWidth: (MediaQuery.of(context).size.width - 100) / 3,
                                            minHeight: 40,
                                          ),
                                          children: const [
                                            Row(mainAxisSize: MainAxisSize.min, children: [
                                              Icon(Icons.light_mode, size: 18),
                                              SizedBox(width: 4),
                                              Text('Светлая'),
                                            ]),
                                            Row(mainAxisSize: MainAxisSize.min, children: [
                                              Icon(Icons.settings_brightness, size: 18),
                                              SizedBox(width: 4),
                                              Text('Авто'),
                                            ]),
                                            Row(mainAxisSize: MainAxisSize.min, children: [
                                              Icon(Icons.dark_mode, size: 18),
                                              SizedBox(width: 4),
                                              Text('Тёмная'),
                                            ]),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 12),
                            // Переключатель языка
                            ValueListenableBuilder<Locale>(
                              valueListenable: localeNotifier,
                              builder: (context, locale, _) {
                                final isRu = locale.languageCode == 'ru';
                                return Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.surface,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Theme.of(context).dividerColor,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.language, color: NannyTheme.primary),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Язык / Language',
                                            style: Theme.of(context).textTheme.titleMedium,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      SizedBox(
                                        width: double.infinity,
                                        child: ToggleButtons(
                                          isSelected: [isRu, !isRu],
                                          onPressed: (index) {
                                            localeNotifier.setLocale(index == 0 ? 'ru' : 'en');
                                          },
                                          borderRadius: BorderRadius.circular(8),
                                          selectedColor: Colors.white,
                                          fillColor: NannyTheme.primary,
                                          color: NannyTheme.primary,
                                          constraints: BoxConstraints(
                                            minWidth: (MediaQuery.of(context).size.width - 80) / 2,
                                            minHeight: 40,
                                          ),
                                          children: const [
                                            Text('Русский'),
                                            Text('English'),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: vm.saveChanges,
                              style: ButtonStyle(
                                shape: WidgetStatePropertyAll(
                                  RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                minimumSize: const WidgetStatePropertyAll(
                                  Size(double.infinity, 60),
                                ),
                              ),
                              child: const Text("Сохранить"),
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  bool get wantKeepAlive => widget.persistState;
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
