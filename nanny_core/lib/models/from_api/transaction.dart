/// FE-MVP-023: Модель финансовой транзакции
class Transaction {
  Transaction({
    required this.id,
    required this.amount,
    required this.type,
    required this.description,
    required this.createdAt,
    this.status,
    this.relatedId,
  });

  final int id;
  final double amount;
  final String type; // deposit, withdrawal, payment, refund, commission
  final String description;
  final DateTime createdAt;
  final String? status; // completed, pending, failed
  final int? relatedId;

  factory Transaction.fromJson(Map<String, dynamic> json) {
    final amount = (json['amount'] as num?)?.toDouble() ?? 0.0;

    // Тип определяем из amount если поле type отсутствует
    final type = json['type'] as String? ??
        (amount >= 0 ? 'deposit' : 'payment');

    // datetime_create может быть null — используем текущее время как fallback
    final rawDate = json['created_at'] as String? ??
        json['datetime_create'] as String?;
    final createdAt =
        rawDate != null ? DateTime.tryParse(rawDate) ?? DateTime.now() : DateTime.now();

    return Transaction(
      id: json['id'] as int? ?? 0,
      amount: amount,
      type: type,
      description: json['description'] as String? ?? '',
      createdAt: createdAt,
      status: json['status'] as String?,
      relatedId: json['related_id'] as int?,
    );
  }

  bool get isIncome => amount > 0;
  bool get isExpense => amount < 0;

  String get typeText {
    switch (type) {
      case 'deposit':
        return 'Пополнение';
      case 'withdrawal':
        return 'Вывод средств';
      case 'payment':
        return 'Оплата';
      case 'refund':
        return 'Возврат';
      case 'commission':
        return 'Комиссия';
      case 'earning':
        return 'Заработок';
      default:
        return type;
    }
  }

  String get statusText {
    switch (status) {
      case 'completed':
        return 'Завершено';
      case 'pending':
        return 'В обработке';
      case 'failed':
        return 'Ошибка';
      default:
        return status ?? '';
    }
  }
}

/// Фильтр для транзакций
class TransactionFilter {
  TransactionFilter({
    this.startDate,
    this.endDate,
    this.types,
    this.minAmount,
    this.maxAmount,
    this.searchQuery,
  });

  final DateTime? startDate;
  final DateTime? endDate;
  final List<String>? types;
  final double? minAmount;
  final double? maxAmount;
  final String? searchQuery;

  bool matches(Transaction transaction) {
    if (startDate != null && transaction.createdAt.isBefore(startDate!)) {
      return false;
    }
    if (endDate != null && transaction.createdAt.isAfter(endDate!)) {
      return false;
    }
    if (types != null && types!.isNotEmpty && !types!.contains(transaction.type)) {
      return false;
    }
    if (minAmount != null && transaction.amount.abs() < minAmount!) {
      return false;
    }
    if (maxAmount != null && transaction.amount.abs() > maxAmount!) {
      return false;
    }
    if (searchQuery != null && searchQuery!.isNotEmpty) {
      final query = searchQuery!.toLowerCase();
      if (!transaction.description.toLowerCase().contains(query) &&
          !transaction.typeText.toLowerCase().contains(query)) {
        return false;
      }
    }
    return true;
  }
}

/// Ответ от /users/transactions с пагинацией
class TransactionListResponse {
  final List<Transaction> transactions;
  final int page;
  final int totalPages;
  final int total;

  TransactionListResponse({
    required this.transactions,
    required this.page,
    required this.totalPages,
    required this.total,
  });

  factory TransactionListResponse.fromJson(Map<String, dynamic> json) {
    final rawList = json['transactions'] as List<dynamic>? ?? [];
    final pagination = json['pagination'] as Map<String, dynamic>? ?? {};
    return TransactionListResponse(
      transactions: rawList
          .map((e) => Transaction.fromJson(e as Map<String, dynamic>))
          .toList(),
      page: pagination['page'] as int? ?? 1,
      totalPages: pagination['pages'] as int? ?? 1,
      total: pagination['total'] as int? ?? 0,
    );
  }
}
