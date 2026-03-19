/// Тариф поездки. Названия и остальные данные приходят из БД через API.
class DriveTariff {
  DriveTariff({
    required this.id,
    this.title,
    this.photoPath,
    this.amount,
    this.isAvailable = false,
  });

  final int id;
  final String? title;
  final String? photoPath;
  double? amount;
  final bool isAvailable;

  /// Отображаемое название: из API или нейтральный fallback, если данных нет.
  String get displayTitle => title ?? 'Тариф #$id';

  DriveTariff.fromJson(Map<String, dynamic> json)
      : id = json["id"] ?? json["id_tariff"],
        title = json["title"] ?? json["type"],
        photoPath = json["photo_path"],
        isAvailable = json["isAvailable"] ?? false,
        amount = json["amount"];
}
