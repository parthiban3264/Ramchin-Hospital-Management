import 'package:hospitrax/utils/utils.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  late IO.Socket socket;

  void connect() {
    socket = IO.io(
      baseUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );

    socket.connect();

    socket.onConnect((_) {});

    socket.on('queueStatusUpdate', (data) {});

    socket.onDisconnect((_) {});
  }

  void disconnect() {
    socket.disconnect();
  }
}
