import 'package:flutter/material.dart';
import 'package:google_sign_in_web/web_only.dart' as google_web;

Widget buildGoogleProviderButton(VoidCallback onPressed) {
  return Center(child: google_web.renderButton());
}
