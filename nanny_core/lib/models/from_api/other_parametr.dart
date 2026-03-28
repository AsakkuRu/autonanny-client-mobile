import 'package:nanny_core/api/api_models/base_models/base_request.dart';

class OtherParametr implements NannyBaseRequest {
  OtherParametr({
    this.title = "Неизвестный параметр",
    this.amount,
    this.id,
    this.count,
  });

  final int? id;
  final String? title;
  final double? amount;
  final int? count;

  OtherParametr.fromJson(Map<String, dynamic> json)
      : id = json['id'] ?? json['parametr'],
        title = json['title'],
        amount = json['amount'],
        count = json['count'];

  @override
  Map<String, dynamic> toJson() => {
        "id": id,
        "title": title,
        "amount": amount,
      };

  Map<String, dynamic> toCacheJson() => {
        "id": id,
        "parametr": id,
        "title": title,
        "amount": amount,
        "count": count,
      };

  Map<String, dynamic> toGraphJson(int childCount) => {
        "parametr": id,
        "count": childCount,
      };
}
