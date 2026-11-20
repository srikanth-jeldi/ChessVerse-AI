// ignore_for_file: avoid_web_libraries_in_flutter
// ignore: deprecated_member_use
import 'dart:html' as html;

final bool useClassicWebBoardPieces = _usesWebKitForChessPieces() ||
    Uri.base.queryParameters['classicPieces'] == '1';

bool _usesWebKitForChessPieces() {
  final String agent = html.window.navigator.userAgent;
  if (!agent.contains('AppleWebKit/')) return false;
  // All iOS browsers share WebKit. iPadOS may use a desktop Safari user agent.
  if (RegExp(r'iPhone|iPad|iPod').hasMatch(agent)) return true;
  return agent.contains('Safari/') &&
      !RegExp(r'Chrome/|Chromium/|Edg/|OPR/').hasMatch(agent);
}

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
