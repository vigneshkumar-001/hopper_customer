import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:hopper/Core/Consents/app_logger.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();

  factory SocketService() => _instance;

  late IO.Socket _socket;
  bool _initialized = false;

  SocketService._internal();

  void initSocket(String url) {
    if (_initialized) {
      if (_socket.disconnected) {
        _socket.connect(); // reconnect if not connected
      }
      return;
    }

    _initialized = true;

    _socket = IO.io(
      url,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .enableReconnection()
          .enableAutoConnect()
          .setReconnectionAttempts(5)
          .setReconnectionDelay(2000)
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

    // Optional: log all incoming events
    _socket.onAny((event, data) {
      AppLogger.log.i("📦 [onAny] Event: $event, Data: $data");
    });
  }

  void registerUser(String userId) {
    emit('register', {
      'userId': userId,
      'type': 'customer',
    });
  }

  void onConnect(Function() callback) {
    _socket.onConnect((_) {
      AppLogger.log.i("📡 onConnect triggered");
      callback();
    });
  }

  void on(String event, Function(dynamic) callback) {
    _socket.on(event, callback);
  }

  void emit(String event, dynamic data) {
    _socket.emit(event, data);
  }
  void off(String event) {
    _socket.off(event);
  }

  void dispose() {
    _socket.dispose();
    _initialized = false;
  }
}
