import 'package:autonanny_ui_core/autonanny_ui_core.dart';
import 'package:flutter/material.dart';
import 'package:nanny_components/base_views/view_models/pages/wallet_vm.dart';
import 'package:nanny_components/nanny_components.dart';
import 'package:nanny_core/nanny_core.dart';

class WalletView extends StatefulWidget {
  final String title;
  final String subtitle;
  final bool hasReplenishButtons;

  const WalletView({
    super.key,
    required this.title,
    required this.subtitle,
    this.hasReplenishButtons = true,
  });

  @override
  State<WalletView> createState() => _WalletViewState();
}

class _WalletViewState extends State<WalletView> {
  late WalletVM vm;

  @override
  void initState() {
    super.initState();
    vm = WalletVM(context: context, update: setState);
  }

  @override
  Widget build(BuildContext context) {
    return AutonannyListScreenShell(
      appBar: AutonannyAppBar(
        title: widget.title,
        leading: AutonannyIconButton(
          icon: const AutonannyIcon(AutonannyIcons.arrowLeft),
          onPressed: () => Navigator.of(context).maybePop(),
          tooltip: 'Назад',
        ),
      ),
      padding: const EdgeInsets.fromLTRB(
        AutonannySpacing.lg,
        AutonannySpacing.sm,
        AutonannySpacing.lg,
        AutonannySpacing.xl,
      ),
      header: _buildHeader(),
      body: RequestLoader(
        request: vm.cardRequest,
        completeView: (context, data) => RefreshIndicator(
          onRefresh: () async => vm.refresh(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              _buildCardsSection(data?.cards ?? const <UserCardData>[]),
              const SizedBox(height: AutonannySpacing.lg),
              _buildActionsSection(),
              if (widget.hasReplenishButtons) ...[
                const SizedBox(height: AutonannySpacing.lg),
                _buildTopUpSection(),
              ],
              const SizedBox(height: AutonannySpacing.xxl),
            ],
          ),
        ),
        errorView: (context, error) => AutonannyErrorState(
          title: 'Не удалось загрузить карты',
          description: error.toString(),
          actionLabel: 'Повторить',
          onAction: vm.refresh,
        ),
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
                  widget.title,
                  style: AutonannyTypography.h2(color: colors.textInverse),
                ),
                const SizedBox(height: AutonannySpacing.xs),
                Text(
                  widget.subtitle,
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

  Widget _buildCardsSection(List<UserCardData> cards) {
    return AutonannySectionContainer(
      title: 'Способы оплаты',
      subtitle: 'Выберите карту для оплаты или пополнения баланса.',
      child: cards.isEmpty
          ? const AutonannyEmptyState(
              title: 'Карт пока нет',
              description:
                  'Добавьте карту, чтобы оплачивать поездки и быстро пополнять баланс.',
              icon: AutonannyIcon(AutonannyIcons.card, size: 36),
            )
          : Column(
              children: cards
                  .map(
                    (card) => Padding(
                      padding: const EdgeInsets.only(
                        bottom: AutonannySpacing.md,
                      ),
                      child: _WalletCardTile(
                        card: card,
                        isSelected: vm.selectedId == card.id,
                        onTap: () => vm.selectCard(card.id),
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
    );
  }

  Widget _buildActionsSection() {
    final hasSelection = vm.selectedId != 0;

    return AutonannySectionContainer(
      title: 'Управление картами',
      subtitle: 'Выбранную карту можно использовать для текущей операции.',
      child: Column(
        children: [
          if (!hasSelection)
            const Padding(
              padding: EdgeInsets.only(bottom: AutonannySpacing.lg),
              child: AutonannyInlineBanner(
                title: 'Карта не выбрана',
                message:
                    'Нажмите на карточку выше, чтобы выбрать её для оплаты или редактирования.',
                tone: AutonannyBannerTone.info,
                leading: AutonannyIcon(AutonannyIcons.info),
              ),
            ),
          AutonannyButton(
            label: 'Выбрать карту',
            onPressed: hasSelection ? vm.chooseCard : null,
          ),
          const SizedBox(height: AutonannySpacing.sm),
          Row(
            children: [
              Expanded(
                child: AutonannyButton(
                  label: 'Добавить карту',
                  variant: AutonannyButtonVariant.secondary,
                  leading: const AutonannyIcon(AutonannyIcons.add),
                  onPressed: vm.navigateToAddCard,
                ),
              ),
              const SizedBox(width: AutonannySpacing.sm),
              Expanded(
                child: AutonannyButton(
                  label: 'Удалить',
                  variant: AutonannyButtonVariant.danger,
                  onPressed: hasSelection ? vm.deleteCard : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopUpSection() {
    return AutonannySectionContainer(
      title: 'Пополнение баланса',
      subtitle: 'Выберите удобный способ: банковская карта или СБП.',
      child: Column(
        children: [
          const AutonannyInlineBanner(
            title: 'Минимальное пополнение — 100 ₽',
            message:
                'После успешной оплаты баланс обновится автоматически, когда backend подтвердит платеж.',
            tone: AutonannyBannerTone.info,
            leading: AutonannyIcon(AutonannyIcons.wallet),
          ),
          const SizedBox(height: AutonannySpacing.lg),
          AutonannyButton(
            label: 'Пополнить картой',
            leading: const AutonannyIcon(AutonannyIcons.card),
            onPressed: () => vm.navigateToView(
              const AddCardView(usePaymentInstead: true),
            ),
          ),
          const SizedBox(height: AutonannySpacing.sm),
          AutonannyButton(
            label: 'Пополнить по СБП',
            variant: AutonannyButtonVariant.secondary,
            leading: const AutonannyIcon(AutonannyIcons.qr),
            onPressed: () => vm.navigateToView(
              const AddCardView(
                usePaymentInstead: true,
                useSbpPayment: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WalletCardTile extends StatelessWidget {
  const _WalletCardTile({
    required this.card,
    required this.isSelected,
    required this.onTap,
  });

  final UserCardData card;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AutonannyRadii.brXl,
        child: Ink(
          padding: const EdgeInsets.all(AutonannySpacing.lg),
          decoration: BoxDecoration(
            gradient: _gradientFor(card.bank),
            borderRadius: AutonannyRadii.brXl,
            border: Border.all(
              color: isSelected
                  ? const Color(0xFFB9FFD2)
                  : Colors.white.withValues(alpha: 0.12),
              width: isSelected ? 1.6 : 1,
            ),
            boxShadow: AutonannyShadows.card,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    card.bank.isNotEmpty ? card.bank.toUpperCase() : 'КАРТА',
                    style: AutonannyTypography.labelM(
                      color: Colors.white.withValues(alpha: 0.84),
                    ),
                  ),
                  const Spacer(),
                  if (isSelected)
                    const AutonannyBadge(
                      label: 'Выбрана',
                      variant: AutonannyBadgeVariant.success,
                    ),
                ],
              ),
              const SizedBox(height: AutonannySpacing.xl),
              Text(
                card.cardNumber,
                style: AutonannyTypography.h3(
                  color: Colors.white,
                ).copyWith(letterSpacing: 0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  LinearGradient _gradientFor(String bank) {
    switch (bank.toLowerCase()) {
      case 'mir':
      case 'мир':
        return const LinearGradient(
          colors: [Color(0xFF0F9B6F), Color(0xFF34D399)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'mastercard':
        return const LinearGradient(
          colors: [Color(0xFFEF4444), Color(0xFFF59E0B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'visa':
      default:
        return const LinearGradient(
          colors: [Color(0xFF6D4CFF), Color(0xFF4338CA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }
}
