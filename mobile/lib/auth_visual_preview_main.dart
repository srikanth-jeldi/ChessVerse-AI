import 'package:flutter/material.dart';

import 'features/auth/presentation/auth_screen.dart';
import 'main.dart' show ChessVerseTheme;

void main() {
  runApp(const _AuthVisualPreviewApp());
}

class _AuthVisualPreviewApp extends StatelessWidget {
  const _AuthVisualPreviewApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ChessVerseTheme.dark(),
      home: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 2000) {
            const previewSize = Size(1440, 900);
            return Align(
              alignment: Alignment.topLeft,
              child: Transform.scale(
                scale: 2,
                alignment: Alignment.topLeft,
                child: MediaQuery(
                  data: MediaQuery.of(context).copyWith(size: previewSize),
                  child: SizedBox(
                    width: previewSize.width,
                    height: previewSize.height,
                    child: AuthScreen(onAuthenticated: (_) {}),
                  ),
                ),
              ),
            );
          }
          if (constraints.maxWidth > 700 && constraints.maxWidth < 1000) {
            const previewSize = Size(390, 1200);
            return Align(
              alignment: Alignment.topLeft,
              child: Transform.scale(
                scale: 2,
                alignment: Alignment.topLeft,
                child: MediaQuery(
                  data: MediaQuery.of(context).copyWith(size: previewSize),
                  child: SizedBox(
                    width: previewSize.width,
                    height: previewSize.height,
                    child: AuthScreen(onAuthenticated: (_) {}),
                  ),
                ),
              ),
            );
          }
          return AuthScreen(onAuthenticated: (_) {});
        },
      ),
    );
  }
}
