import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

import '../../core/app_ui_localizations.dart';
import '../../core/audio/cloud_narration_service.dart';
import '../../core/coach_persona.dart';

class CoachPickerScreen extends StatefulWidget {
  const CoachPickerScreen({super.key, this.languageCode});
  final String? languageCode;
  @override
  State<CoachPickerScreen> createState() => _CoachPickerScreenState();
}

class _CoachPickerScreenState extends State<CoachPickerScreen>
    with WidgetsBindingObserver {
  CoachPersona _selected = CoachPersona.mira;
  CoachPersona? _preview;
  bool _saving = false;
  int _epoch = 0;
  CloudNarrationService? _narrator;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    CoachPersona.load().then((value) {
      if (mounted) setState(() => _selected = value);
    });
  }

  void _stop() {
    _epoch++;
    _narrator?.stop().catchError((Object _) {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _stop();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _epoch++;
    _narrator?.dispose().catchError((Object _) {});
    super.dispose();
  }

  Future<void> _listen(CoachPersona coach) async {
    _stop();
    final epoch = _epoch;
    setState(() => _preview = coach);
    _narrator ??= CloudNarrationService(preferImmediateLocal: false);
    final language = widget.languageCode ?? UiCopy.language.value;
    bool played = false;
    try {
      final catalog = jsonDecode(
        await rootBundle.loadString('assets/i18n/ui/$language.json'),
      ) as Map;
      if (!mounted || epoch != _epoch) return;
      played = await _narrator!.speak(
        text: catalog[coach.preview] as String? ?? coach.preview,
        language: language,
        tone: coach.tone,
        voiceGender: coach.gender,
        allowLocalFallback: false,
        canSpeak: () =>
            mounted &&
            epoch == _epoch &&
            (ModalRoute.of(context)?.isCurrent ?? false),
      );
    } on Object {
      played = false;
    }
    if (!mounted || epoch != _epoch) return;
    setState(() => _preview = null);
    if (!played) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: UiText(
            'Voice could not play. Check your connection and media volume, then turn voice off and on to retry.',
          ),
        ),
      );
    }
  }

  Future<void> _select(CoachPersona coach) async {
    _stop();
    setState(() => _saving = true);
    try {
      await coach.save();
      if (mounted) Navigator.of(context).pop(coach);
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: UiText('Could not save your coach. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF061522),
    appBar: AppBar(title: const UiText('My Coach')),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const UiText(
            'Choose your coaching style. Change your coach anytime without changing your game or progress.',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 18),
          for (final coach in CoachPersona.values)
            Card(
              key: ValueKey('coach-${coach.name}'),
              clipBehavior: Clip.antiAlias,
              color: const Color(0xFF10283A),
              margin: const EdgeInsets.only(bottom: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: coach == _selected
                      ? const Color(0xFFE1B852)
                      : const Color(0xFF28475A),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AspectRatio(
                    aspectRatio: 1,
                    child: Image.asset(
                      coach.image,
                      fit: BoxFit.cover,
                      semanticLabel: coach.name,
                      cacheWidth: 512,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          coach.name,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        UiText(
                          coach.title,
                          style: const TextStyle(
                            color: Color(0xFF59D9C3),
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 10),
                        UiText(
                          coach.description,
                          style: const TextStyle(fontSize: 16, height: 1.4),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton(
                          onPressed: _saving ? null : () => _listen(coach),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: UiText(
                              _preview == coach
                                  ? 'Loading voice…'
                                  : 'Listen to voice',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        FilledButton(
                          onPressed: _saving ? null : () => _select(coach),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: UiText(
                              _selected == coach
                                  ? 'Selected coach'
                                  : 'Choose this coach',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    ),
  );
}
