import 'package:nanny_core/api/api_models/answer_schedule_request.dart';
import 'package:nanny_core/api/api_models/onetime_drive_request.dart';
import 'package:nanny_core/api/request_builder.dart';
import 'package:nanny_core/models/from_api/drive_and_map/drive_tariff.dart';
import 'package:nanny_core/models/from_api/drive_and_map/schedule.dart';
import 'package:nanny_core/models/from_api/drive_and_map/schedule_responses_data.dart';
import 'package:nanny_core/models/from_api/drive_and_map/route_deviation.dart';
import 'package:nanny_core/models/from_api/drive_and_map/shared_ride.dart';
import 'package:nanny_core/models/from_api/trip_history.dart';
import 'package:nanny_core/models/from_api/driver_rating.dart';
import 'package:nanny_core/models/from_api/rating/driver_order_rating.dart';
import 'package:nanny_core/nanny_core.dart';

/// Ответ API получения кода встречи для графика (родитель).
class MeetingCodeForSchedule {
  final String? meetingCode;
  final int? idScheduleRoad;
  MeetingCodeForSchedule({this.meetingCode, this.idScheduleRoad});
}

/// Ответ API получения кода встречи для разовой поездки.
class MeetingCodeForOrder {
  final String? meetingCode;
  final int? idOrder;
  final int? idScheduleRoad;
  final String? verificationScope;
  MeetingCodeForOrder({
    this.meetingCode,
    this.idOrder,
    this.idScheduleRoad,
    this.verificationScope,
  });
}

class ScheduleCancellationResult {
  const ScheduleCancellationResult({
    required this.success,
    this.requiresDebit = false,
    this.debitAmount,
    this.message = '',
  });

  final bool success;
  final bool requiresDebit;
  final double? debitAmount;
  final String message;
}

class OrderCancellationResult {
  const OrderCancellationResult({
    required this.message,
    this.penalty = 0,
    this.basePrice,
    this.currentTotalPrice,
    this.waitingSeconds,
    this.freeWaitingSeconds,
    this.waitingRatePerMinute,
    this.waitingCharge,
    this.isPaidWaiting,
  });

  final String message;
  final double penalty;
  final double? basePrice;
  final double? currentTotalPrice;
  final int? waitingSeconds;
  final int? freeWaitingSeconds;
  final double? waitingRatePerMinute;
  final double? waitingCharge;
  final bool? isPaidWaiting;

  bool get hasPenalty => penalty > 0;

  bool get hasSettlementBreakdown =>
      basePrice != null ||
      currentTotalPrice != null ||
      waitingSeconds != null ||
      waitingCharge != null ||
      freeWaitingSeconds != null ||
      waitingRatePerMinute != null;
}

class OrderRouteChangePreview {
  const OrderRouteChangePreview({
    required this.totalPrice,
    required this.currentTotalPrice,
    required this.priceDelta,
    required this.travelTotal,
    required this.additionalServicesTotal,
    required this.distance,
    required this.duration,
  });

  final double totalPrice;
  final double currentTotalPrice;
  final double priceDelta;
  final double travelTotal;
  final double additionalServicesTotal;
  final int distance;
  final int duration;
}

class NannyOrdersApi {
  static Future<ApiResponse<int?>> createSchedule(Schedule schedule) {
    return RequestBuilder<int?>().create(
        dioRequest:
            DioRequest.dio.post("/orders/schedule", data: schedule.toJson()),
        onSuccess: (response) {
          try {
            final id = response.data["created_schedule"]?["id"];
            if (id == null) return null;
            if (id is int) return id;
            if (id is num) return id.toInt();
            return null;
          } catch (_) {
            return null;
          }
        },
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

  /// BE-MVP-021: Получение кода встречи для графика (для отображения родителю; водитель вводит этот код вместо QR).
  static Future<ApiResponse<MeetingCodeForSchedule>> getMeetingCodeForSchedule(
      int scheduleId) {
    return RequestBuilder<MeetingCodeForSchedule>().create(
      dioRequest:
          DioRequest.dio.get("/orders/meeting_code_for_schedule/$scheduleId"),
      onSuccess: (response) => MeetingCodeForSchedule(
        meetingCode: response.data["meeting_code"] as String?,
        idScheduleRoad: response.data["id_schedule_road"] as int?,
      ),
      errorCodeMsgs: {403: "Нет доступа к этому графику"},
    );
  }

  /// Получение кода встречи для разовой поездки (родитель показывает водителю).
  static Future<ApiResponse<MeetingCodeForOrder>> getMeetingCodeForOrder(
      int orderId) {
    return RequestBuilder<MeetingCodeForOrder>().create(
      dioRequest: DioRequest.dio.get("/orders/meeting_code_for_order/$orderId"),
      onSuccess: (response) => MeetingCodeForOrder(
        meetingCode: response.data["meeting_code"] as String?,
        idOrder: response.data["id_order"] as int?,
        idScheduleRoad: response.data["id_schedule_road"] as int?,
        verificationScope: response.data["verification_scope"] as String?,
      ),
      errorCodeMsgs: {403: "Нет доступа к этому заказу"},
    );
  }

  static Future<ApiResponse<Schedule>> deleteScheduleById(int id) {
    return RequestBuilder<Schedule>().create(
        dioRequest: DioRequest.dio.delete("/orders/schedule/$id"),
        errorCodeMsgs: {404: "Расписание не найдено!"});
  }

  static Future<ScheduleCancellationResult> requestScheduleCancellation(
    int id,
  ) async {
    try {
      final response = await DioRequest.dio.delete(
        "/orders/schedule/$id",
        options: Options(
          extra: {
            'allowStatusCodes': [202],
          },
        ),
      );

      final data = response.data;
      final message = data is Map
          ? (data['message']?.toString() ?? '')
          : 'Контракт расторгнут';

      if (response.statusCode == 200) {
        return ScheduleCancellationResult(
          success: true,
          message: message.isEmpty ? 'Контракт расторгнут' : message,
        );
      }

      if (response.statusCode == 202) {
        final rawDebitAmount = data is Map ? data['debit_amount'] : null;
        final debitAmount = rawDebitAmount is num
            ? rawDebitAmount.toDouble()
            : double.tryParse(rawDebitAmount?.toString() ?? '');

        return ScheduleCancellationResult(
          success: false,
          requiresDebit: true,
          debitAmount: debitAmount,
          message: message,
        );
      }

      return ScheduleCancellationResult(
        success: false,
        message: message.isEmpty ? 'Не удалось расторгнуть контракт' : message,
      );
    } on DioException catch (e) {
      final data = e.response?.data;
      final message = data is Map
          ? (data['message']?.toString() ??
              data['error']?.toString() ??
              data['detail']?.toString())
          : null;

      return ScheduleCancellationResult(
        success: false,
        message: message ?? 'Не удалось расторгнуть контракт',
      );
    } catch (_) {
      return const ScheduleCancellationResult(
        success: false,
        message: 'Отсутствует подключение к интернету',
      );
    }
  }

  static Future<ApiResponse<void>> cancelScheduleWithDebit({
    required int id,
    required double debitAmount,
  }) {
    return RequestBuilder<void>().create(
      dioRequest: DioRequest.dio.delete(
        "/orders/schedule_cancel_with_debit/$id",
        queryParameters: {
          'debit_amount': debitAmount.toStringAsFixed(2),
        },
      ),
      errorCodeMsgs: {
        404: "Расписание не найдено!",
        409: "Недостаточно средств для списания штрафа",
      },
    );
  }

  static Future<ApiResponse<void>> updateScheduleById(
    Schedule schedule, {
    bool includeRoads = true,
  }) {
    final data = schedule.toJson();
    if (!includeRoads) {
      data.remove("roads");
    }

    return RequestBuilder<Schedule>().create(
        dioRequest: DioRequest.dio.put(
          "/orders/schedule",
          data: data,
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

  /// NEW-006: предварительный расчёт стоимости маршрута без сохранения в БД.
  static Future<ApiResponse<double>> estimateScheduleRoadPrice({
    required int idTariff,
    required List<Map<String, dynamic>> addresses,
  }) {
    return RequestBuilder<double>().create(
      dioRequest: DioRequest.dio.post(
        "/orders/schedule_road/estimate",
        data: {"id_tariff": idTariff, "addresses": addresses},
      ),
      onSuccess: (response) {
        final v = response.data["total_price"];
        return (v is num) ? v.toDouble() : 0.0;
      },
      errorCodeMsgs: {405: "Тариф не найден!"},
    );
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
        dioRequest: DioRequest.dio.get('/orders/current'),
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
      dioRequest:
          DioRequest.dio.post("/orders/one-time", data: request.toJson()),
      onSuccess: (response) => response.data["token"],
      errorCodeMsgs: {
        409: 'У вас уже есть активная поездка',
      },
    );
  }

  static Future<ApiResponse<List<TripHistory>>> getTripHistory({
    DateTime? startDate,
    DateTime? endDate,
    String? status,
  }) async {
    final queryParams = <String, dynamic>{};
    if (startDate != null) {
      queryParams['start_date'] = startDate.toIso8601String();
    }
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
        400: 'Не удалось сохранить оценку',
      },
    );
  }

  static Future<ApiResponse<DriverOrderRatingData?>> getMyDriverRating(
    int orderId,
  ) async {
    return RequestBuilder<DriverOrderRatingData?>().create(
      dioRequest: DioRequest.dio.get('/orders/my_rating/$orderId'),
      onSuccess: (response) {
        if (response.data['has_rating'] != true) {
          return null;
        }

        final rawRating = response.data['rating'];
        if (rawRating is! Map<String, dynamic>) {
          return null;
        }

        return DriverOrderRatingData.fromJson(rawRating);
      },
      errorCodeMsgs: {
        404: 'Заказ не найден',
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

  // TASK-C1: Отклонения от маршрута

  static Future<ApiResponse<RouteDeviationsResponse>> getRouteDeviations({
    int? orderId,
    int offset = 0,
    int limit = 20,
  }) async {
    return RequestBuilder<RouteDeviationsResponse>().create(
      dioRequest: DioRequest.dio.get(
        orderId != null
            ? '/orders/route_deviations?order_id=$orderId&offset=$offset&limit=$limit'
            : '/users/route_deviations?offset=$offset&limit=$limit',
      ),
      onSuccess: (response) => RouteDeviationsResponse.fromJson(response.data),
      errorCodeMsgs: {
        404: 'Данные об отклонениях не найдены',
      },
    );
  }

  // TASK-C3: Совместные поездки

  static Future<ApiResponse<SharedRidesResponse>> getSharedRides({
    double? fromLat,
    double? fromLon,
    double? toLat,
    double? toLon,
    String? date,
  }) async {
    return RequestBuilder<SharedRidesResponse>().create(
      dioRequest: DioRequest.dio.get(
        '/orders/shared_rides',
        queryParameters: {
          if (fromLat != null) 'from_lat': fromLat,
          if (fromLon != null) 'from_lon': fromLon,
          if (toLat != null) 'to_lat': toLat,
          if (toLon != null) 'to_lon': toLon,
          if (date != null) 'date': date,
        },
      ),
      onSuccess: (response) => SharedRidesResponse.fromJson(response.data),
      errorCodeMsgs: {
        404: 'Совместных поездок по маршруту не найдено',
      },
    );
  }

  static Future<ApiResponse<Map<String, dynamic>>> joinSharedRide(
      int sharedRideId) async {
    return RequestBuilder<Map<String, dynamic>>().create(
      dioRequest: DioRequest.dio.post(
        '/orders/join_shared_ride',
        data: {'shared_ride_id': sharedRideId},
      ),
      onSuccess: (response) => response.data as Map<String, dynamic>,
      errorCodeMsgs: {
        400: 'Нет свободных мест',
        404: 'Поездка не найдена',
        409: 'Вы уже присоединились к этой поездке',
      },
    );
  }

  static Future<ApiResponse<void>> leaveSharedRide(int sharedRideId) async {
    return RequestBuilder<void>().create(
      dioRequest:
          DioRequest.dio.delete('/orders/leave_shared_ride/$sharedRideId'),
      errorCodeMsgs: {
        404: 'Поездка не найдена',
      },
    );
  }

  // TASK-C6: Смена тарифа при поиске водителя
  static Future<ApiResponse<void>> changeTariff({
    required int orderId,
    required int newTariffId,
  }) async {
    return RequestBuilder<void>().create(
      dioRequest: DioRequest.dio.post(
        '/orders/change_tariff',
        data: {'order_id': orderId, 'new_tariff_id': newTariffId},
      ),
      errorCodeMsgs: {
        404: 'Заказ не найден',
        400: 'Невозможно сменить тариф в текущем статусе',
      },
    );
  }

  static Future<ApiResponse<OrderCancellationResult>> cancelOrder({
    required int orderId,
  }) async {
    return RequestBuilder<OrderCancellationResult>().create(
      dioRequest: DioRequest.dio.post(
        '/orders/one-time/$orderId/cancel',
      ),
      onSuccess: (response) {
        final data = response.data;
        if (data is! Map) {
          return const OrderCancellationResult(
            message: 'Поездка отменена',
          );
        }
        double? readDouble(dynamic value) {
          if (value is num) return value.toDouble();
          return double.tryParse(value?.toString() ?? '');
        }

        int? readInt(dynamic value) {
          if (value is num) return value.toInt();
          return int.tryParse(value?.toString() ?? '');
        }

        bool? readBool(dynamic value) {
          if (value is bool) return value;
          if (value is num) return value != 0;
          final normalized = value?.toString().trim().toLowerCase();
          if (normalized == null || normalized.isEmpty) return null;
          if (normalized == 'true' || normalized == '1') return true;
          if (normalized == 'false' || normalized == '0') return false;
          return null;
        }

        final rawPenalty = data['penalty'];
        final penalty = rawPenalty is num
            ? rawPenalty.toDouble()
            : double.tryParse(rawPenalty?.toString() ?? '') ?? 0;
        final message = data['message']?.toString().trim();
        return OrderCancellationResult(
          message:
              message == null || message.isEmpty ? 'Поездка отменена' : message,
          penalty: penalty,
          basePrice: readDouble(data['base_price']),
          currentTotalPrice: readDouble(data['current_total_price']),
          waitingSeconds: readInt(data['waiting_seconds']),
          freeWaitingSeconds: readInt(data['free_wait_seconds']),
          waitingRatePerMinute: readDouble(data['waiting_rate_per_minute']),
          waitingCharge: readDouble(data['waiting_charge']),
          isPaidWaiting: readBool(data['is_paid_waiting']),
        );
      },
      errorCodeMsgs: {
        404: 'Заказ не найден',
        403: 'Нет доступа к этому заказу',
      },
    );
  }

  // C-042: Изменение маршрута активной поездки
  static Future<ApiResponse<OrderRouteChangePreview>> previewOrderRouteChange({
    required int orderId,
    required List<Map<String, dynamic>> addresses,
  }) async {
    return RequestBuilder<OrderRouteChangePreview>().create(
      dioRequest: DioRequest.dio.post(
        '/orders/$orderId/route-change/preview',
        data: {
          'addresses': addresses,
        },
      ),
      onSuccess: (response) {
        final data = response.data;
        double parseDouble(dynamic raw) =>
            raw is num ? raw.toDouble() : double.tryParse('$raw') ?? 0.0;
        int parseInt(dynamic raw) =>
            raw is num ? raw.toInt() : int.tryParse('$raw') ?? 0;

        return OrderRouteChangePreview(
          totalPrice: parseDouble(data['total_price']),
          currentTotalPrice: parseDouble(data['current_total_price']),
          priceDelta: parseDouble(data['price_delta']),
          travelTotal: parseDouble(data['travel_total']),
          additionalServicesTotal:
              parseDouble(data['additional_services_total']),
          distance: parseInt(data['distance']),
          duration: parseInt(data['duration']),
        );
      },
      errorCodeMsgs: {
        404: 'Заказ не найден',
        400: 'Не удалось пересчитать маршрут',
        403: 'Нет доступа к этому заказу',
      },
    );
  }

  static Future<ApiResponse<void>> updateOrderRoute({
    required int orderId,
    required List<Map<String, dynamic>> addresses,
  }) async {
    return RequestBuilder<void>().create(
      dioRequest: DioRequest.dio.post(
        '/orders/$orderId/route-change',
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
