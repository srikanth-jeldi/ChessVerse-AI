import 'package:flutter/material.dart';

import '../../../core/app_ui_localizations.dart';
import '../domain/mistake_bank.dart';
import '../domain/mistake_weaknesses.dart';

class MistakeWeaknessCard extends StatefulWidget {
  const MistakeWeaknessCard({
    super.key,
    required this.items,
    required this.onPractice,
    this.now,
    this.enabled = true,
  });
  final List<MistakeBankItem> items;
  final ValueChanged<List<MistakeBankItem>> onPractice;
  final DateTime? now;
  final bool enabled;
  @override
  State<MistakeWeaknessCard> createState() => _MistakeWeaknessCardState();
}

class _MistakeWeaknessCardState extends State<MistakeWeaknessCard> {
  int _days = 7;
  @override
  Widget build(BuildContext context) {
    final items = MistakeWeaknesses.recent(
      widget.items,
      days: _days,
      now: widget.now ?? DateTime.now(),
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const UiText(
              'My weaknesses',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final days in [7, 30])
                  ChoiceChip(
                    key: ValueKey('weakness-days-$days'),
                    label: UiText(days == 7 ? 'Last 7 days' : 'Last 30 days'),
                    selected: _days == days,
                    onSelected: (_) => setState(() => _days = days),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            const UiText(
              'Based on saved reviewed positions (up to 100). Tags can overlap; counts are not error rates.',
            ),
            const SizedBox(height: 8),
            if (items.isEmpty)
              const UiText('No reviewed mistakes in this period.'),
            for (final category in MistakeCategory.values)
              _category(category, items),
            const SizedBox(height: 8),
            const UiText(
              'Time pressure means 30 seconds or less on the recorded clock. Missing clocks are not counted. Endgame tags also use the board position.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _category(MistakeCategory category, List<MistakeBankItem> items) {
    final matching = items
        .where((item) => MistakeWeaknesses.tags(item).contains(category))
        .toList();
    final missingClock =
        category == MistakeCategory.timePressure &&
        items.isNotEmpty &&
        items.every((item) => item.review.clockSecondsBefore == null);
    return ExpansionTile(
      key: ValueKey('weakness-${category.name}'),
      tilePadding: EdgeInsets.zero,
      title: UiText(category.label),
      trailing: Text(
        missingClock ? '—' : '${matching.length}',
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LinearProgressIndicator(
              value: items.isEmpty ? 0 : matching.length / items.length,
              minHeight: 7,
              color: const Color(0xFF63D2B8),
            ),
            if (missingClock) const UiText('Clock data unavailable'),
          ],
        ),
      ),
      children: [
        if (matching.isEmpty)
          const Padding(
            padding: EdgeInsets.all(8),
            child: UiText('No matching positions'),
          ),
        if (matching.isNotEmpty) ...[
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: widget.enabled
                  ? () => widget.onPractice(matching)
                  : null,
              child: const UiText('Practise these positions'),
            ),
          ),
          for (final item in matching)
            ListTile(
              title: Text(item.review.playedMove),
              subtitle: Text(
                MaterialLocalizations.of(context)
                    .formatMediumDate(item.game.playedAt.toLocal()),
              ),
              trailing: const Icon(Icons.play_arrow_rounded),
              onTap: widget.enabled ? () => widget.onPractice([item]) : null,
            ),
        ],
      ],
    );
  }
}
