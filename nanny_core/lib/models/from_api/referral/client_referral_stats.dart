class ReferralUser {
  final String name;
  final String status; // 'registered', 'first_ride', 'active'
  final DateTime registeredAt;
  final DateTime? firstRideAt;
  final double bonusEarned;

  ReferralUser({
    required this.name,
    required this.status,
    required this.registeredAt,
    this.firstRideAt,
    required this.bonusEarned,
  });

  factory ReferralUser.fromJson(Map<String, dynamic> json) {
    return ReferralUser(
      name: json['name'] as String? ?? '',
      status: json['status'] as String? ?? 'registered',
      registeredAt: DateTime.tryParse(json['registered_at'] as String? ?? '') ?? DateTime.now(),
      firstRideAt: json['first_ride_at'] != null
          ? DateTime.tryParse(json['first_ride_at'] as String)
          : null,
      bonusEarned: (json['bonus_earned'] as num?)?.toDouble() ?? 0,
    );
  }
}

class BonusHistoryItem {
  final DateTime date;
  final double amount;
  final String description;

  BonusHistoryItem({
    required this.date,
    required this.amount,
    required this.description,
  });

  factory BonusHistoryItem.fromJson(Map<String, dynamic> json) {
    return BonusHistoryItem(
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      description: json['description'] as String? ?? '',
    );
  }
}

class ClientReferralStats {
  final String referralCode;
  final int totalInvited;
  final int registered;
  final int firstRideCompleted;
  final int active;
  final double totalBonus;
  final double periodBonus;
  final List<ReferralUser> referrals;
  final List<BonusHistoryItem> bonusHistory;

  ClientReferralStats({
    required this.referralCode,
    required this.totalInvited,
    required this.registered,
    required this.firstRideCompleted,
    required this.active,
    required this.totalBonus,
    required this.periodBonus,
    required this.referrals,
    required this.bonusHistory,
  });

  factory ClientReferralStats.fromJson(Map<String, dynamic> json) {
    return ClientReferralStats(
      referralCode: json['referral_code'] as String? ?? json['code'] as String? ?? '',
      totalInvited: json['total_invited'] as int? ?? json['invited_count'] as int? ?? 0,
      registered: json['registered'] as int? ?? 0,
      firstRideCompleted: json['first_ride_completed'] as int? ?? 0,
      active: json['active'] as int? ?? json['active_count'] as int? ?? 0,
      totalBonus: (json['total_bonus'] as num?)?.toDouble() ?? (json['bonus_earned'] as num?)?.toDouble() ?? 0,
      periodBonus: (json['period_bonus'] as num?)?.toDouble() ?? 0,
      referrals: (json['referrals'] as List<dynamic>?)
              ?.map((e) => ReferralUser.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      bonusHistory: (json['bonus_history'] as List<dynamic>?)
              ?.map((e) => BonusHistoryItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  factory ClientReferralStats.mock(String code) {
    final now = DateTime.now();
    return ClientReferralStats(
      referralCode: code,
      totalInvited: 5,
      registered: 4,
      firstRideCompleted: 3,
      active: 2,
      totalBonus: 2500,
      periodBonus: 500,
      referrals: [
        ReferralUser(name: 'Анна П.', status: 'active', registeredAt: now.subtract(const Duration(days: 30)), firstRideAt: now.subtract(const Duration(days: 25)), bonusEarned: 500),
        ReferralUser(name: 'Сергей К.', status: 'first_ride', registeredAt: now.subtract(const Duration(days: 20)), firstRideAt: now.subtract(const Duration(days: 15)), bonusEarned: 500),
        ReferralUser(name: 'Мария Д.', status: 'first_ride', registeredAt: now.subtract(const Duration(days: 10)), firstRideAt: now.subtract(const Duration(days: 5)), bonusEarned: 500),
        ReferralUser(name: 'Ольга Н.', status: 'registered', registeredAt: now.subtract(const Duration(days: 5)), bonusEarned: 0),
        ReferralUser(name: 'Иван М.', status: 'registered', registeredAt: now.subtract(const Duration(days: 2)), bonusEarned: 0),
      ],
      bonusHistory: [
        BonusHistoryItem(date: now.subtract(const Duration(days: 5)), amount: 500, description: 'Бонус за первую поездку реферала Мария Д.'),
        BonusHistoryItem(date: now.subtract(const Duration(days: 15)), amount: 500, description: 'Бонус за первую поездку реферала Сергей К.'),
        BonusHistoryItem(date: now.subtract(const Duration(days: 25)), amount: 500, description: 'Бонус за первую поездку реферала Анна П.'),
        BonusHistoryItem(date: now.subtract(const Duration(days: 25)), amount: 500, description: 'Бонус за активность реферала Анна П.'),
        BonusHistoryItem(date: now.subtract(const Duration(days: 25)), amount: 500, description: 'Бонус за активность реферала Анна П.'),
      ],
    );
  }
}
