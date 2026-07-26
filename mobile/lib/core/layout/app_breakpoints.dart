import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/widgets.dart';

enum AppDeviceClass {
  compactPhone,
  largePhone,
  tablet,
  desktop,
}

class AppBreakpoints {
  AppBreakpoints._();

  static const double compactPhoneMaxWidth = 359;
  static const double largePhoneMaxWidth = 599;
  static const double tabletMaxWidth = 1023;

  static AppDeviceClass deviceClassForWidth(double width) {
    if (width <= compactPhoneMaxWidth) {
      return AppDeviceClass.compactPhone;
    }
    if (width <= largePhoneMaxWidth) {
      return AppDeviceClass.largePhone;
    }
    if (width <= tabletMaxWidth) {
      return AppDeviceClass.tablet;
    }
    return AppDeviceClass.desktop;
  }

  static AppDeviceClass deviceClassOf(BuildContext context) {
    final Size size = MediaQuery.sizeOf(context);
    // A rotated phone must remain a phone. Using its landscape width promoted
    // Samsung phones to the tablet layout and visibly stretched dashboard
    // cards. Tablets retain a larger shortest side; web remains width-driven.
    return deviceClassForWidth(kIsWeb ? size.width : size.shortestSide);
  }

  static bool isTabletOrLarger(BuildContext context) {
    final AppDeviceClass deviceClass = deviceClassOf(context);
    return deviceClass == AppDeviceClass.tablet ||
        deviceClass == AppDeviceClass.desktop;
  }

  static double horizontalPadding(BuildContext context) {
    return switch (deviceClassOf(context)) {
      AppDeviceClass.compactPhone => 16,
      AppDeviceClass.largePhone => 20,
      AppDeviceClass.tablet => 32,
      AppDeviceClass.desktop => 48,
    };
  }

  static double maxContentWidth(BuildContext context) {
    return switch (deviceClassOf(context)) {
      AppDeviceClass.compactPhone => 420,
      AppDeviceClass.largePhone => 520,
      AppDeviceClass.tablet => 760,
      AppDeviceClass.desktop => 1040,
    };
  }

  static double boardMaxSize(BuildContext context) {
    final Size size = MediaQuery.sizeOf(context);
    final double shortestSide = size.shortestSide;
    final double reservedHeight = size.height < size.width ? 160 : 280;
    final double heightBound = size.height - reservedHeight;
    final double safeHeightBound =
        heightBound < 280 ? shortestSide : heightBound;
    final double rawSize =
        shortestSide < safeHeightBound ? shortestSide : safeHeightBound;
    return rawSize.clamp(280, 720).toDouble();
  }
}
