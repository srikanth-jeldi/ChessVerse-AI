// ignore_for_file: avoid_web_libraries_in_flutter
// ignore: deprecated_member_use
import 'dart:html' as html;

bool consumeFreshWebLaunch() {
  final uri = Uri.base;
  if (uri.queryParameters['fresh'] != '1') {
    return false;
  }

  final queryParameters = Map<String, String>.from(uri.queryParameters)
    ..remove('fresh');
  final cleanedUri = uri.replace(queryParameters: queryParameters);
  html.window.history.replaceState(null, '', cleanedUri.toString());
  return true;
}
