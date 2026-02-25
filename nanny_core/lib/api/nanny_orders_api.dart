import 'package:nanny_core/api/api_models/answer_schedule_request.dart';
import 'package:nanny_core/api/api_models/onetime_drive_request.dart';
import 'package:nanny_core/api/request_builder.dart';
import 'package:nanny_core/models/from_api/drive_and_map/drive_tariff.dart';
import 'package:nanny_core/models/from_api/drive_and_map/schedule.dart';
import 'package:nanny_core/models/from_api/drive_and_map/schedule_responses_data.dart';
import 'package:nanny_core/models/from_api/trip_history.dart';
import 'package:nanny_core/models/from_api/driver_rating.dart';
import 'package:nanny_core/nanny_core.dart';

class NannyOrdersApi {
  static Future<ApiResponse<void>> createSchedule(Schedule schedule) {
    return RequestBuilder<void>().create(
        dioRequest:
            DioRequest.dio.post("/orders/schedule", data: schedule.toJson()),
        errorCodeMsgs: {
          402: "Недостаточно средств на балансе. Минимальный баланс - 100 руб.",
          405: "Тариф не найден!",
        });
  }

  static Future<ApiResponse<Schedule>> getScheduleById(int id) {
    return RequestBuilder<Schedule>().create(
        dioRequest: DioRequest.dio.get("/orders/schedule/$id"),
        onSuccess: (response) => Schedule.fromJson(response.data["schedule"]),
        errorCodeMsgs: {404: "Расписание не найдено!"});
  }

  static Future<ApiResponse<Schedule>> deleteScheduleById(int id) {
    return RequestBuilder<Schedule>().create(
        dioRequest: DioRequest.dio.delete("/orders/schedule/$id"),
        errorCodeMsgs: {404: "Расписание не найдено!"});
  }

  static Future<ApiResponse<void>> updateScheduleById(Schedule schedule) {
    return RequestBuilder<Schedule>().create(
        dioRequest: DioRequest.dio.put(
          "/orders/schedule",
          data: schedule.toJson(),
        ),
        errorCodeMsgs: {404: "Расписание не найдено!"});
  }

  static Future<ApiResponse<List<Schedule>>> getSchedules() {
    return RequestBuilder<List<Schedule>>().create(
      dioRequest: DioRequest.dio.get("/orders/schedules"),
      onSuccess: (response) => List<Schedule>.from(
          response.data["schedules"].map((x) => Schedule.fromJson(x))),
    );
  }

  static Future<ApiResponse<Schedule>> deleteScheduleRoadById(int id) {
    return RequestBuilder<Schedule>().create(
        dioRequest: DioRequest.dio.delete("/orders/schedule_road/$id"),
        errorCodeMsgs: {404: "Расписание не найдено!"});
  }

  static Future<ApiResponse<Road>> createScheduleRoadById(int id, Road road) {
    return RequestBuilder<Road>().create(
        dioRequest: DioRequest.dio
            .post("/orders/schedule_road/$id", data: road.toJson()),
        errorCodeMsgs: {404: "Расписание не найдено!"});
  }

  static Future<ApiResponse<Road>> getScheduleRoadById(int id) {
    return RequestBuilder<Road>().create(
        dioRequest: DioRequest.dio.get("/orders/schedule_road/$id"),
        onSuccess: (response) => Road.fromJson(response.data["schedule_road"]),
        errorCodeMsgs: {404: "Расписание не найдено!"});
  }

  static Future<ApiResponse<Road>> updateScheduleRoadById(Road road) {
    return RequestBuilder<Road>().create(
        dioRequest: DioRequest.dio.put(
          "/orders/schedule_road",
          data: road.toJson(),
        ),
        errorCodeMsgs: {404: "Маршрут не найдено!"});
  }

  static Future<ApiResponse<List<ScheduleResponsesData>>>
      getScheduleResponses() async {
    return RequestBuilder<List<ScheduleResponsesData>>().create(
      dioRequest: DioRequest.dio.get("/orders/get_schedule_responses"),
      onSuccess: (response) => List<ScheduleResponsesData>.from(response
          .data["responses"]
          .map((x) => ScheduleResponsesData.fromJson(x))),
    );
  }

  static Future<ApiResponse<void>> answerScheduleRequest(
      AnswerScheduleRequest request) async {
    return RequestBuilder<void>().create(
        dioRequest: DioRequest.dio
            .post("/orders/answer_schedule_responses", data: request.toJson()));
  }

  static Future<ApiResponse<Response<dynamic>>> getCurrentOrder() async {
    return RequestBuilder<Response<dynamic>>().create(
        dioRequest: DioRequest.dio.get('/orders/get_current_order'),
        onSuccess: (data) => data);
  }

  static Future<ApiResponse<void>> startCurrentDrive() =>
      throw UnimplementedError(); // TODO: Доделать

  static Future<ApiResponse<DriverUserTextData>> getDriver(int id) async {
    var data = <String, dynamic>{
      "id": id,
    };

    return RequestBuilder<DriverUserTextData>().create(
      dioRequest: DioRequest.dio.post('/orders/get_driver', data: data),
      onSuccess: (response) =>
          DriverUserTextData.fromJson(response.data["driver"]),
    );
  }

  static Future<ApiResponse<List<DriveTariff>>> getOnetimePrices(
      int duration, int distance) async {
    return RequestBuilder<List<DriveTariff>>().create(
      dioRequest: DioRequest.dio.get(
          "/orders/get_onetime_prices?duration=$duration&distance=$distance"),
      onSuccess: (response) => List<DriveTariff>.from(
          response.data["tariffs"].map((x) => DriveTariff.fromJson(x))),
    );
  }

  static Future<ApiResponse<String>> getPriceByRoad(
      {required DriveTariff tariff,
      required int duration,
      required int distance}) async {
    return RequestBuilder<String>().create(
        dioRequest: DioRequest.dio.get(
      "/orders/get_price_by_road?id_tariff=${tariff.id}&duration=$duration&distance=$distance",
    ));
  }

  static Future<ApiResponse<String>> startOnetimeOrder(
      OnetimeDriveRequest request) async {
    return RequestBuilder<String>().create(
      dioRequest: DioRequest.dio
          .post("/orders/start_onetime_drive", data: request.toJson()),
      onSuccess: (response) {
        print('response info ${response.data}');
        return response.data["token"];
      },
    );
  }

  static Future<ApiResponse<List<TripHistory>>> getTripHistory({
    DateTime? startDate,
    DateTime? endDate,
    String? status,
  }) async {
    final queryParams = <String, dynamic>{};
    if (startDate != null) queryParams['start_date'] = startDate.toIso8601String();
    if (endDate != null) queryParams['end_date'] = endDate.toIso8601String();
    if (status != null) queryParams['status'] = status;

    return RequestBuilder<List<TripHistory>>().create(
      dioRequest: DioRequest.dio.get(
        '/orders/get_order_history',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      ),
      onSuccess: (response) {
        final list = response.data['orders'] ?? response.data['history'] ?? [];
        return List<TripHistory>.from(list.map((x) => TripHistory.fromJson(x)));
      },
      errorCodeMsgs: {
        404: 'История поездок не найдена',
      },
    );
  }

  static Future<ApiResponse<void>> rateDriver({
    required int orderId,
    required int rating,
    List<String>? criteria,
    String? review,
  }) async {
    return RequestBuilder<void>().create(
      dioRequest: DioRequest.dio.post(
        '/orders/rate_driver',
        data: {
          'order_id': orderId,
          'rating': rating,
          if (criteria != null && criteria.isNotEmpty) 'criteria': criteria,
          if (review != null && review.isNotEmpty) 'review': review,
        },
      ),
      errorCodeMsgs: {
        404: 'Заказ не найден',
        400: 'Оценка уже поставлена',
      },
    );
  }

  static Future<ApiResponse<DriverRating>> getDriverRating(int driverId) async {
    return RequestBuilder<DriverRating>().create(
      dioRequest: DioRequest.dio.get('/orders/driver_rating/$driverId'),
      onSuccess: (response) => DriverRating.fromJson(response.data),
      errorCodeMsgs: {
        404: 'Водитель не найден',
      },
    );
  }

  // C-042: Изменение маршрута активной поездки
  static Future<ApiResponse<void>> updateOrderRoute({
    required int orderId,
    required List<Map<String, dynamic>> addresses,
  }) async {
    return RequestBuilder<void>().create(
      dioRequest: DioRequest.dio.put(
        '/orders/update_route/$orderId',
        data: {
          'addresses': addresses,
        },
      ),
      errorCodeMsgs: {
        404: 'Заказ не найден',
        400: 'Невозможно изменить маршрут в текущем статусе',
        403: 'Нет доступа к этому заказу',
      },
    );
  }
}
