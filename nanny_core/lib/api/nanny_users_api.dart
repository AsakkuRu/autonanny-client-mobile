import 'package:dio/dio.dart';
import 'package:nanny_core/api/api_models/add_debit_card_request.dart';
import 'package:nanny_core/api/api_models/add_money_request.dart';
import 'package:nanny_core/api/api_models/base_models/api_response.dart';
import 'package:nanny_core/api/api_models/confirm_payment_request.dart';
import 'package:nanny_core/api/api_models/sos_activate_request.dart';
import 'package:nanny_core/api/api_models/start_payment_request.dart';
import 'package:nanny_core/api/api_models/start_sbp_payment_request.dart';
import 'package:nanny_core/api/api_models/update_me_request.dart';
import 'package:nanny_core/api/dio_request.dart';
import 'package:nanny_core/constants.dart';
import 'package:nanny_core/api/request_builder.dart';
import 'package:nanny_core/models/from_api/check_3ds_data.dart';
import 'package:nanny_core/models/from_api/driver_contact.dart';
import 'package:nanny_core/models/from_api/notification_item.dart';
import 'package:nanny_core/models/from_api/payment_init_data.dart';
import 'package:nanny_core/models/from_api/sbp_init_data.dart';
import 'package:nanny_core/models/from_api/transaction.dart';
import 'package:nanny_core/models/from_api/user_cards.dart';
import 'package:nanny_core/models/from_api/user_info.dart';
import 'package:nanny_core/models/from_api/user_money.dart';

class NannyUsersApi {
  static Future<ApiResponse<UserInfo>> getMe() async {
    return RequestBuilder<UserInfo>().create(
      dioRequest: DioRequest.dio.get("/users/get_me"),
      onSuccess: (response) => UserInfo.fromJson(response.data['me']),
    );
  }

  static Future<ApiResponse<void>> updateMe(UpdateMeRequest request) async {
    return RequestBuilder().create(
      dioRequest:
          DioRequest.dio.put("/users/update_me", data: request.toJson()),
    );
  }

  static Future<ApiResponse<UserMoney>> getMoney({String? period}) async {
    return RequestBuilder<UserMoney>().create(
      dioRequest: DioRequest.dio.post("/users/money?period=$period"),
      onSuccess: (response) => UserMoney.fromJson(response.data),
    );
  }

  static Future<ApiResponse<int>> addDebitCard(
      AddDebitCardRequest request) async {
    return RequestBuilder<int>().create(
        dioRequest: DioRequest.dio
            .post("/users/demo/cards/add", data: request.toJson()),
        onSuccess: (response) => response.data['card_id'],
        errorCodeMsgs: {
          // 404 здесь означает, что ручка не найдена на выбранном backend-окружении
          // (например, приложение смотрит на боевой бэк вместо демо).
          404: "Demo-ручка не найдена. Проверьте, что приложение смотрит на демо-бэкенд.",
          405: "Недопустимый банк карты!",
          406: "Карта уже добавлена!",
          407: "Некорректная дата сгорания карты!",
          408: "Некорректное имя носителя карты!",
        });
  }

  static Future<ApiResponse<PaymentInitData>> startPayment(
      StartPaymentRequest request) async {
    // В demo‑режиме не инициализируем реальный платёж, а сразу имитируем успешное пополнение
    return RequestBuilder<PaymentInitData>().create(
      dioRequest: DioRequest.dio.post(
        "/users/demo/balance/topup",
        data: {
          "amount": request.amount / 100, // из копеек в рубли
          "description": "DEMO: Пополнение карты",
        },
      ),
      onSuccess: (_) => PaymentInitData(
        paymentId: "demo",
        terminalKey: "",
        is3DsV2: false,
        threeDsMethod: "",
        serverTransId: "",
      ),
    );
  }

  static Future<ApiResponse<SbpInitData>> startSbpPayment(
      StartSbpPaymentRequest request) async {
    // В demo‑режиме СБП также идёт через моковое пополнение
    return RequestBuilder<SbpInitData>().create(
      dioRequest: DioRequest.dio.post(
        "/users/demo/balance/topup",
        data: {
          "amount": request.amount / 100,
          "description": "DEMO: Пополнение по СБП",
        },
      ),
      onSuccess: (_) => SbpInitData(
        paymentId: "demo",
        paymentUrl: "",
      ),
    );
  }

  static Future<ApiResponse<Check3DsData>> confirmPayment(
      ConfirmPaymentRequest request) async {
    return RequestBuilder<Check3DsData>().create(
      dioRequest:
          DioRequest.dio.post("/users/confirm_payment", data: request.toJson()),
      onSuccess: (response) => Check3DsData.fromJson(response.data),
    );
  }

  static Future<ApiResponse<UserCards>> getUserCards() async {
    return RequestBuilder<UserCards>().create(
      dioRequest: DioRequest.dio.post("/users/get-my-card"),
      onSuccess: (response) => UserCards.fromJson(response.data),
    );
  }

  static Future<ApiResponse<void>> deleteMyCard({required int id}) async {
    var data = <String, dynamic>{
      "id": id,
    };
    return RequestBuilder().create(
      dioRequest: DioRequest.dio.post("/users/delete-my-card", data: data),
    );
  }

  static Future<ApiResponse<void>> addMoney(AddMoneyRequest request) async {
    // В demo‑режиме баланс уже пополняется через /users/demo/balance/topup,
    // поэтому здесь просто возвращаем успешный ответ без дополнительного запроса.
    return ApiResponse(success: true);
  }

  // BE-MVP-028: История транзакций с пагинацией и фильтрацией
  static Future<ApiResponse<TransactionListResponse>> getTransactions({
    int page = 1,
    int perPage = 50,
    String? startDate,
    String? endDate,
    String? transactionType,
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'per_page': perPage,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
      if (transactionType != null) 'transaction_type': transactionType,
    };
    return RequestBuilder<TransactionListResponse>().create(
      dioRequest: DioRequest.dio.get(
        '/users/transactions',
        queryParameters: params,
      ),
      onSuccess: (response) =>
          TransactionListResponse.fromJson(response.data),
    );
  }

  static Future<ApiResponse<String?>> resumePaymentSchedule(int scheduleId) async {
    return RequestBuilder<String?>().create(
      dioRequest: DioRequest.dio.post(
        '/users/payment_schedule/resume/$scheduleId',
      ),
      onSuccess: (response) => response.data['next_payment_date']?.toString(),
      errorCodeMsgs: {
        400: 'Не удалось возобновить автоплатеж по контракту',
        404: 'Контракт или расписание платежей не найдено',
      },
    );
  }

  static Future<ApiResponse<List<NotificationItem>>> getNotifications({
    int offset = 0,
    int limit = 50,
  }) async {
    return RequestBuilder<List<NotificationItem>>().create(
      dioRequest: DioRequest.dio.get(
        '/users/notifications',
        queryParameters: {
          'offset': offset,
          'limit': limit,
        },
      ),
      onSuccess: (response) {
        final rawItems = response.data['notifications'];
        if (rawItems is! List) {
          return <NotificationItem>[];
        }
        return rawItems
            .whereType<Map>()
            .map((item) => NotificationItem.fromJson(Map<String, dynamic>.from(item)))
            .toList();
      },
    );
  }

  static Future<ApiResponse<void>> markNotificationRead(int id) async {
    return RequestBuilder<void>().create(
      dioRequest: DioRequest.dio.post('/users/notifications/$id/read'),
    );
  }

  static Future<ApiResponse<void>> markAllNotificationsRead() async {
    return RequestBuilder<void>().create(
      dioRequest: DioRequest.dio.post('/users/notifications/read_all'),
    );
  }

  // FE-MVP-009: Получение контактов водителя для расписания
  static Future<ApiResponse<DriverContact>> getDriverContact(int scheduleId) async {
    return RequestBuilder<DriverContact>().create(
      dioRequest: DioRequest.dio.get("/users/driver_contact/$scheduleId"),
      onSuccess: (response) => DriverContact.fromJson(response.data['driver']),
      errorCodeMsgs: {
        404: "Водитель еще не назначен на этот контракт"
      },
    );
  }

  // FE-MVP-003: Активация SOS-кнопки (BUG-140326-009: таймаут для диагностики)
  static Future<ApiResponse<void>> activateSOS(SOSActivateRequest request) async {
    return RequestBuilder<void>()
        .create(
          dioRequest: DioRequest.dio.post(
            "/users/activate_sos",
            data: request.toJson(),
            options: Options(
              sendTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 15),
            ),
          ),
          errorCodeMsgs: {
            400: "Ошибка при активации SOS",
            500: "Сервер не отвечает. Проверьте, что backend запущен и доступен по ${NannyConsts.baseUrl}",
          },
        )
        .timeout(
          const Duration(seconds: 18),
          onTimeout: () => ApiResponse(
            errorMessage:
                "Таймаут. Проверьте интернет и доступность сервера (${NannyConsts.baseUrl})",
          ),
        );
  }
}
