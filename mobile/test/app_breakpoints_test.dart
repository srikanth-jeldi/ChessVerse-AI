import 'package:chessverse_ai/core/layout/app_breakpoints.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('landscape mobile browser remains a phone layout', () {
    expect(
      AppBreakpoints.deviceClassForSize(const Size(844, 390)),
      AppDeviceClass.largePhone,
    );
  });

  test('tablet and desktop sizes retain wide layouts', () {
    expect(
      AppBreakpoints.deviceClassForSize(const Size(800, 600)),
      AppDeviceClass.tablet,
    );
    expect(
      AppBreakpoints.deviceClassForSize(const Size(1440, 900)),
      AppDeviceClass.desktop,
    );
  });
}
