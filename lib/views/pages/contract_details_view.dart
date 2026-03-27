import 'package:flutter/material.dart';
import 'package:nanny_client/ui_sdk/client_ui_sdk.dart';
import 'package:nanny_client/views/rating/driver_rating_details_view.dart';
import 'package:nanny_components/base_views/views/pages/wallet.dart';
import 'package:nanny_core/models/from_api/driver_contact.dart';
import 'package:nanny_core/models/from_api/drive_and_map/schedule.dart';
import 'package:nanny_core/nanny_core.dart';

class ContractDetailsView extends StatelessWidget {
  const ContractDetailsView({
    super.key,
    required this.schedule,
    required this.summaryData,
    required this.dayPanels,
    this.driverContact,
    this.responsesCount = 0,
    this.onOpenSchedule,
    this.onEditContract,
    this.onOpenChat,
    this.onShowQr,
  });

  final Schedule schedule;
  final ContractSummaryCardData summaryData;
  final List<ContractDayPanelData> dayPanels;
  final DriverContact? driverContact;
  final int responsesCount;
  final VoidCallback? onOpenSchedule;
  final VoidCallback? onEditContract;
  final VoidCallback? onOpenChat;
  final VoidCallback? onShowQr;

  @override
  Widget build(BuildContext context) {
    return AutonannyAppScaffold(
      appBar: AutonannyAppBar(
        title: schedule.title.isEmpty ? 'Контракт' : schedule.title,
        leading: AutonannyIconButton(
          icon: const AutonannyIcon(AutonannyIcons.arrowLeft),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AutonannySpacing.xl),
        children: [
          ContractSummaryCard(
            data: summaryData,
          ),
          if (schedule.isPaused == true) ...[
            const SizedBox(height: AutonannySpacing.lg),
            _PausedContractBanner(schedule: schedule),
          ],
          const SizedBox(height: AutonannySpacing.lg),
          if (driverContact != null)
            Column(
              children: [
                AssignedDriverCard(
                  data: driverContact!.assignedDriverCardData,
                  onPrimaryAction: onOpenChat,
                  onSecondaryAction: onShowQr,
                ),
                const SizedBox(height: AutonannySpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: AutonannyButton(
                    label: 'Отзывы и рейтинг',
                    variant: AutonannyButtonVariant.secondary,
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => DriverRatingDetailsView(
                            driverId: driverContact!.id,
                            driverName: driverContact!.fullName,
                            driverPhoto: driverContact!.photo,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            )
          else
            AutonannyInlineBanner(
              title: responsesCount > 0
                  ? 'Есть отклики от водителей'
                  : 'Водитель еще не назначен',
              message: responsesCount > 0
                  ? 'В контракте уже есть отклики. Вы сможете выбрать водителя в расписании.'
                  : 'Контракт сохранен, сейчас система ищет подходящего водителя.',
              tone: responsesCount > 0
                  ? AutonannyBannerTone.info
                  : AutonannyBannerTone.warning,
              leading: AutonannyIcon(
                responsesCount > 0
                    ? AutonannyIcons.people
                    : AutonannyIcons.warning,
              ),
            ),
          const SizedBox(height: AutonannySpacing.lg),
          const AutonannyInlineBanner(
            title: 'Маршруты и дни поездок',
            message:
                'Ниже показан read-only breakdown контракта по дням и маршрутам.',
            tone: AutonannyBannerTone.info,
            leading: AutonannyIcon(AutonannyIcons.calendar),
          ),
          const SizedBox(height: AutonannySpacing.lg),
          if (dayPanels.isEmpty)
            const AutonannyInlineBanner(
              title: 'Маршруты пока не настроены',
              message:
                  'Для этого контракта пока нет маршрутов, поэтому детальный breakdown пуст.',
              tone: AutonannyBannerTone.warning,
              leading: AutonannyIcon(AutonannyIcons.warning),
            )
          else
            ...dayPanels.map(
              (panel) => Padding(
                padding: const EdgeInsets.only(bottom: AutonannySpacing.md),
                child: ContractDayPanel(data: panel),
              ),
            ),
          const SizedBox(height: AutonannySpacing.sm),
          Row(
            children: [
              if (onOpenSchedule != null)
                Expanded(
                  child: AutonannyButton(
                    label: 'Открыть расписание',
                    onPressed: onOpenSchedule,
                  ),
                ),
              if (onOpenSchedule != null && onEditContract != null)
                const SizedBox(width: AutonannySpacing.md),
              if (onEditContract != null)
                Expanded(
                  child: AutonannyButton(
                    label: 'Редактировать',
                    variant: AutonannyButtonVariant.secondary,
                    onPressed: onEditContract,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PausedContractBanner extends StatelessWidget {
  const _PausedContractBanner({
    required this.schedule,
  });

  final Schedule schedule;

  @override
  Widget build(BuildContext context) {
    final colors = context.autonannyColors;
    final pauseFrom = _formatPauseDate(schedule.pauseFrom);
    final pauseUntil = _formatPauseDate(schedule.pauseUntil);
    final pauseReason = _formatPauseReason(schedule.pauseReason);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AutonannySectionContainer(
          title: 'Контракт на паузе',
          subtitle: 'Поездки временно остановлены, пока пауза не закончится.',
          trailing: const AutonannyBadge(label: 'На паузе'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AutonannyInlineBanner(
                title: 'Причина паузы',
                message: pauseReason,
                tone: AutonannyBannerTone.warning,
                leading: const AutonannyIcon(AutonannyIcons.warning),
              ),
              const SizedBox(height: AutonannySpacing.md),
              Row(
                children: [
                  Expanded(
                    child: _PauseMetricCard(
                      label: 'Пауза с',
                      value: pauseFrom,
                    ),
                  ),
                  const SizedBox(width: AutonannySpacing.md),
                  Expanded(
                    child: _PauseMetricCard(
                      label: 'Пауза до',
                      value: pauseUntil,
                    ),
                  ),
                ],
              ),
              if (_isBalancePause(schedule.pauseReason)) ...[
                const SizedBox(height: AutonannySpacing.md),
                AutonannyInlineBanner(
                  title: 'Баланс нужно пополнить',
                  message:
                      'Контракт поставлен на паузу из-за нехватки средств. Откройте кошелёк и внесите деньги, чтобы вернуться к поездкам.',
                  tone: AutonannyBannerTone.warning,
                  leading: const AutonannyIcon(AutonannyIcons.wallet),
                  trailing: AutonannyButton(
                    label: 'Пополнить',
                    size: AutonannyButtonSize.medium,
                    variant: AutonannyButtonVariant.secondary,
                    expand: false,
                    onPressed: () => _openWalletTopUp(context),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AutonannySpacing.md),
        AutonannyInlineBanner(
          title: schedule.pauseUntil != null
              ? 'Автовозобновление $pauseUntil'
              : 'Контракт ожидает ручного возобновления',
          message: schedule.pauseUntil != null
              ? 'Когда пауза закончится, контракт снова станет активным автоматически.'
              : 'Сейчас в расписании не будет новых поездок по этому контракту.',
          tone: AutonannyBannerTone.info,
          leading: const AutonannyIcon(AutonannyIcons.calendar),
        ),
        const SizedBox(height: AutonannySpacing.md),
        Container(
          padding: const EdgeInsets.all(AutonannySpacing.lg),
          decoration: BoxDecoration(
            color: colors.surfaceSecondary,
            borderRadius: AutonannyRadii.brLg,
          ),
          child: Text(
            'После снятия паузы вы снова увидите ближайшую поездку, назначенного водителя и детальный breakdown по дням.',
            style: AutonannyTypography.bodyS(
              color: colors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  String _formatPauseDate(String? raw) {
    if (raw == null || raw.isEmpty) {
      return '—';
    }
    return raw.length >= 10 ? raw.substring(0, 10) : raw;
  }

  String _formatPauseReason(String? raw) {
    switch (raw) {
      case 'illness':
        return 'Болезнь или временная нетрудоспособность';
      case 'car_repair':
        return 'Ремонт автомобиля';
      case 'family':
        return 'Семейные обстоятельства';
      case 'vacation':
        return 'Отпуск или командировка';
      case 'insufficient_balance':
      case 'low_balance':
      case 'lack_of_funds':
        return 'Недостаточно средств для продолжения контракта';
      default:
        return (raw == null || raw.isEmpty) ? 'Причина не указана' : raw;
    }
  }

  bool _isBalancePause(String? raw) {
    return raw == 'insufficient_balance' ||
        raw == 'low_balance' ||
        raw == 'lack_of_funds';
  }

  Future<void> _openWalletTopUp(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const WalletView(
          title: 'Пополнение баланса',
          subtitle: 'Выберите способ пополнения',
        ),
      ),
    );

    if (!context.mounted) {
      return;
    }

    final scheduleId = schedule.id;
    if (scheduleId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Не удалось определить контракт для возобновления.'),
        ),
      );
      return;
    }

    final resumeResult = await NannyUsersApi.resumePaymentSchedule(scheduleId);
    if (!context.mounted) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    if (!resumeResult.success) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            resumeResult.errorMessage.isNotEmpty
                ? resumeResult.errorMessage
                : 'Не удалось возобновить контракт после пополнения.',
          ),
        ),
      );
      return;
    }

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          resumeResult.response?.isNotEmpty == true
              ? 'Контракт возобновлён. Следующее списание: ${resumeResult.response}.'
              : 'Контракт успешно возобновлён.',
        ),
      ),
    );
    Navigator.of(context).pop(true);
  }
}

class _PauseMetricCard extends StatelessWidget {
  const _PauseMetricCard({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.autonannyColors;

    return Container(
      padding: const EdgeInsets.all(AutonannySpacing.lg),
      decoration: BoxDecoration(
        color: colors.surfaceSecondary,
        borderRadius: AutonannyRadii.brLg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AutonannyTypography.labelM(
              color: colors.textTertiary,
            ),
          ),
          const SizedBox(height: AutonannySpacing.xs),
          Text(
            value,
            style: AutonannyTypography.h3(
              color: colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
