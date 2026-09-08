# Offline coaching localization — 1.2.36+156

All 34 selectable languages have bundled translations for deterministic coaching
and analysis catalogs. No new paid translation API, message-sharing service, or
chat auto-translation has been enabled.

## Integrated surfaces

- Live coach: move feedback, piece purposes, legal moves, progressive hints,
  undo, evaluation, turn status, daily/online status and analysis messages.
- Game review: headlines, summaries, opening metadata, strengths, mistakes,
  training recommendations, move-quality labels, graph data and actions.
- Personal coach: preset questions, evidence-based local answers, known backend
  response templates, comparison labels, feedback, errors and board accessibility.
- Threat, retry-position and mistake-training sub-screens.
- Position Analysis sheet and Analysis dashboard, including deterministic
  weekly insights, daily plans, weakness history and performance metrics.

Locale resolution is shared. Preference loading gates the live coach/dashboard
to avoid an initial English frame. Review responds to nested language changes.
API requests capture their language; superseded responses are discarded.
Switching language after a free-text question retries that question, not a
different preset. Selecting another preset invalidates the earlier request.

## Content contract

Chess notation, FEN, principal variations, scores, counts, usernames and quoted
user input are preserved. Catalog matching retains complete known explanations,
not shortened generic substitutes. Stored English templates are localized when
rendered; stored game records are not rewritten.

Arbitrary prose from an externally configured AI provider, unknown historical
templates and user-authored text are **not** guaranteed offline translation.
Unknown content remains original rather than fabricating a translation. The
existing AI endpoint receives the selected locale. Fully translating arbitrary
prose would require a separate model/service, which this release does not enable.

## Verification

Catalog tests cover all offered locales, nonempty entries, parameter parity,
complete deterministic report fixtures, backend answer branches, and evidence
preservation. Widget tests exercise review at 360px and 1280px, nested threat and
personal-coach dialogs, retry at 360px, Position Analysis and reactive dashboard
selection. Existing analysis-domain tests are retained.

Tests verify behavior and catalog coverage, not professional linguistic review
by native speakers. They do not prove VPS deployment or physical Android device
behavior. Release/build/deployment results must be reported separately after
verification. This work does not claim app-wide translation of unrelated account,
shop, community or billing screens.
