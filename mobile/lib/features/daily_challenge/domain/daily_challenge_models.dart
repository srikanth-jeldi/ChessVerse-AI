enum DailyChallengeUiDifficulty {
  easy,
  medium,
  hard,
}

extension DailyChallengeUiDifficultyDetails on DailyChallengeUiDifficulty {
  String get title {
    switch (this) {
      case DailyChallengeUiDifficulty.easy:
        return 'Easy';
      case DailyChallengeUiDifficulty.medium:
        return 'Medium';
      case DailyChallengeUiDifficulty.hard:
        return 'Hard';
    }
  }

  String get subtitle {
    switch (this) {
      case DailyChallengeUiDifficulty.easy:
        return '3 moves';
      case DailyChallengeUiDifficulty.medium:
        return '4 moves';
      case DailyChallengeUiDifficulty.hard:
        return '5 moves';
    }
  }

  String get description {
    switch (this) {
      case DailyChallengeUiDifficulty.easy:
        return 'Warm-up tactic for quick confidence.';
      case DailyChallengeUiDifficulty.medium:
        return 'Balanced puzzle with forcing moves.';
      case DailyChallengeUiDifficulty.hard:
        return 'Deep calculation for serious players.';
    }
  }

  int get moveGoal {
    switch (this) {
      case DailyChallengeUiDifficulty.easy:
        return 3;
      case DailyChallengeUiDifficulty.medium:
        return 4;
      case DailyChallengeUiDifficulty.hard:
        return 5;
    }
  }
}

class DailyChallengeUiState {
  const DailyChallengeUiState({
    required this.title,
    required this.difficulty,
    required this.streakDays,
    required this.completedToday,
    required this.currentMove,
    required this.bestTimeLabel,
  });

  final String title;
  final DailyChallengeUiDifficulty difficulty;
  final int streakDays;
  final bool completedToday;
  final int currentMove;
  final String bestTimeLabel;

  int get moveGoal => difficulty.moveGoal;

  double get progress {
    if (moveGoal == 0) {
      return 0;
    }
    return (currentMove / moveGoal).clamp(0, 1).toDouble();
  }

  String get progressLabel => '$currentMove/$moveGoal';

  static const DailyChallengeUiState sample = DailyChallengeUiState(
    title: 'Find the forcing line',
    difficulty: DailyChallengeUiDifficulty.medium,
    streakDays: 5,
    completedToday: false,
    currentMove: 2,
    bestTimeLabel: '01:42',
  );
}
