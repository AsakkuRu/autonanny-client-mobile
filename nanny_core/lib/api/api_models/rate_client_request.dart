/// D-001: Запрос оценки клиента водителем (TASK-D1)
class RateClientRequest {
  final int orderId;
  final int clientId;
  final int overallRating;
  final Map<String, int> criteria;
  final String? comment;

  RateClientRequest({
    required this.orderId,
    required this.clientId,
    required this.overallRating,
    required this.criteria,
    this.comment,
  });

  Map<String, dynamic> toJson() => {
        'order_id': orderId,
        'client_id': clientId,
        'overall_rating': overallRating,
        'criteria': criteria,
        if (comment != null && comment!.isNotEmpty) 'comment': comment,
      };
}
