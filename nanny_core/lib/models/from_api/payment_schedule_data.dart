class PaymentScheduleHistoryItem {
  const PaymentScheduleHistoryItem({
    required this.id,
    required this.amount,
    required this.status,
    this.errorMessage,
    this.datetimeCreate,
  });

  final int id;
  final double amount;
  final String status;
  final String? errorMessage;
  final String? datetimeCreate;

  factory PaymentScheduleHistoryItem.fromJson(Map<String, dynamic> json) {
    return PaymentScheduleHistoryItem(
      id: json['id'] ?? 0,
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      status: json['status']?.toString() ?? 'unknown',
      errorMessage: json['error_message']?.toString(),
      datetimeCreate: json['datetime_create']?.toString(),
    );
  }
}

class PaymentScheduleData {
  const PaymentScheduleData({
    required this.id,
    required this.amount,
    required this.status,
    this.cardId,
    this.nextPaymentDate,
    this.lastPaymentDate,
    this.failedAttempts = 0,
    this.lastError,
    this.paymentHistory = const [],
  });

  final int id;
  final double amount;
  final String status;
  final int? cardId;
  final String? nextPaymentDate;
  final String? lastPaymentDate;
  final int failedAttempts;
  final String? lastError;
  final List<PaymentScheduleHistoryItem> paymentHistory;

  factory PaymentScheduleData.fromJson(Map<String, dynamic> json) {
    return PaymentScheduleData(
      id: json['id'] ?? 0,
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      status: json['status']?.toString() ?? 'active',
      cardId: json['id_card'] as int?,
      nextPaymentDate: json['next_payment_date']?.toString(),
      lastPaymentDate: json['last_payment_date']?.toString(),
      failedAttempts: json['failed_attempts'] ?? 0,
      lastError: json['last_error']?.toString(),
      paymentHistory: (json['payment_history'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map(
            (item) => PaymentScheduleHistoryItem.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(growable: false),
    );
  }

  PaymentScheduleData copyWith({
    int? id,
    double? amount,
    String? status,
    int? cardId,
    String? nextPaymentDate,
    String? lastPaymentDate,
    int? failedAttempts,
    String? lastError,
    List<PaymentScheduleHistoryItem>? paymentHistory,
  }) {
    return PaymentScheduleData(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      cardId: cardId ?? this.cardId,
      nextPaymentDate: nextPaymentDate ?? this.nextPaymentDate,
      lastPaymentDate: lastPaymentDate ?? this.lastPaymentDate,
      failedAttempts: failedAttempts ?? this.failedAttempts,
      lastError: lastError ?? this.lastError,
      paymentHistory: paymentHistory ?? this.paymentHistory,
    );
  }
}
