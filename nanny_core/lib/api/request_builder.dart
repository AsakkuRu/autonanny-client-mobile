import 'package:dio/dio.dart';
import 'package:nanny_core/api/dio_request.dart';

import 'api_models/base_models/api_response.dart';

class RequestBuilder<T> {
  Future<ApiResponse<T>> create({
    required Future<Response<dynamic>> dioRequest,
    T Function(Response response)? onSuccess,
    Map<int, String>? errorCodeMsgs,
    String defaultErrorMsg = "Произошла непредвиденная ошибка!",
  }) async {
    late Response result;
    try {
      result = await dioRequest;
    } on DioException catch (e) {
      if (e.response == null) {
        return ApiResponse(
            statusCode: 422,
            errorMessage:
                "Сервер ничего не вернул или отсутствует подключение к интернету");
      }

      if (e.response!.statusCode == 500) {
        return ApiResponse(
            statusCode: 500, errorMessage: "Сервер не отвечает!");
      }

      // Try to extract error message from response body
      String? errorMessage;
      try {
        final data = e.response!.data;
        if (data is Map) {
          errorMessage = data['message'] ?? data['error'] ?? data['detail'];
        }
      } catch (_) {}

      // Check custom error code messages
      errorCodeMsgs?.forEach((key, value) {
        if (e.response!.statusCode == key) errorMessage = value;
      });

      return ApiResponse(
        statusCode: e.response!.statusCode ?? 0,
        errorMessage: errorMessage ?? defaultErrorMsg,
      );
    } catch (e) {
      return ApiResponse(errorMessage: "Отсутствует подключение к интернету");
    }

    final ok = result.statusCode == 200 || result.statusCode == 201;
    String errorMessage = ok ? "Запрос успешен" : defaultErrorMsg;

    errorCodeMsgs?.forEach((key, value) {
      if (result.statusCode == key) errorMessage = value;
    });

    if (!ok) {
      final data = result.data;
      if (data is Map && data['message'] is String) {
        final m = (data['message'] as String).trim();
        if (m.isNotEmpty) {
          errorMessage = m;
        }
      }
    }

    return ApiResponse<T>(
        statusCode: result.statusCode!,
        errorMessage: errorMessage,
        success: ok,
        response: onSuccess?.call(result));
  }
}
