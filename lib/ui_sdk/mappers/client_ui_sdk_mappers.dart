import 'package:autonanny_ui_core/autonanny_ui_core.dart';
import 'package:autonanny_ui_client/autonanny_ui_client.dart';
import 'package:nanny_client/view_models/map/drive_order_vm.dart';
import 'package:nanny_client/view_models/new_main/active_trip/active_trip_vm.dart';
import 'package:nanny_client/view_models/pages/balance_vm.dart';
import 'package:nanny_client/views/new_main/new_client_main_vm.dart';
import 'package:nanny_core/constants.dart';
import 'package:nanny_core/models/from_api/child_short.dart';
import 'package:nanny_core/models/from_api/driver_contact.dart';
import 'package:nanny_core/models/from_api/drive_and_map/drive_tariff.dart';
import 'package:nanny_core/models/from_api/drive_and_map/schedule.dart';
import 'package:nanny_core/models/from_api/notification_item.dart'
    as api_notification;
import 'package:nanny_core/models/from_api/other_parametr.dart';
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

  TripRequestSummaryData get tripRequestSummaryData => TripRequestSummaryData(
        routeLabel: _routeLabel(
          addresses
              .map((address) => address.address.trim())
              .where((address) => address.isNotEmpty)
              .toList(growable: false),
        ),
        priceLabel: _priceLabel(totalEstimatedPrice),
        tariffLabel: selectedTariff?.displayTitle ?? 'Тариф не выбран',
        servicesLabel: _selectedServicesLabel(
          additionalParams.where(isAdditionalParamSelected).toList(),
        ),
        childLabel: selectedChildren.isEmpty
            ? 'Дети не выбраны'
            : selectedChildren.map((child) => child.fullName).join(', '),
        distanceLabel:
            distance > 0 ? '${distance.toStringAsFixed(1)} км' : null,
        durationLabel:
            duration > 0 ? '${duration.toStringAsFixed(0)} мин' : null,
        caption: _buildTripRequestCaption(
          baseCaption:
              'Проверьте параметры разовой поездки перед отправкой заказа.',
          additionalServicesTotal: selectedAdditionalServicesTotal,
        ),
      );
}

extension DriveOrderVmUiSdkMapper on DriveOrderVM {
  List<AddressEditorItemData> get addressEditorItems {
    return List.generate(addresses.length, (index) {
      final address = addresses[index];
      final isFirst = index == 0;
      final isLast = index == addresses.length - 1;

      return AddressEditorItemData(
        id: '$index',
        title: address.address.trim().isEmpty
            ? 'Адрес не указан'
            : address.address.trim(),
        subtitle: selectedAddressIndex == index
            ? 'Нажмите на карту для уточнения'
            : switch ((isFirst, isLast)) {
                (true, _) => 'Точка отправления',
                (_, true) => 'Точка прибытия',
                _ => 'Промежуточная точка',
              },
        kind: switch ((isFirst, isLast)) {
          (true, _) => AddressEditorItemKind.origin,
          (_, true) => AddressEditorItemKind.destination,
          _ => AddressEditorItemKind.waypoint,
        },
        isSelected: selectedAddressIndex == index,
        canDelete: index > 1,
      );
    });
  }

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

  TripRequestSummaryData get tripRequestSummaryData => TripRequestSummaryData(
        routeLabel: _routeLabel(
          addresses
              .map((address) => address.address.trim())
              .where((address) => address.isNotEmpty)
              .toList(growable: false),
        ),
        priceLabel: _priceLabel(totalEstimatedPrice),
        tariffLabel: selectedTariff?.displayTitle ?? 'Тариф не выбран',
        servicesLabel: _selectedServicesLabel(
          additionalParams.where(isAdditionalParamSelected).toList(),
        ),
        childLabel: selectedChildren.isEmpty
            ? 'Дети не выбраны'
            : selectedChildren.map((child) => child.fullName).join(', '),
        distanceLabel:
            distance > 0 ? '${distance.toStringAsFixed(1)} км' : null,
        durationLabel:
            duration > 0 ? '${duration.toStringAsFixed(0)} мин' : null,
        caption: _buildTripRequestCaption(
          baseCaption:
              'Сводка собирается из текущего маршрута, выбранного тарифа и детей поездки.',
          additionalServicesTotal: selectedAdditionalServicesTotal,
        ),
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

String _routeLabel(List<String> addresses) {
  if (addresses.isEmpty) {
    return 'Маршрут уточняется';
  }
  if (addresses.length == 1) {
    return addresses.first;
  }

  final first = addresses.first;
  final last = addresses.last;
  final middleCount = addresses.length - 2;

  if (middleCount <= 0) {
    return '$first -> $last';
  }

  return '$first -> $last · +$middleCount точк.';
}

String _priceLabel(double? amount) {
  if (amount == null || amount <= 0) {
    return 'Стоимость уточняется';
  }

  return '~ ${amount.round()} ₽';
}

String _selectedServicesLabel(List<OtherParametr> params) {
  final labels = params
      .map((param) => (param.title ?? '').trim())
      .where((label) => label.isNotEmpty)
      .toList(growable: false);

  if (labels.isEmpty) {
    return 'Без дополнительных услуг';
  }

  return labels.join(', ');
}

String _buildTripRequestCaption({
  required String baseCaption,
  required double additionalServicesTotal,
}) {
  if (additionalServicesTotal <= 0) {
    return baseCaption;
  }

  return '$baseCaption В итоговую сумму уже включены доп. услуги на ${additionalServicesTotal.round()} ₽.';
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

extension DriverContactUiSdkMapper on DriverContact {
  AssignedDriverCardData get assignedDriverCardData {
    final ratingParts = <String>[];
    if (rating != null) {
      ratingParts.add('Рейтинг ${rating!.toStringAsFixed(1)}');
    }
    if (reviewsCount != null && reviewsCount! > 0) {
      ratingParts.add('$reviewsCount отзывов');
    }

    return AssignedDriverCardData(
      name: fullName,
      initials: _initials,
      photoUrl: photo,
      phoneLabel: phone,
      ratingLabel: ratingParts.isEmpty ? null : ratingParts.join(' · '),
      carLabel: _carLabel,
      caption: experienceYears == null
          ? null
          : 'Опыт работы: $experienceYears ${_yearsLabel(experienceYears!)}',
      primaryActionLabel: 'Написать',
      secondaryActionLabel: 'Показать QR',
    );
  }

  String get _initials {
    final first = surname.trim().isEmpty ? '' : surname.trim().substring(0, 1);
    final second = name.trim().isEmpty ? '' : name.trim().substring(0, 1);
    final value = '$first$second'.toUpperCase();
    return value.isEmpty ? 'A' : value;
  }

  String? get _carLabel {
    final info = car?.fullInfo.trim() ?? '';
    final colorAndNumber = car?.colorAndNumber.trim() ?? '';

    if (info.isEmpty && colorAndNumber.isEmpty) {
      return null;
    }
    if (info.isEmpty) {
      return colorAndNumber;
    }
    if (colorAndNumber.isEmpty) {
      return info;
    }
    return '$info · $colorAndNumber';
  }

  String _yearsLabel(int years) {
    final mod10 = years % 10;
    final mod100 = years % 100;
    if (mod10 == 1 && mod100 != 11) {
      return 'год';
    }
    if (mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14)) {
      return 'года';
    }
    return 'лет';
  }
}

extension ScheduleUiSdkMapper on Schedule {
  ContractSummaryCardData contractSummaryCardData({
    String? nextTripLabel,
    String? statusLabelOverride,
    AutonannyStatusVariant? statusVariantOverride,
    bool isHighlighted = false,
  }) {
    return ContractSummaryCardData(
      title: title.isEmpty ? _fallbackTitle : title,
      statusLabel: statusLabelOverride ?? _statusLabel,
      statusVariant: statusVariantOverride ?? _statusVariant,
      scheduleLabel: weekdays.isEmpty
          ? 'Дни поездок не выбраны'
          : weekdays.map((weekday) => weekday.shortName).join(' • '),
      isHighlighted: isHighlighted,
      nextTripLabel: nextTripLabel,
      childLabel: '$childrenCount ${_childrenLabel(childrenCount)}',
      servicesLabel: _servicesLabel,
      weeklyAmountLabel: _formatAmount(amountWeek),
      monthlyAmountLabel: _formatAmount(amountMonth),
      actionLabel: 'Открыть расписание',
    );
  }

  String get _fallbackTitle {
    final idLabel = id == null ? '' : ' #$id';
    return 'Контракт$idLabel';
  }

  String get _statusLabel {
    if (_isBalancePause) {
      return 'Нужна оплата';
    }
    if (isPaused == true) {
      return 'Приостановлен';
    }
    if (isActive == true) {
      return 'Активен';
    }
    return 'На согласовании';
  }

  AutonannyStatusVariant get _statusVariant {
    if (_isBalancePause) {
      return AutonannyStatusVariant.danger;
    }
    if (isPaused == true) {
      return AutonannyStatusVariant.warning;
    }
    if (isActive == true) {
      return AutonannyStatusVariant.success;
    }
    return AutonannyStatusVariant.neutral;
  }

  String get _servicesLabel {
    final labels = otherParametrs
        .map((service) => (service.title ?? '').trim())
        .where((label) => label.isNotEmpty)
        .toList(growable: false);

    if (labels.isEmpty) {
      return 'Без дополнительных услуг';
    }

    return labels.join(', ');
  }

  bool get _isBalancePause {
    return isPaused == true &&
        (pauseReason == 'insufficient_balance' ||
            pauseReason == 'low_balance' ||
            pauseReason == 'lack_of_funds');
  }

  String _formatAmount(double? value) {
    if (value == null || value <= 0) {
      return '—';
    }
    return '~ ${value.round()} ₽';
  }

  String _childrenLabel(int count) {
    final mod10 = count % 10;
    final mod100 = count % 100;

    if (mod10 == 1 && mod100 != 11) {
      return 'ребёнок';
    }
    if (mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14)) {
      return 'ребёнка';
    }
    return 'детей';
  }

  List<ContractDayPanelData> contractDayPanelsData({
    Map<int, String> childNamesById = const {},
  }) {
    final roadsByDay = <NannyWeekday, List<Road>>{};

    for (final road in roads) {
      roadsByDay.putIfAbsent(road.weekDay, () => <Road>[]).add(road);
    }

    final days = roadsByDay.keys.toList(growable: false)
      ..sort((left, right) => left.index.compareTo(right.index));

    return days.map((day) {
      final dayRoads = roadsByDay[day]!.toList(growable: false)
        ..sort((left, right) {
          final byHour = left.startTime.hour.compareTo(right.startTime.hour);
          if (byHour != 0) {
            return byHour;
          }
          return left.startTime.minute.compareTo(right.startTime.minute);
        });

      return ContractDayPanelData(
        dayLabel: day.fullName,
        summaryLabel: '${dayRoads.length} ${_routesLabel(dayRoads.length)}',
        caption: day.shortName,
        routes: dayRoads.map((road) {
          final routeChildrenCount =
              road.children?.where((childId) => childId > 0).length ?? 0;

          return ContractRoutePreviewData(
            title: road.title.trim().isEmpty
                ? 'Маршрут ${road.startTime.formatTime()}'
                : road.title.trim(),
            timeLabel:
                '${road.startTime.formatTime()} – ${road.endTime.formatTime()}',
            routeLabel: _roadAddressesLabel(road),
            childLabel: routeChildrenCount > 0
                ? '$routeChildrenCount ${_childrenLabel(routeChildrenCount)}'
                : null,
            assignedChildren: (road.children ?? const <int>[])
                .map((childId) => childNamesById[childId]?.trim() ?? '')
                .where((childName) => childName.isNotEmpty)
                .toList(growable: false),
          );
        }).toList(growable: false),
      );
    }).toList(growable: false);
  }

  String _roadAddressesLabel(Road road) {
    if (road.addresses.isEmpty) {
      return 'Маршрут уточняется';
    }

    final first = road.addresses.first.fromAddress.address.trim();
    final last = road.addresses.last.toAddress.address.trim();

    if (first.isEmpty && last.isEmpty) {
      return 'Маршрут уточняется';
    }

    if (first == last || last.isEmpty) {
      return first.isEmpty ? 'Маршрут уточняется' : first;
    }

    return '$first -> $last';
  }

  String _routesLabel(int count) {
    final mod10 = count % 10;
    final mod100 = count % 100;

    if (mod10 == 1 && mod100 != 11) {
      return 'маршрут';
    }
    if (mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14)) {
      return 'маршрута';
    }
    return 'маршрутов';
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
