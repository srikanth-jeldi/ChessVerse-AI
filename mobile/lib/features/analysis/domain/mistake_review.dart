class MistakeReview {
  const MistakeReview({required this.nextReview, required this.updatedAt,
    this.attempts = 0, this.successes = 0, this.stage = 0});
  final DateTime nextReview, updatedAt;
  final int attempts, successes, stage;
  static const intervals = [1, 3, 7, 14, 30];
  bool due(DateTime now) => !nextReview.isAfter(now.toUtc());
  MistakeReview record(bool correct, DateTime now) {
    final instant = now.toUtc();
    // An early manual replay never advances the review schedule.
    final advance = correct && due(instant);
    final nextStage = correct ? (advance ? (stage + 1).clamp(1, 5) : stage) : 0;
    return MistakeReview(attempts: attempts + 1, successes: successes + (correct ? 1 : 0),
      stage: nextStage, updatedAt: instant,
      nextReview: correct && !advance ? nextReview : instant.add(Duration(days: correct ? intervals[nextStage - 1] : 1)));
  }
  Map<String, dynamic> toJson() => {'attempts': attempts, 'successes': successes, 'stage': stage,
    'nextReview': nextReview.toUtc().toIso8601String(), 'updatedAt': updatedAt.toUtc().toIso8601String()};
  factory MistakeReview.fromJson(Map<String, dynamic> json) => MistakeReview(
    attempts: (json['attempts'] as num?)?.toInt() ?? 0, successes: (json['successes'] as num?)?.toInt() ?? 0,
    stage: ((json['stage'] as num?)?.toInt() ?? 0).clamp(0, 5),
    nextReview: DateTime.parse(json['nextReview'] as String).toUtc(),
    updatedAt: DateTime.parse(json['updatedAt'] as String).toUtc());
}
