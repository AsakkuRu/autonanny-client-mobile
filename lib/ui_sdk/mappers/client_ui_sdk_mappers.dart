import 'package:autonanny_ui_core/autonanny_ui_core.dart';
import 'package:autonanny_ui_client/autonanny_ui_client.dart';
import 'package:nanny_client/view_models/new_main/active_trip/active_trip_vm.dart';
import 'package:nanny_client/view_models/pages/balance_vm.dart';
import 'package:nanny_client/views/new_main/new_client_main_vm.dart';
import 'package:nanny_core/models/from_api/child_short.dart';
import 'package:nanny_core/models/from_api/drive_and_map/drive_tariff.dart';
import 'package:nanny_core/models/from_api/notification_item.dart'
    as api_notification;
import 'package:nanny_core/models/from_api/user_cards.dart';
import 'package:nanny_core/models/from_api/user_money.dart';

extension NewClientMainVmUiSdkMapper on NewClientMainVM {
  List<TariffOptionData> get tariffOptions => tariffs.map((tariff) {
        return tariff.toUiSdkTariffOption(
          isSelected: selectedTariff?.id == tariff.id,
          routeCalculated: distance > 0 && duration > 0,
        );
      }).toList(growable: false);

  ChildSelectorData get childSelectorData => ChildSelectorData(
        children: children
            .map(
              (child) => child.toUiSdkChildOption(
                isSelected: isChildSelected(child),
              ),
            )
            .toList(growable: false),
      );
}

extension DriveTariffUiSdkMapper on DriveTariff {
  TariffOptionData toUiSdkTariffOption({
    required bool isSelected,
    required bool routeCalculated,
  }) {
    return TariffOptionData(
      id: '$id',
      title: displayTitle,
      priceLabel: routeCalculated
          ? '${(amount ?? 0).toStringAsFixed(0)} ₽'
          : '${(amount ?? 0).toStringAsFixed(0)} ₽/км',
      subtitle: _tariffSubtitle,
      isSelected: isSelected,
    );
  }

  String get _tariffSubtitle {
    final normalizedTitle = (title ?? '').toLowerCase();
    if (normalizedTitle.contains('комфорт+') ||
        normalizedTitle.contains('комфорт +')) {
      return 'бизнес класс';
    }

    return switch (id) {
      1 => 'до 4 детей',
      2 => 'авто 2020+',
      3 => 'бизнес класс',
      _ => 'Фиксированная цена',
    };
  }
}

extension ChildShortUiSdkMapper on ChildShort {
  ChildOptionData toUiSdkChildOption({
    required bool isSelected,
  }) {
    return ChildOptionData(
      id: '$id',
      name: displayName,
      subtitle: surname.isEmpty ? null : surname,
      initials: _initials,
      isSelected: isSelected,
    );
  }

  String get _initials {
    final buffer = StringBuffer();
    if (name.isNotEmpty) buffer.write(name.substring(0, 1).toUpperCase());
    if (surname.isNotEmpty) {
      buffer.write(surname.substring(0, 1).toUpperCase());
    }
    final value = buffer.toString();
    return value.isEmpty ? 'A' : value;
  }
}

extension BalanceVmUiSdkMapper on BalanceVM {
  WalletSummaryData walletSummaryData(UserMoney money) {
    final stats = computeStats(money.history);

    return WalletSummaryData(
      balanceLabel: formatCurrency(money.balance),
      caption:
          '${_compact(stats.totalSpent)} ₽ потрачено · ${stats.tripsCount} поездок',
      actionLabel: 'Пополнить',
    );
  }

  String _compact(double value) {
    if (value == 0) return '0';
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1).replaceAll('.0', '')}к';
    }
    return value.toStringAsFixed(0);
  }
}

extension UserCardDataUiSdkMapper on UserCardData {
  PaymentMethodCardData get paymentMethodCardData => PaymentMethodCardData(
        title: '$_bankDisplayName · $cardNumber',
        subtitle: expDate.isNotEmpty ? 'Срок до $expDate' : 'Банковская карта',
        isSelected: isActive,
      );

  String get _bankDisplayName {
    return switch (bank.toLowerCase()) {
      'visa' => 'Visa',
      'mir' => 'Мир',
      'mastercard' => 'Mastercard',
      _ => bank.isEmpty ? 'Карта' : bank,
    };
  }
}

extension NotificationItemUiSdkMapper on api_notification.NotificationItem {
  NotificationItemData notificationItemData({
    required String timeLabel,
  }) {
    return NotificationItemData(
      title: title,
      message: body,
      timeLabel: timeLabel,
      tone: _tone,
      isUnread: !isRead,
    );
  }

  AutonannyBannerTone get _tone {
    return switch (type) {
      'payment' => AutonannyBannerTone.success,
      'system' => AutonannyBannerTone.warning,
      'referral' => AutonannyBannerTone.info,
      'order' => AutonannyBannerTone.info,
      _ => AutonannyBannerTone.info,
    };
  }
}

extension ActiveTripVmUiSdkMapper on ActiveTripVM {
  TripProgressHeaderData tripProgressHeaderData({
    required String routeLabel,
  }) {
    final currentPhase = _tripPhaseIndex;
    final isCancelled = statusId == 2 || statusId == 3;
    final isCompletedTrip = isFinished;

    return TripProgressHeaderData(
      title: statusText,
      subtitle: _headerSubtitle(routeLabel),
      statusLabel: _headerStatusLabel,
      steps: List<TripProgressStepData>.generate(4, (index) {
        final isCompleted =
            currentPhase > index || (isCompletedTrip && index == 3);
        final isCurrent =
            !isCancelled && !isCompletedTrip && currentPhase == index;

        return TripProgressStepData(
          title: _phaseTitle(index),
          isCompleted: isCompleted,
          isCurrent: isCurrent,
        );
      }, growable: false),
    );
  }

  int get _tripPhaseIndex {
    if (isFinished) return 3;
    if (isInProgress) return 2;
    if (isEnRoute || isArrived) return 1;
    return 0;
  }

  String get _headerStatusLabel {
    if (statusId == 2) return 'Отмена водителем';
    if (statusId == 3) return 'Отменена';
    if (isFinished) return 'Завершена';
    if (isInProgress) return 'В пути';
    if (isArrived) return 'Ожидание';
    if (isEnRoute) return 'Водитель в пути';
    return 'Поиск';
  }

  String _headerSubtitle(String routeLabel) {
    final parts = <String>[];

    if (routeLabel.isNotEmpty && routeLabel != 'Маршрут уточняется') {
      parts.add(routeLabel);
    }

    if (etaMinutes != null &&
        !isSearching &&
        !isFinished &&
        statusId != 2 &&
        statusId != 3) {
      parts.add('$etaMinutes мин');
    }

    if (parts.isNotEmpty) {
      return parts.join(' · ');
    }

    return routeLabel;
  }

  String _phaseTitle(int index) {
    return switch (index) {
      0 => 'Поиск водителя',
      1 => 'Водитель едет к вам',
      2 => 'Ребёнок в машине',
      _ => 'Завершение поездки',
    };
  }
}
