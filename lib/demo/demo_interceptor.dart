import 'package:dio/dio.dart';
import 'package:nanny_client/demo/demo_data_provider.dart';

/// B-012 TASK-B12: Dio-перехватчик для демо-режима (клиентская часть)
/// Перехватывает API-запросы и возвращает статичные демо-данные
class DemoInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final demoResponse = DemoDataProvider.getResponse(options.path);
    if (demoResponse != null) {
      handler.resolve(
        Response(
          requestOptions: options,
          data: demoResponse,
          statusCode: 200,
        ),
      );
    } else {
      handler.next(options);
    }
  }
}
