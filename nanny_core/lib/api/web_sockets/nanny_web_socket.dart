import 'dart:async';
import 'package:nanny_core/nanny_core.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class NannyWebSocket {
  NannyWebSocket();

  WebSocketChannel? _channel;
  WebSocketSink? _sink;
  StreamSubscription? _sub;

  final _controller = StreamController<String>.broadcast();
  Stream get stream => _controller.stream;

  bool _connected = false;
  bool _reconnecting = false;
  int _retryCount = 0;
  static const int _maxRetries = 15;
  static const Duration _retryDelay = Duration(seconds: 3);

  bool get connected => _connected;
  String get address => "";

  WebSocketSink get sink => _sink ?? _noOpSink;

  Future<NannyWebSocket> connect() async {
    final url = address;
    if (url.isEmpty) {
      Logger().e("❌ [WebSocket] address is empty");
      throw StateError('WebSocket address is empty');
    }
    try {
      Logger().i("🔄 [WebSocket] Подключение к $url...");
      _channel = WebSocketChannel.connect(Uri.parse(url));
      _sink = _channel!.sink;
      await _channel!.ready;
      _connected = true;
      _retryCount = 0;

      Logger().i("✅ [WebSocket] Подключено к $url");

      _sub?.cancel();
      _sub = _channel!.stream.listen(
        (data) {
          Logger().i("🟢 [WebSocket] Получено: $data");
          _controller.add(data);
        },
        onError: (error) {
          Logger().e("🔴 [WebSocket] Ошибка потока: $error");
          _connected = false;
          _reconnect();
        },
        onDone: () {
          Logger().w("⚠️ [WebSocket] Поток закрыт для $url — переподключение...");
          _connected = false;
          _reconnect();
        },
        cancelOnError: true,
      );

      return this;
    } catch (e) {
      Logger().e("❌ [WebSocket] Ошибка подключения к $url: $e");
      _connected = false;
      _reconnect();
      rethrow;
    }
  }

  void _reconnect() {
    if (_reconnecting) return;
    if (_retryCount >= _maxRetries) {
      Logger().w("⏳ [WebSocket] Достигнут лимит попыток ($_maxRetries)");
      return;
    }
    _reconnecting = true;
    _retryCount++;
    Logger().i("🔄 [WebSocket] Попытка #$_retryCount через ${_retryDelay.inSeconds} сек...");
    Future.delayed(_retryDelay, () async {
      _reconnecting = false;
      if (!_connected) {
        try {
          await connect();
        } catch (_) {}
      }
    });
  }

  void send(String message) {
    if (_connected && _sink != null) {
      Logger().i("📤 [WebSocket] Отправка: $message");
      _sink!.add(message);
    } else {
      Logger().w("⚠️ [WebSocket] Отправка при отключении: $message");
    }
  }

  void dispose() {
    try {
      Logger().w("🛑 [WebSocket] Закрытие $address...");
      _sub?.cancel();
      _sink?.close();
      _controller.close();
      _connected = false;
      Logger().i("✅ [WebSocket] Закрыт");
    } catch (e) {
      Logger().e("❌ [WebSocket] Ошибка при закрытии: $e");
    }
  }
}

final _noOpSink = _NoOpSink();

class _NoOpSink implements WebSocketSink {
  @override
  void add(data) {}

  @override
  void addError(Object error, [StackTrace? stackTrace]) {}

  @override
  Future addStream(Stream stream) => Future.value();

  @override
  Future close([int? code, String? reason]) => Future.value();

  @override
  Future get done => Future.value();
}
