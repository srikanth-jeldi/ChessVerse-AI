import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'app_breakpoints.dart';

class ResponsivePage extends StatelessWidget {
  const ResponsivePage({
    required this.child,
    this.scrollable = true,
    this.safeArea = true,
    this.backgroundGradient = true,
    super.key,
  });

  final Widget child;
  final bool scrollable;
  final bool safeArea;
  final bool backgroundGradient;

  @override
  Widget build(BuildContext context) {
    final EdgeInsets mediaPadding = MediaQuery.paddingOf(context);
    final EdgeInsets pagePadding = EdgeInsets.fromLTRB(
      AppBreakpoints.horizontalPadding(context),
      20,
      AppBreakpoints.horizontalPadding(context),
      24 + mediaPadding.bottom,
    );

    Widget content = Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: AppBreakpoints.maxContentWidth(context),
        ),
        child: Padding(
          padding: pagePadding,
          child: child,
        ),
      ),
    );

    if (scrollable) {
      content = SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: content,
      );
    }

    if (safeArea) {
      content = SafeArea(child: content);
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.background,
        gradient: backgroundGradient ? AppColors.backgroundGradient : null,
      ),
      child: content,
    );
  }
}
