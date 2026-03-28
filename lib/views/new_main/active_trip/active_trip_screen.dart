import 'package:autonanny_ui_client/autonanny_ui_client.dart';
import 'package:autonanny_ui_core/autonanny_ui_core.dart';
import 'package:flutter/material.dart';
import 'package:nanny_client/ui_sdk/support/ui_sdk_address_picker.dart';
import 'package:nanny_client/ui_sdk/mappers/client_ui_sdk_mappers.dart';
import 'package:nanny_client/view_models/new_main/active_trip/active_trip_session_store.dart';
import 'package:nanny_client/view_models/new_main/active_trip/active_trip_vm.dart';
import 'package:nanny_client/views/rating/driver_rating_view.dart';
import 'package:nanny_client/views/rating/driver_rating_details_view.dart';
import 'package:nanny_components/dialogs/driver_qr_dialog.dart';
import 'package:nanny_components/styles/new_design_app.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:nanny_core/api/nanny_orders_api.dart';
import 'package:nanny_core/models/from_api/driver_contact.dart';

class ActiveTripScreen extends StatefulWidget {
  const ActiveTripScreen({
    super.key,
    required this.token,
  });

  final String token;

  @override
  State<ActiveTripScreen> createState() => _ActiveTripScreenState();
}

class _ActiveTripScreenState extends State<ActiveTripScreen> {
  late ActiveTripVM vm;
  bool _isQrDialogOpen = false;
  int _handledRouteChangeResultVersion = 0;
  int _handledTerminalResultVersion = 0;
  int _handledInfoNoticeVersion = 0;

  @override
  void initState() {
    super.initState();
    vm = ActiveTripVM(
      context: context,
      update: setState,
      initialToken: widget.token,
      onTripStarted: () {
        if (_isQrDialogOpen && mounted) {
          Navigator.of(context).pop();
          _isQrDialogOpen = false;
        }
      },
    );
  }

  @override
  void dispose() {
    vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: vm.loadRequest,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const AutonannyAppScaffold(
            body: Center(child: AutonannyLoadingState()),
          );
        }
        if (snapshot.hasError || snapshot.data != true) {
          return AutonannyAppScaffold(
            body: Center(
              child: AutonannyErrorState(
                title: 'Не удалось открыть поездку',
                description:
                    snapshot.error?.toString() ?? 'Попробуйте ещё раз.',
              ),
            ),
          );
        }
        _maybeShowTerminalResultSheet();
        _maybeShowRouteChangeResultSheet();
        _maybeShowInfoNoticeSheet();
        return AutonannyAppScaffold(
          body: Stack(
            children: [
              _LiveTripMap(vm: vm),
              Positioned(
                left: 16,
                top: MediaQuery.of(context).padding.top + 12,
                child: _BackToAppButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ),
              if (vm.canShowSos)
                Positioned(
                  right: 16,
                  top: MediaQuery.of(context).padding.top + 12,
                  child: _SosButton(onPressed: _showSosDialog),
                ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _TripSheet(
                  vm: vm,
                  onCancelPressed: _showCancelDialog,
                  onChangeRoutePressed: _showChangeRouteSheet,
                  onDonePressed: () => Navigator.of(context).pop(),
                  onOpenDriverRating: _openDriverRating,
                  onShowQRPressed: _showMeetingCodeQR,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _maybeShowTerminalResultSheet() {
    final currentVersion = vm.terminalResultVersion;
    if (currentVersion == 0 ||
        currentVersion == _handledTerminalResultVersion) {
      return;
    }
    _handledTerminalResultVersion = currentVersion;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final result = vm.terminalResult;
      if (result == null) {
        return;
      }
      _showTerminalResultSheet(result);
    });
  }

  Future<void> _showTerminalResultSheet(ActiveTripTerminalResult result) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: _TripActionSheet(
          title: result.title,
          subtitle: _formatTripRouteLabel(vm.addresses),
          leadingIcon: result.statusId == 11
              ? Icons.check_circle_rounded
              : result.noDriversFound
                  ? Icons.search_off_rounded
                  : Icons.info_outline_rounded,
          leadingColor: result.statusId == 11
              ? NDT.success
              : result.noDriversFound
                  ? NDT.warning
                  : NDT.danger,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AutonannyInlineBanner(
                title: result.title,
                message: result.message,
                tone: result.statusId == 11
                    ? AutonannyBannerTone.success
                    : result.noDriversFound
                        ? AutonannyBannerTone.warning
                        : AutonannyBannerTone.info,
                leading: AutonannyIcon(
                  result.statusId == 11
                      ? AutonannyIcons.checkCircle
                      : result.noDriversFound
                          ? AutonannyIcons.warning
                          : AutonannyIcons.info,
                ),
              ),
              const SizedBox(height: AutonannySpacing.lg),
              AutonannySectionContainer(
                title: 'Что дальше',
                child: Column(
                  children: [
                    _TripActionInfoRow(
                      label: 'Статус',
                      value: result.title,
                      valueColor: result.statusId == 11 ? NDT.success : null,
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: AutonannySpacing.md,
                      ),
                      child: Divider(height: 1),
                    ),
                    _TripActionInfoRow(
                      label: 'Следующий шаг',
                      value: result.supportsDriverRating && vm.orderId != null
                          ? 'Можно сразу оставить оценку водителю'
                          : 'Экран поездки можно безопасно закрыть',
                    ),
                  ],
                ),
              ),
              if (result.statusId == 11 && vm.baseTripPrice > 0) ...[
                const SizedBox(height: AutonannySpacing.lg),
                AutonannySectionContainer(
                  title: 'Финальный расчет',
                  subtitle:
                      'Сумма по завершенной поездке с учетом активного ожидания.',
                  child: Column(
                    children: [
                      _TripActionInfoRow(
                        label: 'Базовая поездка',
                        value:
                            '${vm.baseTripPrice.toStringAsFixed(vm.baseTripPrice.truncateToDouble() == vm.baseTripPrice ? 0 : 2)} ₽',
                      ),
                      if (vm.hasPaidWaiting) ...[
                        const Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: AutonannySpacing.md,
                          ),
                          child: Divider(height: 1),
                        ),
                        _TripActionInfoRow(
                          label: 'Платное ожидание',
                          value: vm.waitingChargeLabel,
                          valueColor: NDT.warning,
                        ),
                      ],
                      const Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: AutonannySpacing.md,
                        ),
                        child: Divider(height: 1),
                      ),
                      _TripActionInfoRow(
                        label: 'Итого',
                        value: vm.currentTripTotalLabel,
                        valueColor: NDT.success,
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AutonannySpacing.lg),
              if (result.supportsDriverRating && vm.orderId != null) ...[
                SizedBox(
                  height: 52,
                  child: FilledButton(
                    onPressed: () async {
                      Navigator.of(ctx).pop();
                      await _openDriverRating();
                      if (!mounted) return;
                      Navigator.of(context).pop();
                    },
                    child: const Text('Оценить водителя'),
                  ),
                ),
                const SizedBox(height: AutonannySpacing.sm),
              ],
              SizedBox(
                height: 52,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    result.supportsDriverRating ? 'Позже' : 'Закрыть',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showSosDialog() async {
    if (!vm.canShowSos) {
      return;
    }

    final tripChildren = _extractTripChildren(vm.children);
    final childNames = tripChildren
        .map((child) => child.fullName)
        .where((name) => name.isNotEmpty)
        .join(', ');

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.all(20),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Вызов SOS', style: NDT.h2.copyWith(color: NDT.neutral900)),
              const SizedBox(height: 8),
              Text(
                childNames.isEmpty
                    ? 'Будет отправлен сигнал администратору и экстренным контактам.'
                    : 'Будет отправлен сигнал администратору и экстренным контактам по поездке с детьми: $childNames.',
                style: NDT.bodyM.copyWith(color: NDT.neutral500),
                textAlign: TextAlign.center,
              ),
              if (tripChildren.isNotEmpty) ...[
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    for (final child in tripChildren)
                      AutonannyBadge(
                        label: child.fullName.isNotEmpty
                            ? child.fullName
                            : 'Ребенок',
                        variant: AutonannyBadgeVariant.warning,
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              AutonannyButton(
                label: 'Подтвердить SOS',
                onPressed: () async {
                  Navigator.of(context).pop();
                  await vm.confirmSos();
                },
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Отмена — все хорошо'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showMeetingCodeQR() async {
    if (vm.isBusy) return;
    final data = await vm.fetchMeetingCodeForTrip();
    if (!mounted) return;
    if (data == null) {
      await _showTripInfoSheet(
        title: 'Код недоступен',
        message:
            'Водитель ещё не сгенерировал код. Попросите водителя нажать «Включить режим ожидания» в приложении.',
      );
      return;
    }
    final meetingCode = data['meeting_code'] as String?;
    final orderId = data['order_id'] as int?;
    final scheduleRoadId = data['schedule_road_id'] as int?;
    final verificationScope = data['verification_scope'] as String? ?? 'order';
    if (meetingCode == null || meetingCode.isEmpty) {
      await _showTripInfoSheet(
        title: 'Код недоступен',
        message:
            'Водитель ещё не сгенерировал код. Попросите водителя нажать «Включить режим ожидания» в приложении.',
      );
      return;
    }
    final String qrData;
    if (verificationScope == 'schedule' && scheduleRoadId != null) {
      qrData = 'schedule:$scheduleRoadId:$meetingCode';
    } else if (orderId != null) {
      qrData = 'order:$orderId:$meetingCode';
    } else {
      await _showTripInfoSheet(
        title: 'Код недоступен',
        message: 'Не удалось определить тип поездки для верификации.',
      );
      return;
    }
    _isQrDialogOpen = true;
    await DriverQRDialog.show(
      context,
      driverName: 'Водитель',
      qrData: qrData,
      meetingCodePin: meetingCode,
    );
    if (mounted) _isQrDialogOpen = false;
  }

  Future<void> _showTripInfoSheet({
    required String title,
    required String message,
    bool isError = false,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _TripActionSheet(
        title: title,
        subtitle: _formatTripRouteLabel(vm.addresses),
        leadingIcon:
            isError ? Icons.error_outline_rounded : Icons.info_outline_rounded,
        leadingColor: isError ? NDT.danger : NDT.warning,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AutonannyInlineBanner(
              title: title,
              message: message,
              tone: isError
                  ? AutonannyBannerTone.danger
                  : AutonannyBannerTone.info,
              leading: AutonannyIcon(
                isError ? AutonannyIcons.warning : AutonannyIcons.info,
              ),
            ),
            const SizedBox(height: AutonannySpacing.xl),
            AutonannyButton(
              label: 'Понятно',
              onPressed: () => Navigator.of(ctx).pop(),
            ),
          ],
        ),
      ),
    );
  }

  void _maybeShowInfoNoticeSheet() {
    final currentVersion = vm.infoNoticeVersion;
    if (currentVersion == 0 || currentVersion == _handledInfoNoticeVersion) {
      return;
    }
    _handledInfoNoticeVersion = currentVersion;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final notice = vm.infoNotice;
      if (notice == null) {
        return;
      }
      _showTripInfoSheet(
        title: notice.title,
        message: notice.message,
        isError: notice.isError,
      );
    });
  }

  Future<void> _showCancelDialog() async {
    final routeLabel = _formatTripRouteLabel(vm.addresses);
    final approve = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _TripActionSheet(
        title: 'Отмена поездки',
        subtitle: routeLabel,
        leadingIcon: Icons.close_rounded,
        leadingColor: NDT.danger,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AutonannyInlineBanner(
              title: vm.isArrived
                  ? 'Поздняя отмена со штрафом'
                  : 'Подтвердите отмену поездки',
              message: vm.isArrived
                  ? 'Водитель уже прибыл и ожидает. При отмене удерживается 50% стоимости поездки в пользу водителя.'
                  : 'Поездка будет остановлена, а водитель получит уведомление об отмене.',
              tone: vm.isArrived
                  ? AutonannyBannerTone.danger
                  : AutonannyBannerTone.info,
              leading: AutonannyIcon(
                vm.isArrived ? AutonannyIcons.error : AutonannyIcons.info,
              ),
            ),
            const SizedBox(height: AutonannySpacing.lg),
            AutonannySectionContainer(
              title: 'Что произойдет сейчас',
              padding: const EdgeInsets.all(AutonannySpacing.lg),
              child: Column(
                children: [
                  _TripActionInfoRow(
                    label: 'Статус поездки',
                    value: vm.isArrived
                        ? 'Водитель уже на месте'
                        : 'Поездка еще не началась',
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: AutonannySpacing.md,
                    ),
                    child: Divider(height: 1),
                  ),
                  _TripActionInfoRow(
                    label: 'Удержание',
                    value: vm.isArrived
                        ? '50% от стоимости поездки'
                        : 'Без дополнительного удержания',
                    valueColor: vm.isArrived ? NDT.danger : null,
                  ),
                  if (vm.hasPaidWaiting) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: AutonannySpacing.md,
                      ),
                      child: Divider(height: 1),
                    ),
                    _TripActionInfoRow(
                      label: 'Платное ожидание',
                      value: vm.waitingChargeLabel,
                      valueColor: NDT.warning,
                    ),
                  ],
                  const Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: AutonannySpacing.md,
                    ),
                    child: Divider(height: 1),
                  ),
                  _TripActionInfoRow(
                    label: 'Компенсация',
                    value: vm.isArrived
                        ? 'Переводится водителю'
                        : 'Отмена без компенсации',
                  ),
                  if (vm.hasPaidWaiting) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: AutonannySpacing.md,
                      ),
                      child: Divider(height: 1),
                    ),
                    _TripActionInfoRow(
                      label: 'Сумма на сейчас',
                      value: vm.currentTripTotalLabel,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AutonannySpacing.lg),
            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                style: FilledButton.styleFrom(
                  backgroundColor: NDT.danger,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Все равно отменить'),
              ),
            ),
            const SizedBox(height: AutonannySpacing.sm),
            SizedBox(
              height: 52,
              child: OutlinedButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                style: OutlinedButton.styleFrom(
                  foregroundColor: NDT.neutral700,
                  side: const BorderSide(color: NDT.neutral300),
                ),
                child: const Text('Не отменять'),
              ),
            ),
          ],
        ),
      ),
    );
    if (approve != true) return;
    final cancelled = await vm.cancelSearchOrTrip();
    if (cancelled != null && mounted) {
      await _showCancellationResultSheet(cancelled);
      if (!mounted) return;
      Navigator.of(context).pop();
    }
  }

  Future<void> _showCancellationResultSheet(
    OrderCancellationResult result,
  ) async {
    final hasPenalty = result.hasPenalty;
    final penaltyLabel = hasPenalty
        ? '${result.penalty.toStringAsFixed(result.penalty.truncateToDouble() == result.penalty ? 0 : 2)} ₽'
        : null;
    final hasSettlement = result.hasSettlementBreakdown || vm.hasPaidWaiting;
    final basePriceLabel = result.basePrice == null
        ? '${vm.baseTripPrice.toStringAsFixed(vm.baseTripPrice.truncateToDouble() == vm.baseTripPrice ? 0 : 2)} ₽'
        : '${result.basePrice!.toStringAsFixed(result.basePrice!.truncateToDouble() == result.basePrice! ? 0 : 2)} ₽';
    final waitingChargeLabel = result.waitingCharge == null
        ? vm.waitingChargeLabel
        : '${result.waitingCharge!.toStringAsFixed(result.waitingCharge!.truncateToDouble() == result.waitingCharge! ? 0 : 2)} ₽';
    final currentTotalLabel = result.currentTotalPrice == null
        ? vm.currentTripTotalLabel
        : '${result.currentTotalPrice!.toStringAsFixed(result.currentTotalPrice!.truncateToDouble() == result.currentTotalPrice! ? 0 : 2)} ₽';
    final waitingMinutes = result.waitingSeconds == null
        ? (vm.waitingSeconds / 60).ceil()
        : (result.waitingSeconds! / 60).ceil();

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _TripActionSheet(
        title: hasPenalty ? 'Поездка отменена со штрафом' : 'Поездка отменена',
        subtitle: _formatTripRouteLabel(vm.addresses),
        leadingIcon: hasPenalty
            ? Icons.warning_amber_rounded
            : Icons.check_circle_rounded,
        leadingColor: hasPenalty ? NDT.danger : NDT.success,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AutonannyInlineBanner(
              title: hasPenalty
                  ? 'Списан штраф за позднюю отмену'
                  : 'Водитель уже уведомлен',
              message: hasPenalty
                  ? 'Поездка была отменена после прибытия водителя. С баланса будет удержано $penaltyLabel.'
                  : 'Активная поездка закрыта, водитель получил уведомление об отмене.',
              tone: hasPenalty
                  ? AutonannyBannerTone.danger
                  : AutonannyBannerTone.success,
              leading: AutonannyIcon(
                hasPenalty
                    ? AutonannyIcons.warning
                    : AutonannyIcons.checkCircle,
              ),
            ),
            const SizedBox(height: AutonannySpacing.lg),
            AutonannySectionContainer(
              title: 'Итог',
              child: Column(
                children: [
                  _TripActionInfoRow(
                    label: 'Статус',
                    value: hasPenalty ? 'Отменена со штрафом' : 'Отменена',
                    valueColor: hasPenalty ? NDT.danger : null,
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: AutonannySpacing.md,
                    ),
                    child: Divider(height: 1),
                  ),
                  _TripActionInfoRow(
                    label: hasPenalty ? 'Списание' : 'Сообщение',
                    value: hasPenalty
                        ? penaltyLabel!
                        : 'Без дополнительных списаний',
                    valueColor: hasPenalty ? NDT.danger : null,
                  ),
                  if (hasSettlement) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: AutonannySpacing.md,
                      ),
                      child: Divider(height: 1),
                    ),
                    _TripActionInfoRow(
                      label: 'Базовая стоимость',
                      value: basePriceLabel,
                    ),
                    const SizedBox(height: AutonannySpacing.sm),
                    _TripActionInfoRow(
                      label: 'Платное ожидание',
                      value: waitingChargeLabel,
                    ),
                    const SizedBox(height: AutonannySpacing.sm),
                    _TripActionInfoRow(
                      label: 'Ожидание',
                      value: '$waitingMinutes мин',
                    ),
                    const SizedBox(height: AutonannySpacing.sm),
                    _TripActionInfoRow(
                      label: 'Сумма на момент отмены',
                      value: currentTotalLabel,
                      valueColor: NDT.neutral700,
                    ),
                  ],
                  if (vm.hasPaidWaiting) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: AutonannySpacing.md,
                      ),
                      child: Divider(height: 1),
                    ),
                    _TripActionInfoRow(
                      label: 'Платное ожидание',
                      value: vm.waitingChargeLabel,
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: AutonannySpacing.md,
                      ),
                      child: Divider(height: 1),
                    ),
                    _TripActionInfoRow(
                      label: 'Сумма на момент отмены',
                      value: vm.currentTripTotalLabel,
                    ),
                  ],
                ],
              ),
            ),
            if (result.message.trim().isNotEmpty) ...[
              const SizedBox(height: AutonannySpacing.md),
              Text(
                result.message.trim(),
                style: NDT.bodyS.copyWith(color: NDT.neutral500),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: AutonannySpacing.lg),
            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Понятно'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openDriverRating() async {
    final activeOrderId = vm.orderId;
    if (activeOrderId == null) {
      await _showTripInfoSheet(
        title: 'Оценка пока недоступна',
        message:
            'Не удалось определить завершенную поездку. Попробуйте открыть оценку из истории поездок.',
      );
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DriverRatingView(
          orderId: activeOrderId,
          driverName: vm.driverContact?.fullName,
          driverPhoto: vm.driverContact?.photo,
        ),
      ),
    );
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _showChangeRouteSheet() async {
    final routePoints = _buildRouteDisplayPoints(vm.addresses);
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _TripActionSheet(
        title: 'Изменить маршрут',
        subtitle: _formatTripRouteLabel(vm.addresses),
        leadingIcon: Icons.alt_route_rounded,
        leadingColor: NDT.primary,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AutonannyInlineBanner(
              title: 'Запрос уйдет водителю',
              message:
                  'Водитель получит обновленный маршрут и сможет принять или отклонить изменение.',
              tone: AutonannyBannerTone.info,
              leading: AutonannyIcon(AutonannyIcons.info),
            ),
            const SizedBox(height: AutonannySpacing.lg),
            if (routePoints.isNotEmpty)
              _RouteEditPreviewCard(
                points: routePoints,
              ),
            if (routePoints.isNotEmpty)
              const SizedBox(height: AutonannySpacing.lg),
            AutonannySectionContainer(
              title: 'Как изменить маршрут',
              subtitle: 'Выберите способ указания нового адреса.',
              child: Column(
                children: [
                  _TripActionCard(
                    title: 'Поиск по адресу',
                    subtitle: 'Найти новую точку через поиск и подсказки',
                    icon: Icons.search_rounded,
                    iconColor: NDT.primary,
                    iconBackground: NDT.primary100,
                    onTap: () => Navigator.of(ctx).pop('search'),
                  ),
                  const SizedBox(height: AutonannySpacing.sm),
                  _TripActionCard(
                    title: 'Указать на карте',
                    subtitle: 'Поставить новую точку вручную на карте',
                    icon: Icons.place_rounded,
                    iconColor: NDT.primary,
                    iconBackground: NDT.primary100,
                    onTap: () => Navigator.of(ctx).pop('map'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    if (choice == null || !mounted) return;

    final selected = choice == 'map'
        ? await showUiSdkAddressPicker(context)
        : await showUiSdkAddressSearchPicker(context);

    if (selected == null || !mounted) return;

    final ok = await vm.submitRouteChange(
      vm.buildRouteChangePayload(selected),
    );
    if (!mounted) return;
    await _showRouteChangeResultSheet(
      success: ok,
      destinationLabel: selected.address,
    );
  }

  Future<void> _showRouteChangeResultSheet({
    required bool success,
    required String destinationLabel,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _TripActionSheet(
        title: success ? 'Маршрут обновляется' : 'Не удалось изменить маршрут',
        subtitle: _formatTripRouteLabel(vm.addresses),
        leadingIcon:
            success ? Icons.alt_route_rounded : Icons.error_outline_rounded,
        leadingColor: success ? NDT.primary : NDT.danger,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AutonannyInlineBanner(
              title:
                  success ? 'Запрос отправлен водителю' : 'Запрос не отправлен',
              message: success
                  ? 'Водитель получит новый адрес и сможет принять обновленный маршрут.'
                  : 'Маршрут остался без изменений. Проверьте подключение к интернету и попробуйте еще раз.',
              tone: success
                  ? AutonannyBannerTone.info
                  : AutonannyBannerTone.danger,
              leading: AutonannyIcon(
                success ? AutonannyIcons.info : AutonannyIcons.error,
              ),
            ),
            const SizedBox(height: AutonannySpacing.lg),
            AutonannySectionContainer(
              title: success ? 'Новая точка маршрута' : 'Что произошло',
              child: Column(
                children: [
                  _TripActionInfoRow(
                    label: success ? 'Новый адрес' : 'Статус',
                    value:
                        success ? destinationLabel : 'Маршрут не был обновлен',
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: AutonannySpacing.md,
                    ),
                    child: Divider(height: 1),
                  ),
                  _TripActionInfoRow(
                    label: 'Дальше',
                    value: success
                        ? (vm.routeChangeStatus.isNotEmpty
                            ? vm.routeChangeStatus
                            : 'Ожидайте подтверждения от водителя')
                        : 'Можно повторить запрос с карты или через поиск',
                  ),
                ],
              ),
            ),
            const SizedBox(height: AutonannySpacing.lg),
            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Понятно'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _maybeShowRouteChangeResultSheet() {
    final currentVersion = vm.routeChangeResultVersion;
    if (currentVersion == 0 ||
        currentVersion == _handledRouteChangeResultVersion) {
      return;
    }
    _handledRouteChangeResultVersion = currentVersion;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final accepted = vm.lastRouteChangeAccepted;
      if (accepted == null) {
        return;
      }
      _showDriverRouteChangeDecisionSheet(
        accepted: accepted,
        destinationLabel: vm.lastRouteChangeDestination ?? 'Маршрут',
      );
    });
  }

  Future<void> _showDriverRouteChangeDecisionSheet({
    required bool accepted,
    required String destinationLabel,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _TripActionSheet(
        title: accepted ? 'Маршрут обновлен' : 'Водитель отклонил изменение',
        subtitle: _formatTripRouteLabel(vm.addresses),
        leadingIcon:
            accepted ? Icons.check_circle_rounded : Icons.block_rounded,
        leadingColor: accepted ? NDT.success : NDT.danger,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AutonannyInlineBanner(
              title: accepted
                  ? 'Водитель подтвердил новый маршрут'
                  : 'Поездка остается на прежнем маршруте',
              message: accepted
                  ? 'Новый адрес принят водителем и уже добавлен в активную поездку.'
                  : 'Водитель не подтвердил изменение. Вы можете попробовать отправить новый маршрут повторно.',
              tone: accepted
                  ? AutonannyBannerTone.success
                  : AutonannyBannerTone.warning,
              leading: AutonannyIcon(
                accepted ? AutonannyIcons.checkCircle : AutonannyIcons.warning,
              ),
            ),
            const SizedBox(height: AutonannySpacing.lg),
            AutonannySectionContainer(
              title: accepted ? 'Новый адрес' : 'Статус маршрута',
              child: Column(
                children: [
                  _TripActionInfoRow(
                    label: accepted ? 'Точка назначения' : 'Решение водителя',
                    value: accepted ? destinationLabel : 'Изменение отклонено',
                    valueColor: accepted ? null : NDT.danger,
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: AutonannySpacing.md,
                    ),
                    child: Divider(height: 1),
                  ),
                  _TripActionInfoRow(
                    label: 'Дальше',
                    value: accepted
                        ? 'Продолжайте поездку по обновленному маршруту'
                        : 'Можно отправить другой адрес или оставить текущий путь',
                  ),
                ],
              ),
            ),
            const SizedBox(height: AutonannySpacing.lg),
            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Понятно'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveTripMap extends StatefulWidget {
  const _LiveTripMap({required this.vm});

  final ActiveTripVM vm;

  @override
  State<_LiveTripMap> createState() => _LiveTripMapState();
}

class _LiveTripMapState extends State<_LiveTripMap> {
  GoogleMapController? _controller;
  LatLng? _lastAnimatedDriver;

  @override
  void didUpdateWidget(covariant _LiveTripMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    _maybeAnimateToDriver();
  }

  void _maybeAnimateToDriver() {
    final driver = _driverLatLng();
    if (driver == null || _controller == null) return;
    if (_lastAnimatedDriver != null &&
        (_lastAnimatedDriver!.latitude - driver.latitude).abs() < 0.0001 &&
        (_lastAnimatedDriver!.longitude - driver.longitude).abs() < 0.0001) {
      return;
    }
    _lastAnimatedDriver = driver;
    _controller!.animateCamera(
      CameraUpdate.newCameraPosition(CameraPosition(target: driver, zoom: 15)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mapCenter = _resolveCenter();
    final markers = _buildMarkers();
    final bottomPanelHeight = MediaQuery.of(context).size.height * 0.42;

    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(target: mapCenter, zoom: 14),
          onMapCreated: (c) {
            _controller = c;
            _maybeAnimateToDriver();
          },
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          markers: markers,
          polylines: widget.vm.routePolylines,
          padding: EdgeInsets.only(bottom: bottomPanelHeight),
        ),
        if (widget.vm.etaMinutes != null)
          Positioned(
            left: 16,
            top: MediaQuery.of(context).padding.top + 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: NDT.primary,
                borderRadius: NDT.brMd,
              ),
              child: Text(
                '${widget.vm.etaMinutes} мин',
                style: NDT.h3.copyWith(color: Colors.white),
              ),
            ),
          ),
        Positioned(
          right: 16,
          top: MediaQuery.of(context).padding.top + 66,
          child: GestureDetector(
            onTap: () async {
              final driver = _driverLatLng();
              if (driver != null) {
                await _controller?.animateCamera(
                  CameraUpdate.newCameraPosition(
                    CameraPosition(target: driver, zoom: 15),
                  ),
                );
              }
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x22000000),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.my_location_rounded, color: NDT.primary),
            ),
          ),
        ),
      ],
    );
  }

  Set<Marker> _buildMarkers() {
    final result = <Marker>{};

    // Show nearby available drivers during search.
    if (widget.vm.isSearching && widget.vm.nearbyDrivers.isNotEmpty) {
      for (final driver in widget.vm.nearbyDrivers) {
        final lat = _toDouble(driver['latitude'] ?? driver['lat']);
        final lon = _toDouble(driver['longitude'] ?? driver['lon']);
        final id = driver['id_driver'] ?? driver['id'] ?? '${lat}_$lon';
        if (lat == null || lon == null) continue;
        result.add(
          Marker(
            markerId: MarkerId('nearby_driver_$id'),
            position: LatLng(lat, lon),
            zIndexInt: 10,
            icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueViolet),
            infoWindow: const InfoWindow(title: 'Доступный водитель'),
          ),
        );
      }
    }

    final driver = _driverLatLng();
    if (driver != null) {
      result.add(
        Marker(
          markerId: const MarkerId('driver_marker'),
          position: driver,
          zIndexInt: 1000,
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: const InfoWindow(title: 'Водитель'),
        ),
      );
    }

    final routePoints = _routePoints();
    for (var i = 0; i < routePoints.length; i++) {
      final point = routePoints[i];
      final markerHue = i == 0
          ? BitmapDescriptor.hueBlue
          : i == routePoints.length - 1
              ? BitmapDescriptor.hueRed
              : BitmapDescriptor.hueOrange;
      final markerTitle = i == 0
          ? 'Откуда'
          : i == routePoints.length - 1
              ? 'Куда'
              : 'Промежуточная точка $i';
      result.add(
        Marker(
          markerId: MarkerId('route_point_$i'),
          position: point.position,
          zIndexInt: i == routePoints.length - 1 ? 110 : 100,
          icon: BitmapDescriptor.defaultMarkerWithHue(markerHue),
          infoWindow: InfoWindow(title: markerTitle, snippet: point.label),
        ),
      );
    }
    return result;
  }

  LatLng _resolveCenter() {
    final driver = _driverLatLng();
    if (driver != null) return driver;
    final routePoints = _routePoints();
    if (routePoints.isNotEmpty) {
      return routePoints.first.position;
    }
    return const LatLng(55.751244, 37.618423);
  }

  List<_RouteDisplayPoint> _routePoints() =>
      _buildRouteDisplayPoints(widget.vm.addresses);

  LatLng? _driverLatLng() {
    final lat = _toDouble(widget.vm.driverLocation?['lat']);
    final lon = _toDouble(widget.vm.driverLocation?['lon']);
    if (lat == null || lon == null) return null;
    return LatLng(lat, lon);
  }

  double? _toDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}

class _TripSheet extends StatefulWidget {
  const _TripSheet({
    required this.vm,
    required this.onCancelPressed,
    required this.onChangeRoutePressed,
    required this.onDonePressed,
    required this.onOpenDriverRating,
    required this.onShowQRPressed,
  });

  final ActiveTripVM vm;
  final VoidCallback onCancelPressed;
  final VoidCallback onChangeRoutePressed;
  final VoidCallback onDonePressed;
  final VoidCallback onOpenDriverRating;
  final VoidCallback onShowQRPressed;

  @override
  State<_TripSheet> createState() => _TripSheetState();
}

class _TripSheetState extends State<_TripSheet> {
  bool _routeExpanded = false;

  @override
  Widget build(BuildContext context) {
    final vm = widget.vm;
    final route = _routeLabel(vm.addresses);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 32,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.62,
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            MediaQuery.of(context).padding.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: NDT.neutral200,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _tripHeroCard(route),
              const SizedBox(height: 16),
              if (vm.driverContact != null) ...[
                _driverCard(),
                if (vm.driverContact?.phone.trim().isNotEmpty == true) ...[
                  const SizedBox(height: 12),
                  _driverCallButton(),
                ],
                if (vm.driverId != null) ...[
                  const SizedBox(height: 12),
                  _driverRatingButton(),
                ],
                const SizedBox(height: 16),
              ],
              if (vm.addresses.isNotEmpty) ...[
                _routeCard(),
                const SizedBox(height: 16),
              ],
              if (vm.children.isNotEmpty) ...[
                _passengersCard(),
                const SizedBox(height: 16),
              ],
              if (vm.serviceTitles.isNotEmpty) ...[
                _servicesCard(),
                const SizedBox(height: 16),
              ],
              if (vm.noDriversFound) ...[
                Text(
                  'В вашем районе сейчас нет доступных водителей.',
                  style: NDT.bodyM.copyWith(color: NDT.neutral500),
                ),
                const SizedBox(height: 12),
                AutonannyButton(
                  label: 'Закрыть',
                  onPressed: widget.onDonePressed,
                ),
              ],
              if (vm.connectionTimedOut) ...[
                Text(
                  'Проблемы соединения. Сессия сохраняется, идет переподключение.',
                  style: NDT.bodyM.copyWith(color: NDT.neutral500),
                ),
                const SizedBox(height: 12),
              ],
              if (vm.statusId == 2) ...[
                Text(
                  'Водитель отменил поездку. Вы можете заказать нового водителя.',
                  style: NDT.bodyM.copyWith(color: NDT.neutral500),
                ),
                const SizedBox(height: 12),
                AutonannyButton(
                  label: 'Закрыть',
                  onPressed: widget.onDonePressed,
                ),
              ] else if (vm.statusId == 3 && !vm.noDriversFound) ...[
                Text(
                  'Поездка уже отменена и больше не активна.',
                  style: NDT.bodyM.copyWith(color: NDT.neutral500),
                ),
                const SizedBox(height: 12),
                AutonannyButton(
                  label: 'Закрыть',
                  onPressed: widget.onDonePressed,
                ),
              ] else if (vm.isFinished) ...[
                Text(
                  'Поездка завершена. Вы можете сразу оценить водителя или вернуться к этому позже в истории.',
                  style: NDT.bodyM.copyWith(color: NDT.neutral500),
                ),
                const SizedBox(height: 12),
                if (vm.orderId != null) ...[
                  AutonannyButton(
                    label: 'Оценить водителя',
                    onPressed: widget.onOpenDriverRating,
                  ),
                  const SizedBox(height: 8),
                ],
                AutonannyButton(
                  label: 'Закрыть',
                  variant: AutonannyButtonVariant.secondary,
                  onPressed: widget.onDonePressed,
                ),
              ] else ...[
                if (vm.isArrived) const SizedBox(height: 24),
                _tripActionsSection(),
                if (vm.routeChangeStatus.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    'Статус изменения: ${vm.routeChangeStatus}',
                    style: NDT.bodyS.copyWith(color: NDT.neutral500),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _tripHeroCard(String route) {
    final vm = widget.vm;
    final headerData = vm.tripProgressHeaderData(routeLabel: route);
    final tripChildren = _extractTripChildren(vm.children);
    final primaryChild = tripChildren.isNotEmpty ? tripChildren.first : null;
    final useGradient = vm.isSearching || vm.isEnRoute;
    final isArrived = vm.isArrived;
    final onDark = useGradient;

    final backgroundColor = switch ((useGradient, isArrived, vm.isInProgress)) {
      (true, _, _) => null,
      (_, true, _) => const Color(0xFFFFF7ED),
      (_, _, true) => Colors.white,
      _ => NDT.neutral50,
    };

    final borderColor = switch ((useGradient, isArrived, vm.isInProgress)) {
      (true, _, _) => Colors.white.withOpacity(0.16),
      (_, true, _) => const Color(0x33F59E0B),
      (_, _, true) => const Color(0x3322C55E),
      _ => NDT.neutral200,
    };

    final titleColor = onDark ? Colors.white : NDT.neutral900;
    final subtitleColor = onDark ? const Color(0xD9FFFFFF) : NDT.neutral500;
    final eyebrowColor = onDark ? const Color(0xB3FFFFFF) : NDT.neutral400;

    final metric = _heroMetric(vm);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: useGradient
            ? context.autonannyComponents.primaryActionGradient
            : null,
        color: backgroundColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _heroEyebrow(vm),
                      style: NDT.caption.copyWith(
                        color: eyebrowColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _heroTitle(vm),
                      style: NDT.h2.copyWith(color: titleColor),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _heroSubtitle(route, primaryChild),
                      style: NDT.bodyS.copyWith(
                        color: subtitleColor,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              if (metric != null) ...[
                const SizedBox(width: 12),
                _heroMetricPill(
                  label: metric.label,
                  value: metric.value,
                  caption: metric.caption,
                  onDark: onDark,
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          _tripStepStrip(
            headerData.steps,
            onDark: onDark,
            arrived: vm.isArrived,
          ),
          if (vm.isSearching) ...[
            const SizedBox(height: 16),
            _heroInfoPanel(
              onDark: onDark,
              icon: Icons.search_rounded,
              title: 'Подбираем ближайшего водителя',
              subtitle:
                  'Обычно подтверждение занимает до 2 минут. Экран можно оставить открытым.',
            ),
          ] else if (vm.isArrived) ...[
            const SizedBox(height: 16),
            _heroArrivalPanel(onDark: onDark),
          ] else if (primaryChild != null) ...[
            const SizedBox(height: 16),
            _heroChildPanel(primaryChild, onDark: onDark),
          ],
        ],
      ),
    );
  }

  String _heroEyebrow(ActiveTripVM vm) {
    if (vm.isArrived) return 'Встреча и посадка';
    if (vm.isInProgress) return 'Активная поездка';
    if (vm.isEnRoute) return 'Водитель в пути';
    if (vm.isSearching) return 'Поиск водителя';
    return 'Поездка';
  }

  String _heroTitle(ActiveTripVM vm) {
    if (vm.isArrived) return 'Водитель прибыл';
    if (vm.isInProgress) return 'Ребенок в пути';
    if (vm.isEnRoute) return 'Водитель едет к вам';
    if (vm.isSearching) return 'Ищем водителя';
    return vm.statusText;
  }

  String _heroSubtitle(String route, _TripChildSummary? child) {
    final childName = child?.name.trim();
    if (widget.vm.isArrived) {
      return childName?.isNotEmpty == true
          ? 'Назовите PIN или покажите QR для $childName. Маршрут: $route'
          : 'Назовите PIN или покажите QR водителю. Маршрут: $route';
    }
    if (widget.vm.isInProgress) {
      return childName?.isNotEmpty == true
          ? '$childName уже в машине. $route'
          : route;
    }
    if (widget.vm.isEnRoute) {
      return childName?.isNotEmpty == true
          ? '$childName готовится к поездке. $route'
          : route;
    }
    return route;
  }

  ({String label, String value, String? caption})? _heroMetric(
      ActiveTripVM vm) {
    if (vm.isArrived && vm.hasWaitingTimer) {
      return (
        label: vm.isWithinFreeWaitingWindow
            ? 'Бесплатное ожидание'
            : 'Платное ожидание',
        value: vm.waitingTimerLabel,
        caption:
            vm.isWithinFreeWaitingWindow ? 'идет таймер' : vm.waitingRateLabel,
      );
    }
    if (vm.isEnRoute) {
      return (
        label: 'До прибытия',
        value: vm.etaMinutes != null ? '${vm.etaMinutes}' : '—',
        caption: 'мин',
      );
    }
    if (vm.isInProgress) {
      return (
        label: 'До точки',
        value: vm.etaMinutes != null ? '${vm.etaMinutes}' : '—',
        caption: 'мин',
      );
    }
    return null;
  }

  Widget _heroMetricPill({
    required String label,
    required String value,
    required String? caption,
    required bool onDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: onDark ? Colors.white.withOpacity(0.14) : NDT.primary100,
        borderRadius: NDT.brLg,
        border: Border.all(
          color: onDark ? Colors.white.withOpacity(0.16) : NDT.primary100,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            label,
            style: NDT.caption.copyWith(
              color: onDark ? const Color(0xCCFFFFFF) : NDT.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: NDT.h2.copyWith(
                  color: onDark ? Colors.white : NDT.neutral900,
                ),
              ),
              if (caption?.isNotEmpty == true) ...[
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    caption!,
                    style: NDT.caption.copyWith(
                      color: onDark ? const Color(0xCCFFFFFF) : NDT.neutral500,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _tripStepStrip(
    List<TripProgressStepData> steps, {
    required bool onDark,
    required bool arrived,
  }) {
    final activeColor = onDark ? Colors.white : NDT.primary;
    final completedColor = onDark ? Colors.white : NDT.success;
    final inactiveBorder =
        onDark ? Colors.white.withOpacity(0.28) : NDT.neutral300;
    final inactiveText = onDark ? const Color(0xB3FFFFFF) : NDT.neutral500;

    return Row(
      children: [
        for (var i = 0; i < steps.length; i++) ...[
          Expanded(
            child: Column(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: steps[i].isCompleted
                        ? completedColor
                        : steps[i].isCurrent
                            ? activeColor
                            : Colors.transparent,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: steps[i].isCompleted || steps[i].isCurrent
                          ? Colors.transparent
                          : inactiveBorder,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: steps[i].isCompleted
                      ? Icon(
                          Icons.check_rounded,
                          size: 16,
                          color: onDark ? NDT.primary : Colors.white,
                        )
                      : Text(
                          '${i + 1}',
                          style: NDT.bodyS.copyWith(
                            color: steps[i].isCurrent
                                ? (onDark ? NDT.primary : Colors.white)
                                : inactiveText,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
                const SizedBox(height: 8),
                Text(
                  _heroStepTitle(i, arrived),
                  textAlign: TextAlign.center,
                  style: NDT.caption.copyWith(
                    color: steps[i].isCompleted || steps[i].isCurrent
                        ? (onDark ? Colors.white : NDT.neutral900)
                        : inactiveText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          if (i != steps.length - 1)
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(bottom: 24),
                height: 2,
                color: steps[i].isCompleted
                    ? (onDark ? Colors.white.withOpacity(0.7) : NDT.success)
                    : (onDark
                        ? Colors.white.withOpacity(0.18)
                        : NDT.neutral200),
              ),
            ),
        ],
      ],
    );
  }

  String _heroStepTitle(int index, bool arrived) {
    return switch (index) {
      0 => 'Поиск',
      1 => arrived ? 'Прибыл' : 'Едет',
      2 => 'В пути',
      _ => 'Доехал',
    };
  }

  Widget _heroInfoPanel({
    required bool onDark,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: onDark ? Colors.white.withOpacity(0.14) : Colors.white,
        borderRadius: NDT.brLg,
        border: Border.all(
          color: onDark ? Colors.white.withOpacity(0.14) : NDT.neutral200,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: onDark ? Colors.white.withOpacity(0.16) : NDT.primary100,
              borderRadius: NDT.brMd,
            ),
            child: Icon(
              icon,
              size: 18,
              color: onDark ? Colors.white : NDT.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: NDT.bodyM.copyWith(
                    color: onDark ? Colors.white : NDT.neutral900,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: NDT.bodyS.copyWith(
                    color: onDark ? const Color(0xD9FFFFFF) : NDT.neutral500,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroChildPanel(_TripChildSummary child, {required bool onDark}) {
    final vm = widget.vm;
    final subtitle = vm.isInProgress
        ? 'Верификация пройдена. Поездка уже активна.'
        : vm.isEnRoute
            ? 'Маршрут подтвержден. При встрече покажите PIN или QR.'
            : 'Пассажир текущей поездки.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: onDark ? Colors.white.withOpacity(0.14) : Colors.white,
        borderRadius: NDT.brLg,
        border: Border.all(
          color: onDark ? Colors.white.withOpacity(0.14) : NDT.neutral200,
        ),
      ),
      child: Row(
        children: [
          AutonannyAvatar(
            imageUrl: child.photoUrl,
            initials: child.initials,
            size: 44,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  child.fullName.isNotEmpty
                      ? child.fullName
                      : 'Пассажир поездки',
                  style: NDT.bodyM.copyWith(
                    color: onDark ? Colors.white : NDT.neutral900,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: NDT.bodyS.copyWith(
                    color: onDark ? const Color(0xD9FFFFFF) : NDT.neutral500,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          if (vm.isInProgress)
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: onDark
                    ? Colors.white.withOpacity(0.16)
                    : const Color(0x1422C55E),
                borderRadius: NDT.brMd,
              ),
              child: Icon(
                Icons.check_circle_rounded,
                size: 18,
                color: onDark ? Colors.white : NDT.success,
              ),
            ),
        ],
      ),
    );
  }

  Widget _heroArrivalPanel({required bool onDark}) {
    final vm = widget.vm;
    final pinLabel =
        vm.pinCode == null ? '----' : vm.pinCode.toString().padLeft(4, '0');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _heroInfoPanel(
          onDark: onDark,
          icon: Icons.access_time_filled_rounded,
          title: vm.waitingStatusTitle,
          subtitle: vm.waitingStatusHint,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _heroMetricPill(
                label: 'Таймер',
                value: vm.waitingTimerLabel,
                caption: vm.isWithinFreeWaitingWindow ? 'идет' : null,
                onDark: false,
              ),
            ),
            if (vm.hasPaidWaiting) ...[
              const SizedBox(width: 8),
              Expanded(
                child: _heroMetricPill(
                  label: 'Доплата',
                  value: vm.waitingChargeLabel,
                  caption: null,
                  onDark: false,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: NDT.brLg,
            border: Border.all(color: const Color(0x33F59E0B)),
          ),
          child: Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: NDT.primary100,
                  borderRadius: NDT.brMd,
                ),
                child: Text(
                  pinLabel,
                  style: NDT.h2.copyWith(
                    color: NDT.primary,
                    letterSpacing: 4,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PIN для водителя',
                      style: NDT.bodyM.copyWith(
                        color: NDT.neutral900,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Назовите код или откройте QR для верификации встречи.',
                      style: NDT.bodyS.copyWith(
                        color: NDT.neutral500,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AutonannyButton(
          label: 'Показать QR-код',
          onPressed: vm.isBusy ? null : widget.onShowQRPressed,
        ),
      ],
    );
  }

  Widget _tripActionsSection() {
    final vm = widget.vm;
    if (vm.isTerminalState) {
      return const SizedBox.shrink();
    }
    final hasCancelAction = !vm.isInProgress;
    final hasRouteAction = vm.statusId != 15;

    if (!hasCancelAction && !hasRouteAction) {
      return const SizedBox.shrink();
    }

    return AutonannySectionContainer(
      title: 'Действия с поездкой',
      subtitle: vm.isArrived
          ? 'Пока водитель ожидает, отмена может привести к удержанию.'
          : 'Измените маршрут или отмените поездку до начала движения.',
      child: Column(
        children: [
          if (hasRouteAction) ...[
            _TripActionCard(
              title: 'Изменить маршрут',
              subtitle: 'Адрес отправления или назначения',
              icon: Icons.alt_route_rounded,
              iconColor: NDT.primary,
              iconBackground: NDT.primary100,
              onTap: vm.isBusy ? null : widget.onChangeRoutePressed,
            ),
            if (hasCancelAction) const SizedBox(height: AutonannySpacing.sm),
          ],
          if (hasCancelAction)
            _TripActionCard(
              title: 'Отменить поездку',
              subtitle: vm.isArrived
                  ? 'Водитель уже ждет. Возможен штраф 50%.'
                  : 'Поиск и текущая поездка будут остановлены',
              icon: Icons.close_rounded,
              iconColor: NDT.danger,
              iconBackground: NDT.danger.withOpacity(0.1),
              borderColor: NDT.danger.withOpacity(0.18),
              backgroundColor: NDT.danger.withOpacity(0.04),
              titleColor: NDT.danger,
              subtitleColor: const Color(0xFFB91C1C),
              onTap: vm.isBusy ? null : widget.onCancelPressed,
            ),
        ],
      ),
    );
  }

  Widget _routeCard() {
    final vm = widget.vm;
    final points = _buildTripRouteTimelinePoints(vm.addresses);
    if (points.isEmpty) return const SizedBox.shrink();
    final intermediateCount = points.length > 2 ? points.length - 2 : 0;

    return Container(
      decoration: BoxDecoration(
        color: NDT.neutral50,
        borderRadius: NDT.brXl,
        border: Border.all(color: NDT.neutral200),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: NDT.primary100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.route_rounded,
                  size: 18,
                  color: NDT.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Маршрут поездки', style: NDT.h3),
                    Text(
                      'Ключевые точки маршрута',
                      style: NDT.bodyS.copyWith(color: NDT.neutral500),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _routeExpanded = !_routeExpanded;
                  });
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  visualDensity: VisualDensity.compact,
                  foregroundColor: NDT.primary,
                ),
                icon: Icon(
                  _routeExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  size: 18,
                ),
                label: Text(
                  _routeExpanded ? 'Свернуть' : 'Весь маршрут',
                  style: NDT.caption.copyWith(
                    color: NDT.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _ClientRouteSummaryCard(
            start: points.first,
            end: points.last,
            intermediateCount: intermediateCount,
          ),
          if (_routeExpanded) ...[
            const SizedBox(height: 12),
            Divider(height: 1, color: NDT.neutral200),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: points.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                return _ClientRouteTimelineRow(
                  point: points[index],
                  isLast: index == points.length - 1,
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _passengersCard() {
    final children = _extractTripChildren(widget.vm.children);
    if (children.isEmpty) {
      return const SizedBox.shrink();
    }

    final subtitle = switch ((widget.vm.isInProgress, widget.vm.isArrived)) {
      (true, _) => 'Дети, связанные с активной поездкой',
      (_, true) => 'Подготовьте детей к посадке и верификации встречи',
      _ => 'Состав пассажиров по активной поездке',
    };

    return AutonannySectionContainer(
      title: 'Кто в поездке',
      subtitle: subtitle,
      trailing: AutonannyBadge(label: '${children.length} детей'),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AutonannyListRow(
                  padding: EdgeInsets.zero,
                  leading: AutonannyAvatar(
                    imageUrl: children[i].photoUrl,
                    initials: children[i].initials,
                    size: 44,
                  ),
                  title: children[i].fullName.isNotEmpty
                      ? children[i].fullName
                      : 'Ребенок ${i + 1}',
                  subtitle: widget.vm.isInProgress
                      ? 'Поездка активна'
                      : widget.vm.isArrived
                          ? 'Ожидает посадку'
                          : 'Пассажир поездки',
                ),
                if (_childContextBadges(children[i]).isNotEmpty ||
                    _childContextNotes(children[i]).isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 56,
                      top: AutonannySpacing.sm,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_childContextBadges(children[i]).isNotEmpty)
                          Wrap(
                            spacing: AutonannySpacing.sm,
                            runSpacing: AutonannySpacing.sm,
                            children: _childContextBadges(children[i])
                                .map(
                                  (badge) => AutonannyBadge(label: badge),
                                )
                                .toList(growable: false),
                          ),
                        if (_childContextNotes(children[i]).isNotEmpty) ...[
                          const SizedBox(height: AutonannySpacing.sm),
                          ..._childContextNotes(children[i]).map(
                            (note) => Padding(
                              padding: const EdgeInsets.only(
                                bottom: AutonannySpacing.xs,
                              ),
                              child: Text(
                                note.$1,
                                style: AutonannyTypography.bodyS(
                                  color: note.$2,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
            if (i != children.length - 1)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AutonannySpacing.md),
                child: Divider(height: 1),
              ),
          ],
        ],
      ),
    );
  }

  List<String> _childContextBadges(_TripChildSummary child) {
    return [
      if (child.age != null) '${child.age} лет',
      if (child.schoolClass != null && child.schoolClass!.isNotEmpty)
        child.schoolClass!,
      if (child.emergencyContactsCount > 0)
        'Контактов: ${child.emergencyContactsCount}',
    ];
  }

  List<(String, Color)> _childContextNotes(_TripChildSummary child) {
    final colors = context.autonannyColors;
    return [
      if (child.allergiesWarning != null && child.allergiesWarning!.isNotEmpty)
        ('Аллергии: ${child.allergiesWarning}', colors.statusDanger),
      if (child.characterNotes != null && child.characterNotes!.isNotEmpty)
        (child.characterNotes!, colors.textSecondary),
    ];
  }

  Widget _servicesCard() {
    final services = widget.vm.serviceTitles;
    if (services.isEmpty) {
      return const SizedBox.shrink();
    }

    final subtitle = switch ((widget.vm.isInProgress, widget.vm.isArrived)) {
      (true, _) => 'Дополнительные условия, которые учтены в текущей поездке',
      (_, true) => 'Услуги уже переданы водителю и учитываются в поездке',
      _ => 'Дополнительные условия заказа, переданные водителю',
    };

    return AutonannySectionContainer(
      title: 'Дополнительные услуги',
      subtitle: subtitle,
      trailing: AutonannyBadge(label: '${services.length} услуг'),
      child: Column(
        children: [
          for (var i = 0; i < services.length; i++) ...[
            AutonannyListRow(
              padding: EdgeInsets.zero,
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: NDT.primary100,
                  borderRadius: NDT.brMd,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.stars_rounded,
                  size: 18,
                  color: NDT.primary,
                ),
              ),
              title: services[i],
              subtitle: widget.vm.isInProgress
                  ? 'Услуга активна в поездке'
                  : 'Будет учтена при выполнении поездки',
            ),
            if (i != services.length - 1)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AutonannySpacing.md),
                child: Divider(height: 1),
              ),
          ],
        ],
      ),
    );
  }

  Widget _driverCard() {
    final driver = widget.vm.driverContact;
    if (driver == null) {
      return const SizedBox.shrink();
    }

    return AssignedDriverCard(
      data: _activeTripDriverCardData(driver),
      onPrimaryAction: widget.vm.openAssignedDriverProfile,
      onSecondaryAction:
          widget.vm.chatId != null ? widget.vm.openAssignedDriverChat : null,
    );
  }

  Widget _driverRatingButton() {
    final driver = widget.vm.driverContact;
    final driverId = widget.vm.driverId;
    if (driver == null || driverId == null) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: double.infinity,
      child: AutonannyButton(
        label: 'Отзывы и рейтинг',
        variant: AutonannyButtonVariant.secondary,
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => DriverRatingDetailsView(
                driverId: driverId,
                driverName: driver.fullName,
                driverPhoto: driver.photo,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _driverCallButton() {
    return SizedBox(
      width: double.infinity,
      child: AutonannyButton(
        label: 'Позвонить водителю',
        variant: AutonannyButtonVariant.secondary,
        onPressed: widget.vm.callAssignedDriver,
      ),
    );
  }

  AssignedDriverCardData _activeTripDriverCardData(DriverContact driver) {
    final base = driver.assignedDriverCardData;
    return AssignedDriverCardData(
      name: base.name,
      initials: base.initials,
      photoUrl: base.photoUrl,
      phoneLabel: base.phoneLabel,
      ratingLabel: base.ratingLabel,
      carLabel: base.carLabel,
      caption: widget.vm.isInProgress
          ? 'Назначенный водитель уже ведет поездку'
          : widget.vm.isArrived
              ? 'Водитель уже на месте. Можно открыть профиль или написать в чат.'
              : 'Назначенный водитель по этой поездке',
      primaryActionLabel: 'Профиль',
      secondaryActionLabel: widget.vm.chatId != null ? 'Написать' : null,
    );
  }

  String _routeLabel(List<Map<String, dynamic>> addresses) {
    final labels = _buildRouteDisplayPoints(addresses)
        .map((point) => point.label)
        .where((label) => label.isNotEmpty)
        .toList(growable: false);
    if (labels.isEmpty) return 'Маршрут уточняется';
    return labels.join(' → ');
  }
}

class _ClientRouteSummaryCard extends StatelessWidget {
  const _ClientRouteSummaryCard({
    required this.start,
    required this.end,
    required this.intermediateCount,
  });

  final _ClientRouteTimelinePoint start;
  final _ClientRouteTimelinePoint end;
  final int intermediateCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: NDT.primary100,
        borderRadius: NDT.brMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ClientRouteSummaryRow(
            icon: Icons.trip_origin_rounded,
            label: 'Старт',
            value: start.address,
            color: NDT.primary,
          ),
          const SizedBox(height: 10),
          _ClientRouteSummaryRow(
            icon: Icons.place_rounded,
            label: 'Финиш',
            value: end.address,
            color: NDT.danger,
          ),
          if (intermediateCount > 0) ...[
            const SizedBox(height: 10),
            Text(
              '+ ${_intermediatePointsLabel(intermediateCount)}',
              style: NDT.bodyS.copyWith(color: NDT.neutral500),
            ),
          ],
        ],
      ),
    );
  }
}

class _TripActionSheet extends StatelessWidget {
  const _TripActionSheet({
    required this.title,
    required this.subtitle,
    required this.leadingIcon,
    required this.leadingColor,
    required this.child,
  });

  final String title;
  final String subtitle;
  final IconData leadingIcon;
  final Color leadingColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            20 + MediaQuery.of(context).padding.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: NDT.neutral200,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: AutonannySpacing.lg),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: leadingColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      leadingIcon,
                      color: leadingColor,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: AutonannySpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: NDT.h2),
                        const SizedBox(height: AutonannySpacing.xs),
                        Text(
                          subtitle,
                          style: NDT.bodyS.copyWith(color: NDT.neutral500),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AutonannySpacing.lg),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _TripActionCard extends StatelessWidget {
  const _TripActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.onTap,
    this.backgroundColor,
    this.borderColor,
    this.titleColor,
    this.subtitleColor,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? borderColor;
  final Color? titleColor;
  final Color? subtitleColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: backgroundColor ?? Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: borderColor ?? NDT.neutral200,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: AutonannySpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: NDT.bodyM.copyWith(
                        color: titleColor ?? NDT.neutral900,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AutonannySpacing.xs),
                    Text(
                      subtitle,
                      style: NDT.bodyS.copyWith(
                        color: subtitleColor ?? NDT.neutral500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: titleColor?.withOpacity(0.55) ?? NDT.neutral400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TripActionInfoRow extends StatelessWidget {
  const _TripActionInfoRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: NDT.bodyM.copyWith(color: NDT.neutral500),
          ),
        ),
        const SizedBox(width: AutonannySpacing.md),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: NDT.bodyM.copyWith(
              color: valueColor ?? NDT.neutral900,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _RouteEditPreviewCard extends StatelessWidget {
  const _RouteEditPreviewCard({
    required this.points,
  });

  final List<_RouteDisplayPoint> points;

  @override
  Widget build(BuildContext context) {
    final from = points.first;
    final to = points.last;

    return AutonannySectionContainer(
      title: 'Маршрут поездки',
      subtitle: points.length > 2
          ? '+ ${_intermediatePointsLabel(points.length - 2)} внутри маршрута'
          : 'Изменится адрес отправления или назначения',
      child: Column(
        children: [
          _RouteEditPointRow(
            label: 'Откуда',
            value: from.label,
            color: NDT.primary,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AutonannySpacing.md),
            child: Divider(height: 1),
          ),
          _RouteEditPointRow(
            label: 'Куда',
            value: to.label,
            color: NDT.danger,
          ),
        ],
      ),
    );
  }
}

class _RouteEditPointRow extends StatelessWidget {
  const _RouteEditPointRow({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
        ),
        const SizedBox(width: AutonannySpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: NDT.caption.copyWith(
                  color: NDT.neutral400,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AutonannySpacing.xs),
              Text(
                value,
                style: NDT.bodyM.copyWith(
                  color: NDT.neutral700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TripChildSummary {
  const _TripChildSummary({
    required this.id,
    required this.name,
    required this.surname,
    this.photoUrl,
    this.age,
    this.schoolClass,
    this.characterNotes,
    this.allergiesWarning,
    this.emergencyContactsCount = 0,
  });

  final int? id;
  final String name;
  final String surname;
  final String? photoUrl;
  final int? age;
  final String? schoolClass;
  final String? characterNotes;
  final String? allergiesWarning;
  final int emergencyContactsCount;

  String get fullName => '$name $surname'.trim();

  String get initials {
    final parts = fullName
        .split(' ')
        .where((part) => part.trim().isNotEmpty)
        .toList(growable: false);
    if (parts.isEmpty) {
      return '?';
    }
    if (parts.length == 1) {
      return parts.first.characters.first.toUpperCase();
    }
    return '${parts.first.characters.first}${parts.last.characters.first}'
        .toUpperCase();
  }
}

List<_TripChildSummary> _extractTripChildren(
  List<Map<String, dynamic>> rawChildren,
) {
  return rawChildren
      .map(
        (child) => _TripChildSummary(
          id: child['id'] as int?,
          name: (child['name'] ?? '').toString(),
          surname: (child['surname'] ?? '').toString(),
          photoUrl:
              (child['photo_url'] ?? child['photo_path'] ?? '').toString(),
          age: (child['age'] as num?)?.toInt(),
          schoolClass: child['school_class']?.toString(),
          characterNotes: child['character_notes']?.toString(),
          allergiesWarning: child['allergies_warning']?.toString(),
          emergencyContactsCount:
              (child['emergency_contacts_count'] as num?)?.toInt() ?? 0,
        ),
      )
      .where((child) =>
          child.fullName.isNotEmpty || child.photoUrl?.isNotEmpty == true)
      .toList(growable: false);
}

class _ClientRouteSummaryRow extends StatelessWidget {
  const _ClientRouteSummaryRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: NDT.caption.copyWith(color: color)),
              const SizedBox(height: 2),
              Text(value, style: NDT.bodyS.copyWith(color: NDT.neutral900)),
            ],
          ),
        ),
      ],
    );
  }
}

class _RouteDisplayPoint {
  const _RouteDisplayPoint({
    required this.label,
    required this.position,
  });

  final String label;
  final LatLng position;
}

enum _ClientRoutePointAccent {
  start,
  intermediate,
  finalStop,
}

class _ClientRouteTimelinePoint {
  const _ClientRouteTimelinePoint({
    required this.role,
    required this.address,
    required this.accent,
  });

  final String role;
  final String address;
  final _ClientRoutePointAccent accent;
}

List<_ClientRouteTimelinePoint> _buildTripRouteTimelinePoints(
  List<Map<String, dynamic>> addresses,
) {
  final points = _buildRouteDisplayPoints(addresses);
  if (points.isEmpty) return const [];

  final result = <_ClientRouteTimelinePoint>[
    _ClientRouteTimelinePoint(
      role: 'Точка старта',
      address: points.first.label,
      accent: _ClientRoutePointAccent.start,
    ),
  ];

  if (points.length > 2) {
    for (var i = 1; i < points.length - 1; i++) {
      result.add(
        _ClientRouteTimelinePoint(
          role: 'Промежуточная точка $i',
          address: points[i].label,
          accent: _ClientRoutePointAccent.intermediate,
        ),
      );
    }
  }

  if (points.length > 1) {
    result.add(
      _ClientRouteTimelinePoint(
        role: 'Финальная точка',
        address: points.last.label,
        accent: _ClientRoutePointAccent.finalStop,
      ),
    );
  }

  return result;
}

List<_RouteDisplayPoint> _buildRouteDisplayPoints(
  List<Map<String, dynamic>> addresses,
) {
  if (addresses.isEmpty) return const [];

  final points = <_RouteDisplayPoint>[];
  final first = addresses.first;
  final firstLabel = (first['from_address'] ?? first['from'] ?? '').toString();
  final firstLat = _routeValueToDouble(first['from_lat']);
  final firstLon = _routeValueToDouble(first['from_lon']);
  if (firstLabel.isNotEmpty && firstLat != null && firstLon != null) {
    points.add(
      _RouteDisplayPoint(
        label: firstLabel,
        position: LatLng(firstLat, firstLon),
      ),
    );
  }

  for (final segment in addresses) {
    final label = (segment['to_address'] ?? segment['to'] ?? '').toString();
    final lat = _routeValueToDouble(segment['to_lat']);
    final lon = _routeValueToDouble(segment['to_lon']);
    if (label.isEmpty || lat == null || lon == null) continue;
    points.add(
      _RouteDisplayPoint(
        label: label,
        position: LatLng(lat, lon),
      ),
    );
  }

  return points;
}

String _formatTripRouteLabel(List<Map<String, dynamic>> addresses) {
  final labels = _buildRouteDisplayPoints(addresses)
      .map((point) => point.label)
      .where((label) => label.isNotEmpty)
      .toList(growable: false);
  if (labels.isEmpty) {
    return 'Маршрут уточняется';
  }
  return labels.join(' → ');
}

double? _routeValueToDouble(dynamic value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

String _intermediatePointsLabel(int count) {
  if (count % 10 == 1 && count % 100 != 11) {
    return '$count промежуточная точка';
  }
  if ([2, 3, 4].contains(count % 10) && ![12, 13, 14].contains(count % 100)) {
    return '$count промежуточные точки';
  }
  return '$count промежуточных точек';
}

class _ClientRouteTimelineRow extends StatelessWidget {
  const _ClientRouteTimelineRow({
    required this.point,
    required this.isLast,
  });

  final _ClientRouteTimelinePoint point;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final colors = _colors(point.accent);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 22,
          child: Column(
            children: [
              _ClientRouteMarker(accent: point.accent),
              if (!isLast)
                Container(
                  width: 2,
                  height: 28,
                  margin: const EdgeInsets.symmetric(vertical: 3),
                  decoration: BoxDecoration(
                    color: NDT.neutral300,
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: NDT.brMd,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(point.role, style: NDT.caption.copyWith(color: colors.$2)),
                const SizedBox(height: 4),
                Text(point.address,
                    style: NDT.bodyM.copyWith(color: NDT.neutral900)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  (Color, Color) _colors(_ClientRoutePointAccent accent) {
    switch (accent) {
      case _ClientRoutePointAccent.start:
        return (NDT.primary100, NDT.primary);
      case _ClientRoutePointAccent.intermediate:
        return (NDT.neutral100, NDT.neutral500);
      case _ClientRoutePointAccent.finalStop:
        return (const Color(0xFFFFF1F2), NDT.danger);
    }
  }
}

class _ClientRouteMarker extends StatelessWidget {
  const _ClientRouteMarker({required this.accent});

  final _ClientRoutePointAccent accent;

  @override
  Widget build(BuildContext context) {
    switch (accent) {
      case _ClientRoutePointAccent.start:
        return Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: NDT.primary,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x335B4FCF),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
        );
      case _ClientRoutePointAccent.intermediate:
        return Container(
          width: 10,
          height: 10,
          decoration: const BoxDecoration(
            color: NDT.neutral400,
            shape: BoxShape.circle,
          ),
        );
      case _ClientRoutePointAccent.finalStop:
        return Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: NDT.danger,
            borderRadius: BorderRadius.circular(4),
          ),
        );
    }
  }
}

class _SosButton extends StatelessWidget {
  const _SosButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: NDT.danger,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Color(0x66EF4444),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: const Text(
          'SOS',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

class _BackToAppButton extends StatelessWidget {
  const _BackToAppButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: NDT.neutral0,
          borderRadius: BorderRadius.circular(12),
          boxShadow: NDT.cardShadow,
        ),
        alignment: Alignment.center,
        child: const Icon(
          Icons.arrow_back_rounded,
          size: 20,
          color: NDT.neutral900,
        ),
      ),
    );
  }
}

class ActiveTripRestoreCoordinator {
  static Future<ActiveTripSessionData?> resolveSession() async {
    return ActiveTripSessionStore.load();
  }
}
