import 'package:web_socket_channel/html.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

const bool onlineSocketRequiresTicket = true;

WebSocketChannel connectOnlineSocket(Uri uri, String token, String? ticket) {
  if (ticket == null || ticket.isEmpty) {
    throw StateError('A WebSocket ticket is required.');
  }
  return HtmlWebSocketChannel.connect(
    uri.replace(
      queryParameters: <String, String>{'ticket': ticket},
    ),
  );
}
