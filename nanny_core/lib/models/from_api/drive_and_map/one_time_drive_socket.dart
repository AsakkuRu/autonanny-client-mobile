import 'package:nanny_components/widgets/one_time_drive_widget.dart';

/// D-009: Расширен полями срочного заказа «На замену» (TASK-D9)
class OneTimeDriveResponse {
  final int? idOrder;
  final String? username;
  final String? phone;
  final String? userPhoto;
  final double? amount;
  final dynamic idStatus;
  final List<AddressOneTimeDrive>? addresses;

  // D-009: Поля срочного заказа
  final bool isUrgent;
  final double? urgentMultiplier;
  final double? urgentBonus;
  final String? urgentReason;

  OneTimeDriveResponse(
      {this.idOrder,
      this.username,
      this.phone,
      this.userPhoto,
      this.amount,
      this.idStatus,
      this.addresses,
      this.isUrgent = false,
      this.urgentMultiplier,
      this.urgentBonus,
      this.urgentReason});

  factory OneTimeDriveResponse.fromJson(Map<String, dynamic> json) {
    return OneTimeDriveResponse(
        idOrder: json['id_order'] ?? json['order_id'],
        username: json['username'],
        phone: json['phone'],
        userPhoto: json['user_photo'],
        amount: ((json['amount'] ?? json['total_price']) as num?)?.toDouble(),
        idStatus: json['id_status'],
        addresses: (json['addresses'] as List?)
            ?.map((e) => AddressOneTimeDrive.fromJson(e))
            .toList(),
        isUrgent: json['is_urgent'] ?? false,
        urgentMultiplier: json['urgent_multiplier']?.toDouble(),
        urgentBonus: json['urgent_bonus']?.toDouble(),
        urgentReason: json['urgent_reason']);
  }

  double? get effectiveAmount {
    if (!isUrgent) return amount;
    if (urgentMultiplier != null && amount != null) return amount! * urgentMultiplier!;
    if (urgentBonus != null && amount != null) return amount! + urgentBonus!;
    return amount;
  }

  OneTimeDriveModel toUi({bool isFromSocket = false}) => OneTimeDriveModel(
      avatar: userPhoto ?? '',
      username: username ?? '',
      isFromSocket: isFromSocket,
      price: (effectiveAmount ?? amount ?? 0).toString(),
      orderId: idOrder ?? 0,
      orderStatus: idStatus,
      phone: phone,
      addresses: addresses?.map((e) => e.toUI()).toList() ?? []);
}

class AddressOneTimeDrive {
  final String? from;
  final bool? isFinish;
  final String? to;
  final double? fromLat;
  final double? fromLon;
  final double? toLat;
  final double? toLon;
  final int? duration;

  AddressOneTimeDrive(
      {this.from,
      this.isFinish,
      this.to,
      this.fromLat,
      this.fromLon,
      this.toLat,
      this.toLon,
      this.duration});

  factory AddressOneTimeDrive.fromJson(Map<String, dynamic> json) {
    final finish = json['is_finish'] ?? json['isFinish'];
    return AddressOneTimeDrive(
        from: json['from_address'] ?? json['from'],
        isFinish: finish is bool ? finish : finish == 1 || finish == '1',
        to: json['to_address'] ?? json['to'],
        fromLat: json['from_lat'],
        fromLon: json['from_lon'],
        toLat: json['to_lat'],
        toLon: json['to_lon'],
        duration: json['duration']);
  }

  OneTimeDriveAddress toUI() => OneTimeDriveAddress(
      from: from ?? '',
      isFinish: isFinish ?? false,
      to: to ?? '',
      fromLat: fromLat ?? 0,
      fromLon: fromLon ?? 0,
      toLat: toLat ?? 0,
      toLon: toLon ?? 0,
      duration: duration ?? 0);
}
