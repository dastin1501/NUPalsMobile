import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../utils/api_constant.dart'; // Import the ApiConstants

class WebSocketService {
  late IO.Socket _socket;

  void init() {
    // Configure the socket
    _socket = IO.io('${ApiConstants.baseUrl}', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    // Connect to the socket
    _socket.connect();

    // Handle socket events here
    _socket.onConnect((_) {
      print('Connected to socket');
    });

    _socket.onDisconnect((_) {
      print('Disconnected from socket');
    });

    // Example event listener for incoming messages
    _socket.on('message', (data) {
      print('New message: $data');
      // Handle incoming message
    });
  }

  void sendMessage(String message) {
    if (_socket.connected) { // Check if the socket is connected
      _socket.emit('message', message); // Emit a message
    } else {
      print('Socket not connected');
    }
  }

  void dispose() {
    _socket.dispose(); // Clean up when done
  }
}
