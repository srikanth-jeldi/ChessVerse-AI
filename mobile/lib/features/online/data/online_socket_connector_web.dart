import 'package:web_socket_channel/html.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

WebSocketChannel connectOnlineSocket(Uri uri, String token) {
  return HtmlWebSocketChannel.connect(
    uri.replace(
      queryParameters: <String, String>{'access_token': token},
    ),
  );
}
