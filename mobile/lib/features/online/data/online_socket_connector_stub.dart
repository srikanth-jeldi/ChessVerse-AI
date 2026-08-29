import 'package:web_socket_channel/web_socket_channel.dart';

const bool onlineSocketRequiresTicket = true;

WebSocketChannel connectOnlineSocket(Uri uri, String token, String? ticket) {
  throw UnsupportedError('WebSocket transport is unavailable.');
}
