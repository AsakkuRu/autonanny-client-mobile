import 'package:autonanny_ui_core/autonanny_ui_core.dart';
import 'package:flutter/material.dart';
import 'package:nanny_client/view_models/new_main/profile/client_profile_v2_vm.dart';
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

    return AutonannyAppScaffold(
      body: FutureBuilder<void>(
        future: _initFuture,
        builder: (context, snapshot) {
          return AutonannyGradientHeaderShell(
            headerPadding: const EdgeInsets.fromLTRB(
              AutonannySpacing.lg,
              AutonannySpacing.md,
              AutonannySpacing.lg,
              AutonannySpacing.xl,
            ),
            header: _ProfileHero(vm: vm),
            body: RefreshIndicator(
              onRefresh: vm.init,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AutonannySpacing.lg),
                children: [
                  const AutonannyInlineBanner(
                    title: 'Профиль всегда под рукой',
                    message:
                        'Управляйте детьми, уведомлениями и безопасностью без перехода в legacy-экраны.',
                    tone: AutonannyBannerTone.info,
                    leading: AutonannyIcon(AutonannyIcons.profile),
                  ),
                  const SizedBox(height: AutonannySpacing.lg),
                  _buildPersonalDataSection(),
                  _buildChildrenSection(),
                  _buildSecuritySection(),
                  _buildNotificationsSection(),
                  _buildAppearanceSection(),
                  _buildTripsSection(),
                  _buildPartnersSection(),
                  _buildHelpSection(),
                  _buildAboutSection(),
                  const SizedBox(height: AutonannySpacing.md),
                  AutonannyButton(
                    label: 'Выйти из аккаунта',
                    variant: AutonannyButtonVariant.danger,
                    leading: const AutonannyIcon(
                      AutonannyIcons.logout,
                      color: Colors.white,
                      size: 18,
                    ),
                    onPressed: vm.logout,
                  ),
                  const SizedBox(height: AutonannySpacing.md),
                  Center(
                    child: Text(
                      'АвтоНяня v1.0.0',
                      style: AutonannyTypography.caption(
                        color: context.autonannyColors.textTertiary,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: MediaQuery.of(context).padding.bottom +
                        AutonannySpacing.lg,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPersonalDataSection() {
    return AutonannyProfileSection(
      title: 'Личные данные',
      children: [
        AutonannyProfileRow(
          icon: AutonannyIcons.profile,
          label: 'Полное имя',
          value: vm.fullName.isEmpty ? 'Не указано' : vm.fullName,
          onTap: vm.editFullName,
        ),
        AutonannyProfileRow(
          icon: AutonannyIcons.phone,
          label: 'Телефон',
          value: vm.phoneMasked,
          tone: AutonannyProfileRowTone.success,
          badgeLabel: 'Подтверждён',
          badgeVariant: AutonannyBadgeVariant.success,
          onTap: () => _showInfoDialog(
            'Телефон',
            'Изменение телефона выполняется через подтверждение в службе поддержки',
          ),
        ),
        AutonannyProfileRow(
          icon: AutonannyIcons.mail,
          label: 'Email',
          value: vm.email,
          tone: vm.email == 'Не указан'
              ? AutonannyProfileRowTone.primary
              : AutonannyProfileRowTone.success,
          badgeLabel: vm.email == 'Не указан' ? null : 'Подтверждён',
          badgeVariant: AutonannyBadgeVariant.success,
          onTap: () => _showInfoDialog(
            'Email',
            'Редактирование email будет добавлено в следующем обновлении',
          ),
        ),
        AutonannyProfileRow(
          icon: AutonannyIcons.location,
          label: 'Домашний адрес',
          value: vm.address,
          onTap: () => _showInfoDialog(
            'Адрес',
            'Редактирование адреса будет добавлено в следующем обновлении',
          ),
        ),
      ],
    );
  }

  Widget _buildChildrenSection() {
    final colors = context.autonannyColors;

    return AutonannyProfileSection(
      title: 'Мои дети',
      children: [
        if (vm.isChildrenLoading)
          const Padding(
            padding: EdgeInsets.all(AutonannySpacing.xl),
            child: Center(child: CircularProgressIndicator()),
          )
        else ...[
          if (vm.children.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(
                AutonannySpacing.lg,
                AutonannySpacing.md,
                AutonannySpacing.lg,
                AutonannySpacing.sm,
              ),
              child: AutonannyInlineBanner(
                title: 'Детские профили пока не добавлены',
                message:
                    'Добавьте профиль ребёнка, чтобы оформлять поездки быстрее и без повторного ввода данных.',
                tone: AutonannyBannerTone.info,
                leading: AutonannyIcon(AutonannyIcons.child),
              ),
            )
          else
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
            padding: const EdgeInsets.fromLTRB(
              AutonannySpacing.lg,
              AutonannySpacing.sm,
              AutonannySpacing.lg,
              AutonannySpacing.lg,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: AutonannyButton(
                label: 'Добавить ребёнка',
                variant: AutonannyButtonVariant.secondary,
                size: AutonannyButtonSize.medium,
                expand: false,
                leading: AutonannyIcon(
                  AutonannyIcons.add,
                  color: colors.actionPrimary,
                  size: 18,
                ),
                onPressed: vm.openAddChild,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSecuritySection() {
    return AutonannyProfileSection(
      title: 'Безопасность',
      children: [
        AutonannyProfileRow(
          icon: AutonannyIcons.lock,
          label: 'Пароль',
          value: 'Изменить пароль',
          tone: AutonannyProfileRowTone.warning,
          onTap: vm.changePassword,
        ),
        AutonannyProfileRow(
          icon: AutonannyIcons.pinCode,
          label: 'PIN-код входа',
          value: 'Изменить PIN',
          tone: AutonannyProfileRowTone.warning,
          onTap: vm.changePin,
        ),
        AutonannyProfileRow(
          icon: AutonannyIcons.verified,
          label: 'Биометрия',
          value: vm.canUseBiometrics
              ? 'Face ID / Touch ID'
              : 'Не поддерживается на устройстве',
          tone: AutonannyProfileRowTone.success,
          showChevron: false,
          enabled: vm.canUseBiometrics,
          toggleValue: vm.useBiometrics,
          onToggle: vm.canUseBiometrics ? vm.setBiometrics : null,
        ),
      ],
    );
  }

  Widget _buildNotificationsSection() {
    return AutonannyProfileSection(
      title: 'Уведомления',
      children: [
        AutonannyProfileRow(
          icon: AutonannyIcons.bell,
          label: 'Push-уведомления',
          value: 'Поездки, чаты, оплата',
          showChevron: false,
          toggleValue: vm.pushEnabled,
          onToggle: vm.setPushNotifications,
        ),
        AutonannyProfileRow(
          icon: AutonannyIcons.sms,
          label: 'SMS',
          value: 'Только важные события',
          tone: AutonannyProfileRowTone.neutral,
          showChevron: false,
          toggleValue: vm.smsEnabled,
          onToggle: vm.setSmsNotifications,
        ),
      ],
    );
  }

  Widget _buildAppearanceSection() {
    return AutonannyProfileSection(
      title: 'Внешний вид',
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AutonannySpacing.lg,
            AutonannySpacing.md,
            AutonannySpacing.lg,
            AutonannySpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Тема приложения',
                style: AutonannyTypography.bodyS(
                  color: context.autonannyColors.textTertiary,
                ),
              ),
              const SizedBox(height: AutonannySpacing.md),
              Wrap(
                spacing: AutonannySpacing.sm,
                runSpacing: AutonannySpacing.sm,
                children: [
                  _ThemeModeChip(
                    icon: AutonannyIcons.sun,
                    label: 'Светлая',
                    isActive: vm.themeMode == ThemeMode.light,
                    onTap: () => vm.setThemeMode(ThemeMode.light),
                  ),
                  _ThemeModeChip(
                    icon: AutonannyIcons.moon,
                    label: 'Тёмная',
                    isActive: vm.themeMode == ThemeMode.dark,
                    onTap: () => vm.setThemeMode(ThemeMode.dark),
                  ),
                  _ThemeModeChip(
                    icon: AutonannyIcons.settings,
                    label: 'Система',
                    isActive: vm.themeMode == ThemeMode.system,
                    onTap: () => vm.setThemeMode(ThemeMode.system),
                  ),
                ],
              ),
            ],
          ),
        ),
        Divider(height: 1, color: context.autonannyColors.borderSubtle),
        AutonannyProfileRow(
          icon: AutonannyIcons.language,
          label: 'Язык',
          value: vm.locale.languageCode == 'ru' ? 'Русский' : 'English',
          tone: AutonannyProfileRowTone.neutral,
          badgeLabel: vm.locale.languageCode.toUpperCase(),
          badgeVariant: AutonannyBadgeVariant.info,
          onTap: _showLanguagePicker,
        ),
      ],
    );
  }

  Widget _buildTripsSection() {
    return AutonannyProfileSection(
      title: 'Мои поездки',
      children: [
        AutonannyProfileRow(
          icon: AutonannyIcons.car,
          label: 'Всего поездок',
          value: 'История поездок · ${vm.tripsCount}',
          onTap: vm.openTripHistory,
        ),
      ],
    );
  }

  Widget _buildPartnersSection() {
    return AutonannyProfileSection(
      title: 'Партнёрам',
      children: [
        AutonannyProfileRow(
          icon: AutonannyIcons.group,
          label: 'Партнёрская сеть',
          value: 'Приглашайте семьи в АвтоНяню',
          badgeLabel: 'Партнёр',
          badgeVariant: AutonannyBadgeVariant.info,
          onTap: vm.openReferral,
        ),
      ],
    );
  }

  Widget _buildHelpSection() {
    return AutonannyProfileSection(
      title: 'Помощь',
      children: [
        AutonannyProfileRow(
          icon: AutonannyIcons.book,
          label: 'База знаний',
          value: 'Частые вопросы (FAQ)',
          tone: AutonannyProfileRowTone.warning,
          onTap: vm.openFaq,
        ),
        AutonannyProfileRow(
          icon: AutonannyIcons.chat,
          label: 'Служба поддержки',
          value: 'Написать оператору',
          tone: AutonannyProfileRowTone.success,
          badgeLabel: 'Онлайн',
          badgeVariant: AutonannyBadgeVariant.success,
          onTap: vm.openSupportChat,
        ),
        AutonannyProfileRow(
          icon: AutonannyIcons.phone,
          label: 'Горячая линия',
          value: '8-800-555-35-35 · Бесплатно',
          tone: AutonannyProfileRowTone.neutral,
          onTap: vm.callHotline,
        ),
      ],
    );
  }

  Widget _buildAboutSection() {
    return AutonannyProfileSection(
      title: 'О приложении',
      children: [
        AutonannyProfileRow(
          icon: AutonannyIcons.document,
          value: 'Пользовательское соглашение',
          tone: AutonannyProfileRowTone.neutral,
          onTap: vm.openUserAgreement,
        ),
        AutonannyProfileRow(
          icon: AutonannyIcons.shield,
          value: 'Политика конфиденциальности',
          tone: AutonannyProfileRowTone.neutral,
          onTap: vm.openPrivacyPolicy,
        ),
        AutonannyProfileRow(
          icon: AutonannyIcons.warning,
          value: 'Подать жалобу',
          tone: AutonannyProfileRowTone.danger,
          onTap: vm.openComplaint,
        ),
      ],
    );
  }

  Future<void> _showLanguagePicker() async {
    final colors = context.autonannyColors;
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return AutonannyBottomSheetShell(
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colors.borderSubtle,
                      borderRadius: AutonannyRadii.brFull,
                    ),
                  ),
                ),
                const SizedBox(height: AutonannySpacing.lg),
                Text(
                  'Язык',
                  style: AutonannyTypography.h3(
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: AutonannySpacing.sm),
                _LanguageOption(
                  icon: AutonannyIcons.checkCircle,
                  label: 'Русский',
                  isSelected: vm.locale.languageCode == 'ru',
                  onTap: () => Navigator.pop(context, 'ru'),
                ),
                _LanguageOption(
                  icon: AutonannyIcons.language,
                  label: 'English',
                  isSelected: vm.locale.languageCode == 'en',
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

  Future<void> _showInfoDialog(String title, String description) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: AutonannySpacing.lg,
          ),
          child: AutonannyDialogSurface(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: AutonannyTypography.h3(
                    color: dialogContext.autonannyColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AutonannySpacing.sm),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: AutonannyTypography.bodyS(
                    color: dialogContext.autonannyColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AutonannySpacing.xl),
                AutonannyButton(
                  label: 'Понятно',
                  onPressed: () => Navigator.of(dialogContext).pop(),
                ),
              ],
            ),
          ),
        );
      },
    );
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
  const _ProfileHero({required this.vm});

  final ClientProfileV2Vm vm;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Text(
            'Профиль',
            style: AutonannyTypography.h2(color: Colors.white),
          ),
        ),
        const SizedBox(height: AutonannySpacing.xl),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _HeroAvatar(vm: vm),
            const SizedBox(width: AutonannySpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vm.fullName.isEmpty ? 'Профиль' : vm.fullName,
                    style: AutonannyTypography.h2(color: Colors.white),
                  ),
                  const SizedBox(height: AutonannySpacing.xs),
                  Text(
                    vm.phoneMasked,
                    style: AutonannyTypography.bodyS(
                      color: const Color(0xD9FFFFFF),
                    ),
                  ),
                  const SizedBox(height: AutonannySpacing.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AutonannySpacing.sm,
                      vertical: AutonannySpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0x26FFFFFF),
                      borderRadius: AutonannyRadii.brFull,
                      border: Border.all(color: const Color(0x40FFFFFF)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AutonannyIcon(
                          AutonannyIcons.verified,
                          size: 14,
                          color: Color(0xFFB9FFD2),
                        ),
                        SizedBox(width: AutonannySpacing.xs),
                        Text(
                          'Проверенный клиент',
                          style: TextStyle(
                            color: Color(0xFFF4FFFA),
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AutonannySpacing.lg),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AutonannySpacing.md,
            vertical: AutonannySpacing.md,
          ),
          decoration: BoxDecoration(
            color: const Color(0x26FFFFFF),
            borderRadius: AutonannyRadii.brLg,
            border: Border.all(color: const Color(0x33FFFFFF)),
          ),
          child: Row(
            children: [
              Expanded(
                child: AutonannyStatItem(
                  value: vm.tripsCount,
                  label: 'ПОЕЗДОК',
                  inverse: true,
                ),
              ),
              Expanded(
                child: AutonannyStatItem(
                  value: vm.contractsCount,
                  label: 'КОНТРАКТОВ',
                  inverse: true,
                ),
              ),
              Expanded(
                child: AutonannyStatItem(
                  value: vm.ratingValue,
                  label: 'РЕЙТИНГ',
                  inverse: true,
                ),
              ),
              Expanded(
                child: AutonannyStatItem(
                  value: vm.monthsWithUs,
                  label: 'С НАМИ',
                  inverse: true,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeroAvatar extends StatelessWidget {
  const _HeroAvatar({required this.vm});

  final ClientProfileV2Vm vm;

  @override
  Widget build(BuildContext context) {
    final photoPath = NannyUser.userInfo?.photoPath ?? '';

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 84,
          height: 84,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: const Color(0x33FFFFFF)),
          ),
          alignment: Alignment.center,
          child: AutonannyAvatar(
            imageUrl: photoPath,
            initials: vm.userInitials,
            size: 84,
            borderRadius: BorderRadius.circular(26),
          ),
        ),
        Positioned(
          right: -2,
          bottom: -2,
          child: GestureDetector(
            onTap: vm.changeProfilePhoto,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFDCD8FB)),
              ),
              alignment: Alignment.center,
              child: const AutonannyIcon(
                AutonannyIcons.edit,
                color: Color(0xFF5B4FCF),
                size: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ThemeModeChip extends StatelessWidget {
  const _ThemeModeChip({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final AutonannyIconAsset icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.autonannyColors;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AutonannyRadii.brFull,
        child: AnimatedContainer(
          duration: AutonannyMotion.fast,
          padding: const EdgeInsets.symmetric(
            horizontal: AutonannySpacing.md,
            vertical: AutonannySpacing.sm,
          ),
          decoration: BoxDecoration(
            color: isActive
                ? colors.actionPrimary.withValues(alpha: 0.14)
                : colors.surfaceSecondary,
            borderRadius: AutonannyRadii.brFull,
            border: Border.all(
              color: isActive ? colors.actionPrimary : colors.borderSubtle,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AutonannyIcon(
                icon,
                size: 16,
                color: isActive ? colors.actionPrimary : colors.textSecondary,
              ),
              const SizedBox(width: AutonannySpacing.xs),
              Text(
                label,
                style: AutonannyTypography.labelM(
                  color: isActive ? colors.actionPrimary : colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  const _LanguageOption({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final AutonannyIconAsset icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.autonannyColors;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AutonannyRadii.brLg,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: AutonannySpacing.md,
          ),
          child: Row(
            children: [
              AutonannyIcon(
                icon,
                color: colors.textSecondary,
                size: 18,
              ),
              const SizedBox(width: AutonannySpacing.md),
              Expanded(
                child: Text(
                  label,
                  style: AutonannyTypography.bodyM(
                    color: colors.textPrimary,
                  ),
                ),
              ),
              if (isSelected)
                AutonannyIcon(
                  AutonannyIcons.check,
                  color: colors.actionPrimary,
                  size: 18,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChildRowCard extends StatelessWidget {
  const _ChildRowCard({
    required this.childName,
    required this.childMeta,
    required this.isActive,
    this.photoPath,
    this.onTap,
  });

  final String childName;
  final String childMeta;
  final bool isActive;
  final String? photoPath;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.autonannyColors;
    final initial =
        childName.isNotEmpty ? childName.characters.first.toUpperCase() : 'Р';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AutonannySpacing.lg,
            AutonannySpacing.md,
            AutonannySpacing.lg,
            AutonannySpacing.md,
          ),
          child: Row(
            children: [
              _ChildAvatar(
                photoPath: photoPath,
                initial: initial,
              ),
              const SizedBox(width: AutonannySpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      childName,
                      style: AutonannyTypography.bodyL(
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AutonannySpacing.xxs),
                    Text(
                      childMeta.isEmpty ? 'Профиль ребёнка' : childMeta,
                      style: AutonannyTypography.bodyS(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AutonannySpacing.sm),
              AutonannyBadge(
                label: isActive ? 'Активен' : 'Неактивен',
                variant: isActive
                    ? AutonannyBadgeVariant.success
                    : AutonannyBadgeVariant.neutral,
              ),
              const SizedBox(width: AutonannySpacing.xs),
              AutonannyIcon(
                AutonannyIcons.chevronRight,
                size: 18,
                color: colors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChildAvatar extends StatelessWidget {
  const _ChildAvatar({
    required this.photoPath,
    required this.initial,
  });

  final String? photoPath;
  final String initial;

  @override
  Widget build(BuildContext context) {
    final fileUrl = NannyConsts.buildFileUrl(photoPath);
    if (fileUrl != null) {
      return CircleAvatar(
        radius: 22,
        backgroundImage: NetworkImage(fileUrl),
      );
    }

    return Container(
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
      alignment: Alignment.center,
      child: Text(
        initial,
        style: AutonannyTypography.bodyL(color: Colors.white),
      ),
    );
  }
}
