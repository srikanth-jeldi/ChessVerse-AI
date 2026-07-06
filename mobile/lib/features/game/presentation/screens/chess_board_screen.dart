import 'package:flutter/material.dart';

import '../../../../core/theme/chessverse_theme.dart';
import '../../application/game_controller.dart';
import '../../domain/chess_piece.dart';
import '../../domain/game_status.dart';
import '../widgets/chess_board_view.dart';
import '../widgets/primary_panel.dart';

class ChessBoardScreen extends StatefulWidget {
  const ChessBoardScreen({required this.mode, required this.difficulty, super.key});

  final ChessGameMode mode;
  final AiDifficulty difficulty;

  @override
  State<ChessBoardScreen> createState() => _ChessBoardScreenState();
}

class _ChessBoardScreenState extends State<ChessBoardScreen> {
  late final GameController _controller = GameController(
    mode: widget.mode,
    difficulty: widget.difficulty,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text(widget.mode == ChessGameMode.ai ? 'Vs ${widget.difficulty.label} AI' : 'Local 2 Player'),
            actions: <Widget>[
              IconButton(
                tooltip: 'Reset game',
                icon: const Icon(Icons.refresh_rounded),
                onPressed: () => _controller.reset(),
              ),
            ],
          ),
          body: SafeArea(
            child: Stack(
              children: <Widget>[
                ListView(
                  padding: const EdgeInsets.all(14),
                  children: <Widget>[
                    _StatusCard(controller: _controller),
                    const SizedBox(height: 12),
                    ChessBoardView(
                      board: _controller.board,
                      selectedSquare: _controller.selectedSquare,
                      legalTargets: _controller.legalTargets,
                      onSquareTap: (String square) => _controller.tapSquare(square),
                    ),
                    const SizedBox(height: 12),
                    _ControlPanel(controller: _controller),
                  ],
                ),
                if (_controller.aiThinking)
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.42)),
                      child: const Center(
                        child: PrimaryPanel(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              CircularProgressIndicator(),
                              SizedBox(height: 14),
                              Text('AI is thinking...', style: TextStyle(fontWeight: FontWeight.w900)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                if (_controller.status.isGameOver)
                  Positioned.fill(
                    child: _ResultOverlay(controller: _controller),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.controller});

  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final bool check = controller.status.isCheck;
    return PrimaryPanel(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: <Widget>[
          CircleAvatar(
            backgroundColor: check ? ChessVerseColors.danger : ChessVerseColors.gold,
            foregroundColor: ChessVerseColors.ink,
            child: Icon(check ? Icons.warning_rounded : Icons.sports_esports_rounded),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Turn: ${controller.turn.label}', style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 3),
                Text(controller.message, style: const TextStyle(color: ChessVerseColors.muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ControlPanel extends StatelessWidget {
  const _ControlPanel({required this.controller});

  final GameController controller;

  @override
  Widget build(BuildContext context) {
    return PrimaryPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(child: _CapturedLine(label: 'White lost', pieces: controller.capturedWhite)),
              const SizedBox(width: 12),
              Expanded(child: _CapturedLine(label: 'Black lost', pieces: controller.capturedBlack)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.flag_rounded),
                  label: const Text('Resign'),
                  onPressed: controller.status.isGameOver ? null : controller.resign,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  icon: const Icon(Icons.replay_rounded),
                  label: const Text('New Game'),
                  onPressed: controller.reset,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('Moves: ${controller.history.length}', style: const TextStyle(color: ChessVerseColors.muted)),
        ],
      ),
    );
  }
}

class _CapturedLine extends StatelessWidget {
  const _CapturedLine({required this.label, required this.pieces});

  final String label;
  final List<ChessPiece> pieces;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: const TextStyle(color: ChessVerseColors.muted, fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          pieces.isEmpty ? '—' : pieces.map((ChessPiece piece) => piece.symbol).join(' '),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 18),
        ),
      ],
    );
  }
}

class _ResultOverlay extends StatelessWidget {
  const _ResultOverlay({required this.controller});

  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final GameStatus status = controller.status;
    return DecoratedBox(
      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.62)),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: PrimaryPanel(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(status.title.toUpperCase(), style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: ChessVerseColors.gold)),
                const SizedBox(height: 10),
                Text(status.detail, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 8),
                Text('Moves: ${controller.history.length}', style: const TextStyle(color: ChessVerseColors.muted)),
                const SizedBox(height: 20),
                FilledButton.icon(
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('New Game'),
                  onPressed: controller.reset,
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  icon: const Icon(Icons.home_rounded),
                  label: const Text('Home'),
                  onPressed: () => Navigator.of(context).popUntil((Route<dynamic> route) => route.isFirst),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
