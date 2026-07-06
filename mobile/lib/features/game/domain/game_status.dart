enum GameEndReason { none, checkmate, stalemate, timeout, resignation }

class GameStatus {
  const GameStatus({
    required this.isCheck,
    required this.isGameOver,
    required this.reason,
    this.winnerLabel,
  });

  final bool isCheck;
  final bool isGameOver;
  final GameEndReason reason;
  final String? winnerLabel;

  const GameStatus.playing({bool check = false})
      : isCheck = check,
        isGameOver = false,
        reason = GameEndReason.none,
        winnerLabel = null;

  const GameStatus.ended({required this.reason, this.winnerLabel})
      : isCheck = false,
        isGameOver = true;

  String get title {
    if (!isGameOver) return isCheck ? 'Check!' : 'Game running';
    return switch (reason) {
      GameEndReason.checkmate => 'Checkmate',
      GameEndReason.stalemate => 'Draw',
      GameEndReason.timeout => 'Time out',
      GameEndReason.resignation => 'Resigned',
      GameEndReason.none => 'Game over',
    };
  }

  String get detail {
    if (!isGameOver) {
      return isCheck ? 'Protect the king.' : 'Make your move.';
    }
    return switch (reason) {
      GameEndReason.checkmate => '${winnerLabel ?? 'Player'} wins by checkmate.',
      GameEndReason.stalemate => 'Stalemate. No legal moves and king is not in check.',
      GameEndReason.timeout => '${winnerLabel ?? 'Player'} wins on time.',
      GameEndReason.resignation => '${winnerLabel ?? 'Player'} wins by resignation.',
      GameEndReason.none => 'Game complete.',
    };
  }
}
