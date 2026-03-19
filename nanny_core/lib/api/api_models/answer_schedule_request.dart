import 'package:nanny_core/api/api_models/base_models/base_request.dart';

class AnswerScheduleRequest implements NannyBaseRequest {
  AnswerScheduleRequest({
    this.idSchedule,
    this.idResponses,
    this.flag
  });

  int? idSchedule;
  List<int>? idResponses;
  bool? flag;
  
  @override
  Map<String, dynamic> toJson() => {
    "id_schedule": idSchedule,
    "id_responses": idResponses,
    "flag": flag
  };
}