import 'dart:async';
import 'dart:convert';

import 'package:nanny_core/nanny_core.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Единый WebSocket-клиент для всех событий (заказы, чат, системные).
///
/// Подключается к `ws://{host}/api/v1.0/ws?token={JWT}`.
/// Синглтон — одно соединение на приложение.
///
/// Использование:
/// ```dart
/// final socket = await UnifiedSocket.connect();
/// socket.on('order.status_changed').listen((msg) { ... });
/// socket.send('ping', {});
/// ```
class UnifiedSocket {
  static UnifiedSocket? _instance;

  WebSocketChannel? _channel;
  WebSocketSink? _sink;
  StreamSubscription? _sub;

  final _controller = StreamController<Map<String, dynamic>>.broadcast();
  bool _connected = false;
  bool _reconnecting = false;
  int _retryCount = 0;
  static const int _maxRetries = 15;
  static const Duration _retryDelay = Duration(seconds: 3);

  UnifiedSocket._();

  /// Поток всех входящих событий (распарсенные JSON).
  Stream<Map<String, dynamic>> get events => _controller.stream;

  /// Подписка на конкретный тип событий.
  Stream<Map<String, dynamic>> on(String eventType) {
    return _controller.stream.where((msg) => msg['event'] == eventType);
  }

  /// Подключён ли WS.
  bool get connected => _connected;

  /// Подключение. Если уже есть активный инстанс — возвращает его.
  static Future<UnifiedSocket> connect() async {
    if (_instance != null && _instance!._connected) return _instance!;
    _instance = UnifiedSocket._();
    await _instance!._connect();
    return _instance!;
  }

  /// Получить текущий инстанс (без подключения). Null если не подключён.
  static UnifiedSocket? get instance => _instance;

  Future<void> _connect() async {
    final token = DioRequest.authToken;
    if (token.isEmpty) {
      Logger().e("❌ [UnifiedSocket] No auth token available");
      return;
    }

    final url = "${NannyConsts.socketUrl}/ws?token=$token";

    try {
      Logger().i("🔄 [UnifiedSocket] Подключение к $url...");
      _channel = WebSocketChannel.connect(Uri.parse(url));
      _sink = _channel!.sink;
      await _channel!.ready;
      _connected = true;
      _retryCount = 0;

      Logger().i("✅ [UnifiedSocket] Подключено");

      _sub?.cancel();
      _sub = _channel!.stream.listen(
        _onData,
        onError: (error) {
          Logger().e("🔴 [UnifiedSocket] Ошибка: $error");
          _connected = false;
          _reconnect();
        },
        onDone: () {
          Logger().w("⚠️ [UnifiedSocket] Соединение закрыто — переподключение...");
          _connected = false;
          _reconnect();
        },
        cancelOnError: true,
      );
    } catch (e) {
      Logger().e("❌ [UnifiedSocket] Ошибка подключения: $e");
      _connected = false;
      _reconnect();
    }
  }

  void _onData(dynamic rawData) {
    try {
      final decoded = rawData is String ? jsonDecode(rawData) : rawData;
      if (decoded is Map<String, dynamic>) {
        final event = decoded['event'];
        Logger().i("🟢 [UnifiedSocket] Событие: $event");
        _controller.add(decoded);
      }
    } catch (e) {
      Logger().e("❌ [UnifiedSocket] Ошибка парсинга: $e");
    }
  }

  void _reconnect() {
    if (_reconnecting) return;
    if (_retryCount >= _maxRetries) {
      Logger().w("⏳ [UnifiedSocket] Лимит попыток ($_maxRetries) исчерпан");
      return;
    }
    _reconnecting = true;
    _retryCount++;
    Logger().i("🔄 [UnifiedSocket] Попытка #$_retryCount через ${_retryDelay.inSeconds} сек...");
    Future.delayed(_retryDelay, () async {
      _reconnecting = false;
      if (!_connected) {
        try {
          await _connect();
        } catch (_) {}
      }
    });
  }

  /// Отправить событие на сервер.
  void send(String event, Map<String, dynamic> data, {String? ref}) {
    if (!_connected || _sink == null) {
      Logger().w("⚠️ [UnifiedSocket] Отправка при отключении: $event");
      return;
    }
    final message = jsonEncode({
      "v": 1,
      "event": event,
      "data": data,
      "ts": DateTime.now().millisecondsSinceEpoch ~/ 1000,
      if (ref != null) "ref": ref,
    });
    _sink!.add(message);
  }

  /// Закрыть соединение и сбросить синглтон.
  void dispose() {
    try {
      Logger().w("🛑 [UnifiedSocket] Закрытие...");
      _sub?.cancel();
      _sink?.close();
      if (!_controller.isClosed) _controller.close();
      _connected = false;
      _instance = null;
      Logger().i("✅ [UnifiedSocket] Закрыт");
    } catch (e) {
      Logger().e("❌ [UnifiedSocket] Ошибка при закрытии: $e");
    }
  }

  /// Сброс (для logout). Закрывает соединение и обнуляет инстанс.
  static void reset() {
    _instance?.dispose();
    _instance = null;
  }
}
