import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

const bool onlineSocketRequiresTicket = false;

WebSocketChannel connectOnlineSocket(Uri uri, String token, String? ticket) {
  return IOWebSocketChannel.connect(
    uri,
    headers: <String, dynamic>{'Authorization': 'Bearer $token'},
    pingInterval: const Duration(seconds: 20),
    connectTimeout: const Duration(seconds: 12),
  );
}
