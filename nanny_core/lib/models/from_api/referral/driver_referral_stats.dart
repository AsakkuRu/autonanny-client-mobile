import 'package:nanny_core/models/from_api/roles/driver_referal_data.dart';

/// D-007: Модели статистики рефералов водителя (TASK-D7)
class DriverReferralStats {
  final int totalReferrals;
  final int activeReferrals;
  final int pendingReferrals;
  final double totalBonus;
  final List<DriverReferalData> referrals;
  final List<ReferralBonusEvent> bonusHistory;

  DriverReferralStats({
    required this.totalReferrals,
    required this.activeReferrals,
    required this.pendingReferrals,
    required this.totalBonus,
    required this.referrals,
    required this.bonusHistory,
  });

  factory DriverReferralStats.fromJson(Map<String, dynamic> json) {
    return DriverReferralStats(
      totalReferrals: json['total_referrals'] ?? 0,
      activeReferrals: json['active_referrals'] ?? 0,
      pendingReferrals: json['pending_referrals'] ?? 0,
      totalBonus: (json['total_bonus'] ?? 0).toDouble(),
      referrals: (json['referrals'] as List? ?? [])
          .map((e) => DriverReferalData.fromJson(e))
          .toList(),
      bonusHistory: (json['bonus_history'] as List? ?? [])
          .map((e) => ReferralBonusEvent.fromJson(e))
          .toList(),
    );
  }

  factory DriverReferralStats.mock() {
    return DriverReferralStats(
      totalReferrals: 5,
      activeReferrals: 3,
      pendingReferrals: 2,
      totalBonus: 1250.0,
      referrals: [
        DriverReferalData(id: 1, name: 'Михаил В.', photoPath: '', status: true),
        DriverReferalData(id: 2, name: 'Олег С.', photoPath: '', status: false),
        DriverReferalData(id: 3, name: 'Наталья П.', photoPath: '', status: true),
      ],
      bonusHistory: [
        ReferralBonusEvent(
          date: DateTime.now().subtract(const Duration(days: 3)),
          amount: 500.0,
          referralName: 'Михаил В.',
          event: 'first_ride',
        ),
        ReferralBonusEvent(
          date: DateTime.now().subtract(const Duration(days: 10)),
          amount: 250.0,
          referralName: 'Олег С.',
          event: 'registered',
        ),
        ReferralBonusEvent(
          date: DateTime.now().subtract(const Duration(days: 30)),
          amount: 500.0,
          referralName: 'Наталья П.',
          event: 'monthly_bonus',
        ),
      ],
    );
  }
}

class ReferralBonusEvent {
  final DateTime date;
  final double amount;
  final String referralName;
  final String event;

  ReferralBonusEvent({
    required this.date,
    required this.amount,
    required this.referralName,
    required this.event,
  });

  factory ReferralBonusEvent.fromJson(Map<String, dynamic> json) {
    return ReferralBonusEvent(
      date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
      amount: (json['amount'] ?? 0).toDouble(),
      referralName: json['referral_name'] ?? '',
      event: json['event'] ?? '',
    );
  }

  String get eventLabel {
    switch (event) {
      case 'registered':
        return 'Регистрация';
      case 'first_ride':
        return 'Первая поездка';
      case 'monthly_bonus':
        return 'Ежемесячный бонус';
      default:
        return event;
    }
  }
}
