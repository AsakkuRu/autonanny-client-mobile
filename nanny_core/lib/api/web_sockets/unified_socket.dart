import 'dart:async';
import 'dart:convert';

import 'package:nanny_core/nanny_core.dart';

/// Единый WebSocket-клиент для всех событий (заказы, чат, системные).
///
/// Подключается к `ws://{host}/api/v1.0/ws?token={JWT}`.
/// Синглтон — одно соединение на приложение.
///
/// Использование:
/// ```dart
/// final socket = await UnifiedSocket.connect();
/// socket.on('trip.status_changed').listen((msg) { ... });
/// socket.send('ping', {});
/// ```
class UnifiedSocket {
  static UnifiedSocket? _instance;

  WebSocketChannel? _channel;
  WebSocketSink? _sink;
  StreamSubscription? _sub;
  Future<void>? _connectFuture;
  bool _disposed = false;

  final _controller = StreamController<Map<String, dynamic>>.broadcast();
  final Map<String, bool> _desiredSubscriptionState = <String, bool>{};
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
    final instance = _instance ??= UnifiedSocket._();
    await instance._ensureConnected();
    return instance;
  }

  /// Получить текущий инстанс (без подключения). Null если не подключён.
  static UnifiedSocket? get instance => _instance;

  Future<void> _ensureConnected() async {
    if (_disposed) return;
    if (_connected && _sink != null && _channel != null) return;

    final pending = _connectFuture;
    if (pending != null) {
      await pending;
      return;
    }

    final completer = Completer<void>();
    _connectFuture = completer.future;
    try {
      await _connect();
      if (!completer.isCompleted) completer.complete();
    } catch (e, st) {
      if (!completer.isCompleted) completer.completeError(e, st);
    } finally {
      _connectFuture = null;
    }
  }

  Future<void> _connect() async {
    if (_disposed) return;
    final token = DioRequest.authToken;
    if (token.isEmpty) {
      Logger().e("❌ [UnifiedSocket] No auth token available");
      return;
    }

    final url = "${NannyConsts.socketUrl}/ws?token=$token";

    try {
      Logger().i("🔄 [UnifiedSocket] Подключение к $url...");
      await _sub?.cancel();
      _sub = null;
      _channel = WebSocketChannel.connect(Uri.parse(url));
      _sink = _channel!.sink;
      await _channel!.ready;
      if (_disposed) {
        return;
      }
      _connected = true;
      _retryCount = 0;

      Logger().i("✅ [UnifiedSocket] Подключено");

      _sub = _channel!.stream.listen(
        _onData,
        onError: (error) {
          Logger().e("🔴 [UnifiedSocket] Ошибка: $error");
          _connected = false;
          _reconnect();
        },
        onDone: () {
          Logger()
              .w("⚠️ [UnifiedSocket] Соединение закрыто — переподключение...");
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
        if (event == 'connected') {
          _replaySessionState();
        }
        _controller.add(decoded);
      }
    } catch (e) {
      Logger().e("❌ [UnifiedSocket] Ошибка парсинга: $e");
    }
  }

  void _trackDesiredSubscriptions(Map<String, dynamic> data) {
    final raw = data['subscriptions'];
    if (raw is! Map) return;

    raw.forEach((key, value) {
      if (key is! String || value is! bool) return;
      final name = key.trim();
      if (name.isEmpty) return;
      _desiredSubscriptionState[name] = value;
    });
  }

  void _replaySessionState() {
    if (!_connected || _sink == null || _desiredSubscriptionState.isEmpty) {
      return;
    }

    final message = jsonEncode({
      "v": 1,
      "event": "subscriptions.update",
      "data": {
        "subscriptions": Map<String, bool>.from(_desiredSubscriptionState),
      },
      "ts": DateTime.now().millisecondsSinceEpoch ~/ 1000,
    });

    Logger().i(
      "🔁 [UnifiedSocket] Восстанавливаю subscriptions: ${_desiredSubscriptionState.keys.toList()}",
    );
    _sink!.add(message);
  }

  void _reconnect() {
    if (_disposed) return;
    if (_reconnecting) return;
    if (_retryCount >= _maxRetries) {
      Logger().w("⏳ [UnifiedSocket] Лимит попыток ($_maxRetries) исчерпан");
      return;
    }
    _reconnecting = true;
    _retryCount++;
    Logger().i(
        "🔄 [UnifiedSocket] Попытка #$_retryCount через ${_retryDelay.inSeconds} сек...");
    Future.delayed(_retryDelay, () async {
      _reconnecting = false;
      if (!_connected && !_disposed) {
        try {
          if (_retryCount == 1 || _retryCount % 3 == 0) {
            final recoveredToken = await DioRequest.recoverAccessToken();
            if (recoveredToken != null && recoveredToken.isNotEmpty) {
              Logger().w("🔐 [UnifiedSocket] Токен обновлён перед reconnect");
            }
          }
          await _ensureConnected();
        } catch (_) {}
      }
    });
  }

  /// Отправить событие на сервер.
  void send(String event, Map<String, dynamic> data, {String? ref}) {
    if (event == 'subscriptions.update') {
      _trackDesiredSubscriptions(data);
      if (!_connected || _sink == null) {
        Logger().i("📦 [UnifiedSocket] Очередь subscriptions.update до reconnect");
        return;
      }
    }

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
      _disposed = true;
      _sub?.cancel();
      _sink?.close();
      if (!_controller.isClosed) _controller.close();
      _connected = false;
      _connectFuture = null;
      _reconnecting = false;
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

  Future<void> forceReconnect() async {
    if (_disposed) return;
    _connected = false;
    _reconnecting = false;
    try {
      await _sub?.cancel();
    } catch (_) {}
    _sub = null;
    try {
      await _sink?.close();
    } catch (_) {}
    _sink = null;
    _channel = null;
    await _ensureConnected();
  }
}
