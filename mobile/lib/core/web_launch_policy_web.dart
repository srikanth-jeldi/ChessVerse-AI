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
  // Flutter stores navigation bookkeeping in history.state. Replacing it with
  // null breaks the framework's route-information synchronization and causes
  // an uncaught startup exception after the `fresh=1` redirect.
  html.window.history.replaceState(
    html.window.history.state,
    '',
    cleanedUri.toString(),
  );
  return true;
}
