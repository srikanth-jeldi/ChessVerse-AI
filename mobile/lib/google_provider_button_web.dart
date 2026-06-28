import 'package:flutter/material.dart';
import 'package:google_sign_in_web/web_only.dart' as google_web;

Widget buildGoogleProviderButton(VoidCallback onPressed) {
  return LayoutBuilder(
    builder: (BuildContext context, BoxConstraints constraints) {
      final double buttonWidth = constraints.maxWidth.clamp(220, 400);
      return SizedBox(
        width: double.infinity,
        height: 44,
        child: Center(
          child: google_web.renderButton(
            configuration: google_web.GSIButtonConfiguration(
              type: google_web.GSIButtonType.standard,
              theme: google_web.GSIButtonTheme.filledBlack,
              size: google_web.GSIButtonSize.large,
              text: google_web.GSIButtonText.continueWith,
              shape: google_web.GSIButtonShape.rectangular,
              logoAlignment: google_web.GSIButtonLogoAlignment.left,
              minimumWidth: buttonWidth,
              locale: 'en',
            ),
          ),
        ),
      );
    },
  );
}
