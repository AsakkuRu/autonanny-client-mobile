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

      String? errorMessage;
      errorCodeMsgs?.forEach((key, value) {
        if (e.response!.statusCode == key) errorMessage = value;
      });

      return ApiResponse(errorMessage: errorMessage ?? defaultErrorMsg);
    } catch (e) {
      return ApiResponse(errorMessage: "Отсутствует подключение к интернету");
    }

    String errorMessage = "Запрос успешен";

    errorCodeMsgs?.forEach((key, value) {
      if (result.statusCode == key) errorMessage = value;
    });

    // bool success = false;
    // if(result.data['status'].runtimeType == String) {
    //   success = result.data['status'] == "OK";
    // }
    // else {
    //   success = result.data['status'];
    // }

    return ApiResponse<T>(
        statusCode: result.statusCode!,
        errorMessage: errorMessage,
        success: result.statusCode == 200 || result.statusCode == 201,
        response: onSuccess?.call(result));
  }
}
