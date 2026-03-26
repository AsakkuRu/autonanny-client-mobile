import 'package:flutter/material.dart';
import 'package:nanny_client/ui_sdk/client_ui_sdk.dart';
import 'package:nanny_client/view_models/pages/autopay_settings_vm.dart';

/// FE-MVP-020: Экран настроек автоматического списания
class AutopaySettingsView extends StatefulWidget {
  const AutopaySettingsView({super.key});

  @override
  State<AutopaySettingsView> createState() => _AutopaySettingsViewState();
}

class _AutopaySettingsViewState extends State<AutopaySettingsView> {
  late final AutopaySettingsVM vm;

  @override
  void initState() {
    super.initState();
    vm = AutopaySettingsVM(context: context, update: setState);
  }

  @override
  Widget build(BuildContext context) {
    return AutonannyListScreenShell(
      appBar: AutonannyAppBar(
        title: 'Автоплатежи',
        leading: AutonannyIconButton(
          icon: const AutonannyIcon(AutonannyIcons.arrowLeft),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      header: _buildHeader(),
      body: FutureBuilder<bool>(
        future: vm.loadRequest,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const AutonannyLoadingState(
              label: 'Загружаем настройки автоплатежей.',
            );
          }

          if (snapshot.hasError || snapshot.data != true) {
            return AutonannyErrorState(
              title: 'Не удалось загрузить данные',
              description: snapshot.error?.toString() ??
                  'Попробуйте открыть настройки ещё раз.',
              actionLabel: 'Повторить',
              onAction: () => vm.reloadPage(),
            );
          }

          return ListView(
            children: [
              const AutonannyInlineBanner(
                title: 'Еженедельное списание',
                message:
                    'Автоматическая оплата будет проходить с выбранной карты раз в неделю.',
                tone: AutonannyBannerTone.info,
                leading: AutonannyIcon(AutonannyIcons.info),
              ),
              const SizedBox(height: AutonannySpacing.lg),
              AutonannySectionContainer(
                title: 'Автоматическое списание',
                subtitle:
                    'Включите автоплатежи, чтобы не подтверждать оплату вручную.',
                trailing: AutonannySwitch(
                  value: vm.isAutopayEnabled,
                  onChanged: vm.toggleAutopay,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: context.autonannyColors.surfaceSecondary,
                        borderRadius: AutonannyRadii.brMd,
                      ),
                      alignment: Alignment.center,
                      child: AutonannyIcon(
                        AutonannyIcons.timer,
                        color: context.autonannyColors.actionPrimary,
                      ),
                    ),
                    const SizedBox(width: AutonannySpacing.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Еженедельная оплата',
                            style: AutonannyTypography.labelL(
                              color: context.autonannyColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: AutonannySpacing.xs),
                          Text(
                            vm.isAutopayEnabled
                                ? 'Списание будет происходить автоматически.'
                                : 'Сейчас автоплатежи отключены.',
                            style: AutonannyTypography.bodyS(
                              color: context.autonannyColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (vm.isAutopayEnabled) ...[
                const SizedBox(height: AutonannySpacing.lg),
                _buildCardsSection(),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    final colors = context.autonannyColors;

    return Container(
      padding: const EdgeInsets.all(AutonannySpacing.xl),
      decoration: const BoxDecoration(
        gradient: AutonannyGradients.hero,
        borderRadius: AutonannyRadii.brLg,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Автоматические списания',
                  style: AutonannyTypography.h2(color: colors.textInverse),
                ),
                const SizedBox(height: AutonannySpacing.xs),
                Text(
                  'Настройте карту и дайте приложению оплачивать поездки автоматически.',
                  style: AutonannyTypography.bodyS(
                    color: colors.textInverse.withValues(alpha: 0.82),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AutonannySpacing.lg),
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: colors.textInverse.withValues(alpha: 0.16),
              borderRadius: AutonannyRadii.brMd,
            ),
            alignment: Alignment.center,
            child: const AutonannyIcon(
              AutonannyIcons.card,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardsSection() {
    if (vm.cards.isEmpty) {
      return AutonannyInlineBanner(
        title: 'Нет привязанных карт',
        message: 'Добавьте карту, чтобы включить автоплатежи.',
        tone: AutonannyBannerTone.warning,
        leading: const AutonannyIcon(AutonannyIcons.warning),
        trailing: AutonannyButton(
          label: 'Добавить',
          size: AutonannyButtonSize.medium,
          onPressed: vm.addCard,
          expand: false,
        ),
      );
    }

    return AutonannySectionContainer(
      title: 'Карта для списания',
      subtitle:
          'Выберите карту, с которой будет происходить еженедельная оплата.',
      trailing: AutonannyButton(
        label: 'Добавить',
        variant: AutonannyButtonVariant.secondary,
        size: AutonannyButtonSize.medium,
        leading: const AutonannyIcon(AutonannyIcons.add),
        onPressed: vm.addCard,
        expand: false,
      ),
      child: Column(
        children: vm.cards
            .asMap()
            .entries
            .map((entry) => Padding(
                  padding: EdgeInsets.only(
                    bottom: entry.key == vm.cards.length - 1
                        ? 0
                        : AutonannySpacing.md,
                  ),
                  child: PaymentMethodCard(
                    data: entry.value.paymentMethodCardData.copyWith(
                      isSelected: vm.selectedCardId == entry.value.id,
                    ),
                    onTap: () => vm.selectCard(entry.value.id),
                  ),
                ))
            .toList(growable: false),
      ),
    );
  }
}
