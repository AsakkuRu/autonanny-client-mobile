class TariffAlternative {
  final int tariffId;
  final String tariffName;
  final String? tariffPhoto;
  final double price;
  final int estimatedWaitMinutes;

  TariffAlternative({
    required this.tariffId,
    required this.tariffName,
    this.tariffPhoto,
    required this.price,
    required this.estimatedWaitMinutes,
  });

  factory TariffAlternative.fromJson(Map<String, dynamic> json) {
    return TariffAlternative(
      tariffId: json['tariff_id'] as int? ?? json['id'] as int? ?? 0,
      tariffName: json['tariff_name'] as String? ?? json['name'] as String? ?? '',
      tariffPhoto: json['tariff_photo'] as String?,
      price: (json['price'] as num?)?.toDouble() ?? 0,
      estimatedWaitMinutes: json['estimated_wait'] as int? ?? json['estimated_wait_minutes'] as int? ?? 0,
    );
  }
}
