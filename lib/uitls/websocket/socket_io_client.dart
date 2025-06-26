import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:hopper/Core/Consents/app_logger.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();

  factory SocketService() => _instance;

  late IO.Socket _socket;
  bool _initialized = false;

  SocketService._internal();

  void initSocket(String url) {
    if (_initialized) return;
    _initialized = true;

    _socket = IO.io(
      url,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .build(),
    );

    _socket.connect();

    _socket.onConnect((_) {
      AppLogger.log.i("✅ Connected to $url");
    });

    _socket.onDisconnect((_) {
      AppLogger.log.e("❌ Disconnected from $url");
    });

    _socket.onConnectError((err) {
      AppLogger.log.e("❗ Connect error: $err");
    });

    _socket.onError((err) {
      AppLogger.log.e("❗ General socket error: $err");
    });

    // 💡 Debug: log all incoming events
    _socket.onAny((event, data) {
      AppLogger.log.i("📦 [onAny] Event: $event, Data: $data");
    });
  }

  void onConnect(Function() callback) {
    _socket.onConnect((_) {
      AppLogger.log.i("📡 onConnect triggered");
      callback();
    });
  }

  void on(String event, Function(dynamic) callback) {
    AppLogger.log.i("👂 Listening to: $event");
    AppLogger.log.i("👂 callback to: $callback");
    _socket.on(event, callback);
  }

  void emit(String event, dynamic data) {
    AppLogger.log.i("📤 Emitting → $event");
    AppLogger.log.i("🧾 Payload: $data");
    _socket.emit(event, data);
  }

  void dispose() {
    AppLogger.log.w("🔌 Disposing socket");
    _socket.disconnect();
    _socket.dispose();
    _initialized = false;
  }
}
