import 'package:flutter/material.dart';
import 'package:nanny_client/view_models/new_main/profile/client_profile_v2_vm.dart';
import 'package:nanny_components/nanny_components.dart';
import 'package:nanny_core/models/from_api/child.dart';
import 'package:nanny_core/nanny_core.dart';

class ClientProfileV2View extends StatefulWidget {
  final Widget logoutView;

  const ClientProfileV2View({
    super.key,
    required this.logoutView,
  });

  @override
  State<ClientProfileV2View> createState() => _ClientProfileV2ViewState();
}

class _ClientProfileV2ViewState extends State<ClientProfileV2View>
    with AutomaticKeepAliveClientMixin {
  late final ClientProfileV2Vm vm;
  late final Future<void> _initFuture;

  @override
  void initState() {
    super.initState();
    vm = ClientProfileV2Vm(
      context: context,
      update: setState,
      logoutView: widget.logoutView,
    );
    _initFuture = vm.init();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: NDT.screenBg,
      body: FutureBuilder<void>(
        future: _initFuture,
        builder: (context, snapshot) {
          return RefreshIndicator(
            onRefresh: vm.init,
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _ProfileHero(vm: vm),
                const SizedBox(height: NDT.sp12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Column(
                    children: [
                      NdSectionCard(
                        title: 'Личные данные',
                        children: [
                          NdProfileRow(
                            icon: Icons.person_outline_rounded,
                            accent: NdProfileAccent.purple,
                            label: 'Полное имя',
                            value: vm.fullName.isEmpty ? 'Не указано' : vm.fullName,
                            onTap: vm.editFullName,
                          ),
                          NdProfileRow(
                            icon: Icons.call_outlined,
                            accent: NdProfileAccent.purple,
                            label: 'Телефон',
                            value: vm.phoneMasked,
                            badgeText: 'Подтверждён',
                            badgeTone: NdBadgeTone.green,
                            onTap: () => NannyDialogs.showMessageBox(
                              context,
                              'Телефон',
                              'Изменение телефона выполняется через подтверждение в службе поддержки',
                            ),
                          ),
                          NdProfileRow(
                            icon: Icons.mail_outline_rounded,
                            accent: NdProfileAccent.purple,
                            label: 'Email',
                            value: vm.email,
                            badgeText: vm.email == 'Не указан' ? null : 'Подтверждён',
                            badgeTone: NdBadgeTone.green,
                            onTap: () => NannyDialogs.showMessageBox(
                              context,
                              'Email',
                              'Редактирование email будет добавлено в следующем обновлении',
                            ),
                          ),
                          NdProfileRow(
                            icon: Icons.location_on_outlined,
                            accent: NdProfileAccent.purple,
                            label: 'Домашний адрес',
                            value: vm.address,
                            onTap: () => NannyDialogs.showMessageBox(
                              context,
                              'Адрес',
                              'Редактирование адреса будет добавлено в следующем обновлении',
                            ),
                          ),
                        ],
                      ),
                      NdSectionCard(
                        title: 'Мои дети',
                        children: [
                          if (vm.isChildrenLoading)
                            const Padding(
                              padding: EdgeInsets.all(20),
                              child: Center(
                                child: CircularProgressIndicator(color: NDT.primary),
                              ),
                            )
                          else ...[
                            if (vm.children.isEmpty)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                                child: Text(
                                  'Список детей пока пуст. Добавьте профиль ребёнка, чтобы быстрее оформлять поездки.',
                                  style: NDT.bodyS,
                                ),
                              ),
                            ...vm.children.map(
                              (child) => _ChildRowCard(
                                childName: child.name,
                                childMeta: _childMeta(child),
                                isActive: child.isActive,
                                photoPath: child.photoPath,
                                onTap: () => vm.openChildEdit(child),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                              child: GestureDetector(
                                onTap: vm.openAddChild,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: NDT.neutral50,
                                    borderRadius: NDT.brMd,
                                    border: Border.all(
                                      color: NDT.neutral200,
                                      width: 1.2,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.add_rounded,
                                          color: NDT.primary, size: 18),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Добавить ребёнка',
                                        style: NDT.bodyM.copyWith(color: NDT.primary),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      NdSectionCard(
                        title: 'Безопасность',
                        children: [
                          NdProfileRow(
                            icon: Icons.lock_outline_rounded,
                            accent: NdProfileAccent.amber,
                            label: 'Пароль',
                            value: 'Изменить пароль',
                            onTap: vm.changePassword,
                          ),
                          NdProfileRow(
                            icon: Icons.shield_outlined,
                            accent: NdProfileAccent.amber,
                            label: 'PIN-код входа',
                            value: 'Изменить PIN',
                            onTap: vm.changePin,
                          ),
                          NdProfileRow(
                            icon: Icons.verified_user_outlined,
                            accent: NdProfileAccent.green,
                            label: 'Биометрия',
                            value: vm.canUseBiometrics
                                ? 'Face ID / Touch ID'
                                : 'Не поддерживается на устройстве',
                            showChevron: false,
                            toggleValue: vm.useBiometrics,
                            onToggle: vm.canUseBiometrics ? vm.setBiometrics : null,
                            enabled: vm.canUseBiometrics,
                          ),
                        ],
                      ),
                      NdSectionCard(
                        title: 'Уведомления',
                        children: [
                          NdProfileRow(
                            icon: Icons.notifications_none_rounded,
                            accent: NdProfileAccent.purple,
                            label: 'Push-уведомления',
                            value: 'Поездки, чаты, оплата',
                            showChevron: false,
                            toggleValue: vm.pushEnabled,
                            onToggle: vm.setPushNotifications,
                          ),
                          NdProfileRow(
                            icon: Icons.sms_outlined,
                            accent: NdProfileAccent.gray,
                            label: 'SMS',
                            value: 'Только важные события',
                            showChevron: false,
                            toggleValue: vm.smsEnabled,
                            onToggle: vm.setSmsNotifications,
                          ),
                        ],
                      ),
                      NdSectionCard(
                        title: 'Внешний вид',
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Тема приложения',
                                  style: NDT.bodyS.copyWith(color: NDT.neutral400),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    NdThemeOptionChip(
                                      icon: Icons.light_mode_outlined,
                                      label: 'Светлая',
                                      isActive: vm.themeMode == ThemeMode.light,
                                      onTap: () => vm.setThemeMode(ThemeMode.light),
                                    ),
                                    const SizedBox(width: 8),
                                    NdThemeOptionChip(
                                      icon: Icons.dark_mode_outlined,
                                      label: 'Тёмная',
                                      isActive: vm.themeMode == ThemeMode.dark,
                                      onTap: () => vm.setThemeMode(ThemeMode.dark),
                                    ),
                                    const SizedBox(width: 8),
                                    NdThemeOptionChip(
                                      icon: Icons.settings_suggest_outlined,
                                      label: 'Система',
                                      isActive: vm.themeMode == ThemeMode.system,
                                      onTap: () => vm.setThemeMode(ThemeMode.system),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 1, color: NDT.neutral100),
                          NdProfileRow(
                            icon: Icons.language_rounded,
                            accent: NdProfileAccent.gray,
                            label: 'Язык',
                            value: vm.locale.languageCode == 'ru' ? 'Русский' : 'English',
                            badgeText: vm.locale.languageCode.toUpperCase(),
                            onTap: _showLanguagePicker,
                          ),
                        ],
                      ),
                      NdSectionCard(
                        title: 'Мои поездки',
                        children: [
                          NdProfileRow(
                            icon: Icons.directions_car_outlined,
                            accent: NdProfileAccent.purple,
                            label: 'Всего поездок',
                            value: 'История поездок · ${vm.tripsCount}',
                            onTap: vm.openTripHistory,
                          ),
                        ],
                      ),
                      NdSectionCard(
                        title: 'Партнёрам',
                        children: [
                          NdProfileRow(
                            icon: Icons.groups_outlined,
                            accent: NdProfileAccent.purple,
                            label: 'Партнёрская сеть',
                            value: 'Приглашайте семьи в АвтоНяню',
                            badgeText: 'Партнёр',
                            badgeTone: NdBadgeTone.purple,
                            onTap: vm.openReferral,
                          ),
                        ],
                      ),
                      NdSectionCard(
                        title: 'Помощь',
                        children: [
                          NdProfileRow(
                            icon: Icons.help_outline_rounded,
                            accent: NdProfileAccent.amber,
                            label: 'База знаний',
                            value: 'Частые вопросы (FAQ)',
                            onTap: vm.openFaq,
                          ),
                          NdProfileRow(
                            icon: Icons.chat_bubble_outline_rounded,
                            accent: NdProfileAccent.green,
                            label: 'Служба поддержки',
                            value: 'Написать оператору',
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.circle, color: NDT.success, size: 8),
                                SizedBox(width: 8),
                                Icon(Icons.chevron_right_rounded,
                                    color: NDT.neutral300, size: 20),
                              ],
                            ),
                            onTap: vm.openSupportChat,
                          ),
                          NdProfileRow(
                            icon: Icons.call_outlined,
                            accent: NdProfileAccent.gray,
                            label: 'Горячая линия',
                            value: '8-800-555-35-35 · Бесплатно',
                            onTap: vm.callHotline,
                          ),
                        ],
                      ),
                      NdSectionCard(
                        title: 'О приложении',
                        children: [
                          NdProfileRow(
                            icon: Icons.description_outlined,
                            accent: NdProfileAccent.gray,
                            label: '',
                            value: 'Пользовательское соглашение',
                            onTap: vm.openUserAgreement,
                          ),
                          NdProfileRow(
                            icon: Icons.shield_outlined,
                            accent: NdProfileAccent.gray,
                            label: '',
                            value: 'Политика конфиденциальности',
                            onTap: vm.openPrivacyPolicy,
                          ),
                          NdProfileRow(
                            icon: Icons.report_problem_outlined,
                            accent: NdProfileAccent.amber,
                            label: '',
                            value: 'Подать жалобу',
                            onTap: vm.openComplaint,
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: vm.logout,
                        child: Container(
                          height: 52,
                          width: double.infinity,
                          margin: const EdgeInsets.only(top: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFDEEEE),
                            borderRadius: NDT.brLg,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.logout_rounded,
                                  color: NDT.danger, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                'Выйти из аккаунта',
                                style: NDT.bodyL.copyWith(color: NDT.danger),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'АвтоНяня v1.0.0',
                        style: NDT.caption.copyWith(fontSize: 10),
                      ),
                      SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _showLanguagePicker() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: NDT.neutral0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: NDT.neutral200,
                    borderRadius: NDT.brFull,
                  ),
                ),
                const SizedBox(height: 16),
                Text('Язык', style: NDT.h3),
                const SizedBox(height: 10),
                ListTile(
                  leading: const Icon(Icons.check_circle_outline_rounded),
                  title: const Text('Русский'),
                  trailing: vm.locale.languageCode == 'ru'
                      ? const Icon(Icons.check_rounded, color: NDT.primary)
                      : null,
                  onTap: () => Navigator.pop(context, 'ru'),
                ),
                ListTile(
                  leading: const Icon(Icons.language_rounded),
                  title: const Text('English'),
                  trailing: vm.locale.languageCode == 'en'
                      ? const Icon(Icons.check_rounded, color: NDT.primary)
                      : null,
                  onTap: () => Navigator.pop(context, 'en'),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selected != null) {
      await vm.setLocale(selected);
    }
  }

  String _childMeta(Child child) {
    final parts = <String>[];
    if (child.age != null) {
      parts.add('${child.age} лет');
    } else {
      parts.add(child.ageDisplay);
    }
    if ((child.schoolClass ?? '').isNotEmpty) {
      parts.add(child.schoolClass!);
    }
    return parts.join(' · ');
  }

  @override
  bool get wantKeepAlive => true;
}

class _ProfileHero extends StatelessWidget {
  final ClientProfileV2Vm vm;

  const _ProfileHero({required this.vm});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF4D40C8), Color(0xFF5F52D1), Color(0xFF6E63D9)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
          child: Column(
            children: [
              Row(
                children: [
                  const Spacer(),
                  NdIconButton(
                    icon: Icons.settings_outlined,
                    size: 38,
                    onTap: () => NannyDialogs.showMessageBox(
                      context,
                      'Настройки',
                      'Общие настройки доступны в разделах ниже на этом экране',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(color: Colors.white30),
                    ),
                    child: (NannyUser.userInfo?.photoPath ?? '').isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(26),
                            child: Image.network(
                              NannyUser.userInfo!.photoPath,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _HeroInitials(vm: vm),
                            ),
                          )
                        : _HeroInitials(vm: vm),
                  ),
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: GestureDetector(
                      onTap: vm.changeProfilePhoto,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: NDT.neutral0,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFDCD8FB)),
                        ),
                        child: const Icon(
                          Icons.edit_outlined,
                          color: NDT.primary,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                vm.fullName.isEmpty ? 'Профиль' : vm.fullName,
                style: NDT.h2.copyWith(color: NDT.neutral0),
              ),
              const SizedBox(height: 2),
              Text(
                vm.phoneMasked,
                style: NDT.bodyM.copyWith(color: Colors.white70),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: NDT.brLg,
                  border: Border.all(color: Colors.white24),
                ),
                child: Row(
                  children: [
                    _StatItem(value: vm.tripsCount, label: 'ПОЕЗДОК'),
                    _StatItem(value: vm.contractsCount, label: 'КОНТРАКТА'),
                    _StatItem(value: vm.ratingValue, label: 'РЕЙТИНГ'),
                    _StatItem(value: vm.monthsWithUs, label: 'С НАМИ'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;

  const _StatItem({
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: NDT.h3.copyWith(color: NDT.neutral0),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: NDT.labelM.copyWith(color: Colors.white70, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _HeroInitials extends StatelessWidget {
  final ClientProfileV2Vm vm;

  const _HeroInitials({required this.vm});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        vm.userInitials,
        style: NDT.h1.copyWith(color: NDT.neutral0),
      ),
    );
  }
}

class _ChildRowCard extends StatelessWidget {
  final String childName;
  final String childMeta;
  final bool isActive;
  final String? photoPath;
  final VoidCallback? onTap;

  const _ChildRowCard({
    required this.childName,
    required this.childMeta,
    required this.isActive,
    this.photoPath,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final initial = childName.isNotEmpty ? childName.characters.first.toUpperCase() : 'Р';
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Row(
            children: [
              NannyConsts.buildFileUrl(photoPath) != null
                  ? CircleAvatar(
                      radius: 22,
                      backgroundImage: NetworkImage(NannyConsts.buildFileUrl(photoPath)!),
                    )
                  : Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFEC4899), Color(0xFFBE185D)],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          initial,
                          style: NDT.bodyL.copyWith(color: NDT.neutral0),
                        ),
                      ),
                    ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      childName,
                      style: NDT.bodyL.copyWith(color: NDT.neutral900),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      childMeta.isEmpty ? 'Профиль ребёнка' : childMeta,
                      style: NDT.bodyS,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              NdBadge(
                text: isActive ? 'Активен' : 'Неактивен',
                tone: isActive ? NdBadgeTone.green : NdBadgeTone.neutral,
              ),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right_rounded, color: NDT.neutral300),
            ],
          ),
        ),
      ),
    );
  }
}
