import 'package:flutter/material.dart';

import '../app_language.dart';

Future<String?> showAiLanguagePicker(BuildContext context) async {
  final String selected = await AppLanguageController.selectedCode();
  if (!context.mounted) return null;
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF081B2A),
    builder: (BuildContext sheetContext) => SafeArea(
      child: FractionallySizedBox(
        heightFactor: .78,
        child: Column(children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 8, 8),
            child: Row(children: <Widget>[
              const Icon(Icons.translate_rounded, color: Color(0xFF59E4C8)),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('AI Coach language',
                        style: TextStyle(
                            fontSize: 19, fontWeight: FontWeight.w900)),
                    Text('Explanations, hints and lessons use this language.',
                        style:
                            TextStyle(color: Color(0xFFAAB8C4), fontSize: 12)),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(sheetContext),
                icon: const Icon(Icons.close_rounded),
              ),
            ]),
          ),
          const Divider(),
          Expanded(
            child: ListView.builder(
              itemCount: AppLanguageController.supported.length,
              itemBuilder: (BuildContext context, int index) {
                final AppLanguage language =
                    AppLanguageController.supported[index];
                final bool active = language.code == selected;
                return ListTile(
                  leading: Icon(
                    language.code == AppLanguageController.systemCode
                        ? Icons.phone_android_rounded
                        : Icons.translate_rounded,
                    color: active ? const Color(0xFF59E4C8) : null,
                  ),
                  title: Text(language.nativeName),
                  subtitle: language.nativeName == language.englishName
                      ? null
                      : Text(language.englishName),
                  trailing: active
                      ? const Icon(Icons.check_circle_rounded,
                          color: Color(0xFF59E4C8))
                      : null,
                  onTap: () => Navigator.pop(sheetContext, language.code),
                );
              },
            ),
          ),
        ]),
      ),
    ),
  );
}

Future<String?> selectAndSaveAiLanguage(BuildContext context) async {
  final String? selected = await showAiLanguagePicker(context);
  if (selected == null || !context.mounted) return null;
  await AppLanguageController.select(selected);
  if (!context.mounted) return null;
  final AppLanguage language = AppLanguageController.byCode(selected);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(selected == AppLanguageController.systemCode
          ? 'AI Coach now follows your device language.'
          : 'AI Coach will answer in ${language.englishName}.'),
    ),
  );
  return selected;
}

Future<bool> chooseAndSaveAiLanguage(BuildContext context) async {
  return await selectAndSaveAiLanguage(context) != null;
}
