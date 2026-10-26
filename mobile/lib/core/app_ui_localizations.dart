import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_language.dart';

/// Bundled translations for app-authored UI copy only. Never translate account
/// identifiers, user content, chess notation, or unknown server messages.
abstract final class UiCopy {
  static final ValueNotifier<String> language = ValueNotifier('en');
  static final Map<String, Map<String, String>> _catalogs = {};
  static int _request = 0;

  static String normalize(String source) =>
      source.replaceAll(RegExp(r'\s+'), ' ').trim();

  static Future<void> load(String code) async {
    final request = ++_request;
    final resolved = AppLanguageController.resolveCode(code);
    if (resolved != 'en' && !_catalogs.containsKey(resolved)) {
      final json = await rootBundle.loadString('assets/i18n/ui/$resolved.json');
      _catalogs[resolved] = Map<String, String>.from(jsonDecode(json) as Map);
    }
    if (request == _request) language.value = resolved;
  }

  static String text(String source) =>
      _catalogs[language.value]?[normalize(source)] ?? source;

  static String format(String source, List<Object?> values) =>
      text(source).replaceAllMapped(RegExp(r'\{(\d+)\}'), (match) {
        final index = int.parse(match[1]!);
        return index < values.length ? '${values[index] ?? ''}' : match[0]!;
      });
}

/// Register an inherited locale dependency so decoration strings and tooltips
/// rebuild when the application language changes.
String uiText(BuildContext context, String source) {
  Localizations.localeOf(context);
  return UiCopy.text(source);
}

/// Retains Text's styling/semantics while reacting to a loaded UI catalog.
class UiText extends StatelessWidget {
  const UiText(
    this.data, {
    this.values = const [],
    super.key,
    this.style,
    this.strutStyle,
    this.textAlign,
    this.textDirection,
    this.locale,
    this.softWrap,
    this.overflow,
    this.textScaler,
    this.maxLines,
    this.semanticsLabel,
    this.semanticsIdentifier,
    this.textWidthBasis,
    this.textHeightBehavior,
    this.selectionColor,
  });
  final String data;
  final List<Object?> values;
  final TextStyle? style;
  final StrutStyle? strutStyle;
  final TextAlign? textAlign;
  final TextDirection? textDirection;
  final Locale? locale;
  final bool? softWrap;
  final TextOverflow? overflow;
  final TextScaler? textScaler;
  final int? maxLines;
  final String? semanticsLabel;
  final String? semanticsIdentifier;
  final TextWidthBasis? textWidthBasis;
  final TextHeightBehavior? textHeightBehavior;
  final Color? selectionColor;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<String>(
    valueListenable: UiCopy.language,
    builder: (context, language, _) => Text(
      UiCopy.format(data, values),
      style: style,
      strutStyle: strutStyle,
      textAlign: textAlign,
      textDirection: textDirection,
      locale: locale,
      softWrap: softWrap,
      overflow: overflow,
      textScaler: textScaler,
      maxLines: maxLines,
      semanticsLabel: semanticsLabel == null
          ? null
          : UiCopy.text(semanticsLabel!),
      semanticsIdentifier: semanticsIdentifier,
      textWidthBasis: textWidthBasis,
      textHeightBehavior: textHeightBehavior,
      selectionColor: selectionColor,
    ),
  );
}

/// Complete single-line action text. The button still owns its tap target;
/// only its label scales down when a translation cannot fit the available width.
/// Prefer giving actions a full row before using this constrained fallback.
class UiActionText extends UiText {
  const UiActionText(
    super.data, {
    super.values,
    super.key,
    super.style,
    super.strutStyle,
    super.textAlign,
    super.textDirection,
    super.locale,
    super.softWrap = false,
    super.overflow = TextOverflow.visible,
    super.textScaler,
    super.maxLines = 1,
    super.semanticsLabel,
    super.semanticsIdentifier,
    super.textWidthBasis,
    super.textHeightBehavior,
    super.selectionColor,
  });

  @override
  Widget build(BuildContext context) =>
      FittedBox(fit: BoxFit.scaleDown, child: super.build(context));
}

class UiLanguageHost extends StatefulWidget {
  const UiLanguageHost({required this.builder, super.key});
  final Widget Function(BuildContext, Locale) builder;

  @override
  State<UiLanguageHost> createState() => _UiLanguageHostState();
}

class _UiLanguageHostState extends State<UiLanguageHost> {
  @override
  void initState() {
    super.initState();
    AppLanguageController.effectiveLanguageChanges.addListener(_load);
    _load();
  }

  Future<void> _load() async {
    final code =
        AppLanguageController.effectiveLanguageChanges.value ??
        await AppLanguageController.effectiveCode();
    await UiCopy.load(code);
  }

  @override
  void dispose() {
    AppLanguageController.effectiveLanguageChanges.removeListener(_load);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<String>(
    valueListenable: UiCopy.language,
    builder: (context, language, _) =>
        widget.builder(context, Locale(language)),
  );
}
