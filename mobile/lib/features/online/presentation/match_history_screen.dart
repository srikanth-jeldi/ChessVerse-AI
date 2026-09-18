import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../main.dart'
    show ChessBoard, ChessPiece, BoardSkin, boardPalettes;

import '../../../core/local_game_archive.dart';
import '../../../core/computer_game_store.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../core/widgets/desktop_app_sidebar.dart';
import '../../auth/data/auth_session_store.dart';
import '../data/online_match_api.dart';
import '../data/pgn_archive_service.dart';
import '../data/fen_archive_service.dart';
import '../data/saved_position_api.dart';
import '../../analysis/domain/ai_review_report.dart';
import '../../analysis/data/game_analysis_api.dart';
import '../../analysis/presentation/adaptive_ai_review.dart';

class MatchHistoryScreen extends StatefulWidget {
  const MatchHistoryScreen({
    super.key,
    this.onResume,
    this.onPlayAgain,
    this.onDestinationSelected,
  });
  final Future<void> Function(ComputerGameDraft)? onResume;
  final Future<void> Function()? onPlayAgain;
  final ValueChanged<int>? onDestinationSelected;

  @override
  State<MatchHistoryScreen> createState() => _MatchHistoryScreenState();
}

class _MatchHistoryScreenState extends State<MatchHistoryScreen> {
  final OnlineMatchApi _api = const OnlineMatchApi();
  static const PgnArchiveService _pgn = PgnArchiveService();
  static const FenArchiveService _fen = FenArchiveService();
  static const SavedPositionApi _positionsApi = SavedPositionApi();
  static const GameAnalysisApi _analysisApi = GameAnalysisApi();
  late Future<List<OnlineMatchDto>> _online = _load();
  List<SavedGameRecord> _cloudGames = [];
  List<OnlineMatchDto> _onlineGames = <OnlineMatchDto>[];
  bool _historySyncFailed = false;
  String _filter = 'All';
  final Set<String> _selectedGameIds = <String>{};
  late Future<List<ComputerGameDraft>> _drafts = _loadDrafts();
  Future<List<ComputerGameDraft>> _loadDrafts() async {
    final owner = await ComputerGameStore.activeOwner();
    if (owner.isEmpty) return [];
    return ComputerGameStore.load(owner);
  }

  Future<List<OnlineMatchDto>> _load() async {
    final StoredAuthSession? session = await const AuthSessionStore().read();
    if (session == null) return const <OnlineMatchDto>[];
    try {
      final drafts = await ComputerGameStore.history(session.token);
      _cloudGames = drafts
          .map(
            (d) => SavedGameRecord(
              mode: 'Play vs AI',
              result: d.state['result'] as String,
              detail: d.state['detail'] as String? ?? '',
              moves: List<String>.from(d.state['moves'] as List).reversed
                  .toList(),
              playedAt: d.updatedAt,
              whitePlayer: d.whiteName,
              blackPlayer: d.blackName,
              playerOutcome: d.state['outcome'] as String?,
              moveReviews: (d.state['reviews'] as List? ?? [])
                  .map(
                    (r) => SavedMoveReview.fromJson(
                      Map<String, dynamic>.from(r as Map),
                    ),
                  )
                  .toList(),
            ),
          )
          .toList();
      _historySyncFailed = false;
    } catch (_) {
      _historySyncFailed = true;
    }
    final List<OnlineMatchDto> history = await _api.history(session.token);
    _onlineGames = history;
    return history;
  }

  Future<void> _refresh() async {
    final Future<List<OnlineMatchDto>> next = _load();
    setState(() {
      _online = next;
      _drafts = _loadDrafts();
    });
    try {
      await next;
    } catch (_) {
      /* FutureBuilder displays the retry state. */
    }
  }

  Future<void> _startNewGame() async {
    await widget.onPlayAgain?.call();
    if (mounted) await _refresh();
  }

  Future<void> _importPgn() async {
    try {
      final picked = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const <String>['pgn'],
      );
      if (picked.isEmpty) return;
      final Uint8List bytes = await picked.single.readAsBytes();
      final String rawPgn = utf8.decode(bytes, allowMalformed: true);
      final List<SavedGameRecord> imported = _pgn.importGames(rawPgn);
      if (!mounted) return;
      final _PgnReviewChoice? choice = await _choosePgnReview(imported.first);
      if (choice == null) return;
      final String selectedName = choice.playerSide == 'white'
          ? imported.first.whitePlayer
          : imported.first.blackPlayer;
      final List<SavedGameRecord> configured = imported
          .map((game) {
            final bool selectedIsWhite =
                game.whitePlayer.trim().toLowerCase() ==
                selectedName.trim().toLowerCase();
            final bool selectedIsBlack =
                game.blackPlayer.trim().toLowerCase() ==
                selectedName.trim().toLowerCase();
            final String side = selectedIsWhite
                ? 'white'
                : selectedIsBlack
                ? 'black'
                : choice.playerSide;
            return SavedGameRecord(
              mode: game.mode,
              result: game.result,
              detail: game.detail,
              moves: game.moves,
              playedAt: game.playedAt,
              whitePlayer: game.whitePlayer,
              blackPlayer: game.blackPlayer,
              playerOutcome: game.playerOutcome,
              playerSide: side,
              reviewScope: choice.reviewScope,
              openingEco: game.openingEco,
              openingName: game.openingName,
              initialFen: game.initialFen,
            );
          })
          .toList(growable: false);
      final Set<String> existing = LocalGameArchive.games
          .map(_gameFingerprint)
          .toSet();
      int added = 0;
      final StoredAuthSession? session = await const AuthSessionStore().read();
      for (final SavedGameRecord game in configured.reversed) {
        if (existing.add(_gameFingerprint(game))) {
          LocalGameArchive.addGame(game);
          added++;
          if (session != null) {
            try {
              final CloudAnalysisJob job = await _analysisApi.create(
                session.token,
                clientRequestId:
                    'pgn-${game.playedAt.microsecondsSinceEpoch}-$added',
                initialFen: game.initialFen!,
                sanMoves: game.moves,
                depth: 16,
                playerColor: game.playerSide?.toUpperCase(),
                sourceFormat: 'PGN',
                sourceSite: game.detail,
                originalPgn: rawPgn,
                whitePlayer: game.whitePlayer,
                blackPlayer: game.blackPlayer,
                gameResult: game.result,
              );
              LocalGameArchive.updateCloudAnalysisForGame(
                playedAt: game.playedAt,
                jobId: job.id,
                status: job.status,
              );
            } on Object {
              // The local import remains safe if cloud analysis is unavailable.
            }
          }
        }
      }
      if (!mounted) return;
      await _refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            added == 0
                ? 'These PGN games are already in My Games.'
                : 'Imported $added game${added == 1 ? '' : 's'}. Open one for AI Review.',
          ),
        ),
      );
    } on Object catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error is FormatException ? error.message : 'PGN import failed. Please choose a valid Chess.com or standard PGN file.',
          ),
        ),
      );
    }
  }

  Future<void> _importFen() async {
    try {
      final picked = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const <String>['fen', 'txt'],
      );
      if (picked.isEmpty) return;
      final bytes = await picked.single.readAsBytes();
      final positions = _fen.importPositions(
        utf8.decode(bytes, allowMalformed: true),
      );
      final existing = LocalGameArchive.games
          .map((game) => game.initialFen)
          .whereType<String>()
          .toSet();
      int added = 0;
      final session = await const AuthSessionStore().read();
      for (final position in positions.reversed) {
        if (!existing.add(position)) continue;
        LocalGameArchive.addGame(
          SavedGameRecord(
            mode: 'Imported FEN',
            result: '*',
            detail:
                'Imported chess position • ${position.split(' ')[1] == 'w' ? 'White' : 'Black'} to move',
            moves: const <String>[],
            playedAt: DateTime.now().toUtc(),
            whitePlayer: 'FEN position',
            blackPlayer: 'Analysis board',
            initialFen: position,
            reviewScope: 'both',
          ),
        );
        if (session != null) {
          try {
            await _positionsApi.save(
              session.token,
              fen: position,
              label: 'Imported FEN position',
              tags: const <String>['imported'],
            );
          } on Object {
            // The durable device copy remains available and can sync later.
          }
        }
        added++;
      }
      if (!mounted) return;
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            added == 0
                ? 'These FEN positions are already in My Games.'
                : 'Imported $added FEN position${added == 1 ? '' : 's'}.',
          ),
        ),
      );
    } on Object catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error is FormatException
                ? error.message
                : 'FEN import failed. Please choose a valid .fen or .txt file.',
          ),
        ),
      );
    }
  }

  Future<_PgnReviewChoice?> _choosePgnReview(SavedGameRecord game) async {
    String side =
        LocalGameArchive.profileUsername?.trim().toLowerCase() ==
            game.blackPlayer.trim().toLowerCase()
        ? 'black'
        : 'white';
    String scope = 'player';
    return showDialog<_PgnReviewChoice>(
      context: context,
      builder: (BuildContext context) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setDialogState) => Dialog(
          backgroundColor: AppColors.backgroundDeep,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 24,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: AppColors.accentGold, width: 1.2),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 620,
              maxHeight: MediaQuery.sizeOf(context).height * .9,
            ),
            child: SingleChildScrollView(
              key: const ValueKey<String>('pgn-review-dialog-scroll'),
              padding: EdgeInsets.all(
                MediaQuery.sizeOf(context).width < 480 ? 20 : 28,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Row(
                    children: <Widget>[
                      Icon(
                        Icons.auto_awesome_rounded,
                        color: Color(0xFF5EEAD4),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Personalise your AI review',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tell ChessVerseAI who you played as and what the coach should analyse.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'WHICH PLAYER ARE YOU?',
                    style: TextStyle(
                      color: AppColors.accentGold,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  LayoutBuilder(
                    builder:
                        (BuildContext context, BoxConstraints constraints) {
                          final Widget whiteTile = _PgnChoiceTile(
                            selected: side == 'white',
                            icon: Icons.light_mode_rounded,
                            title: game.whitePlayer,
                            subtitle: 'White pieces',
                            onTap: () => setDialogState(() => side = 'white'),
                          );
                          final Widget blackTile = _PgnChoiceTile(
                            selected: side == 'black',
                            icon: Icons.dark_mode_rounded,
                            title: game.blackPlayer,
                            subtitle: 'Black pieces',
                            onTap: () => setDialogState(() => side = 'black'),
                          );
                          if (constraints.maxWidth < 430) {
                            return Column(
                              children: <Widget>[
                                whiteTile,
                                const SizedBox(height: 9),
                                blackTile,
                              ],
                            );
                          }
                          return Row(
                            children: <Widget>[
                              Expanded(child: whiteTile),
                              const SizedBox(width: 12),
                              Expanded(child: blackTile),
                            ],
                          );
                        },
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'REVIEW MODE',
                    style: TextStyle(
                      color: AppColors.accentGold,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...<
                        ({
                          String value,
                          IconData icon,
                          String title,
                          String subtitle,
                        })
                      >[
                        (
                          value: 'player',
                          icon: Icons.person_search_rounded,
                          title: 'Review My Moves',
                          subtitle:
                              'My accuracy, mistakes and better alternatives',
                        ),
                        (
                          value: 'opponent',
                          icon: Icons.visibility_rounded,
                          title: 'Review Opponent Moves',
                          subtitle: 'Their best ideas, threats and strategies',
                        ),
                        (
                          value: 'both',
                          icon: Icons.compare_arrows_rounded,
                          title: 'Review Both Players',
                          subtitle: 'A complete move-by-move game analysis',
                        ),
                      ]
                      .map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 9),
                          child: _PgnChoiceTile(
                            selected: scope == item.value,
                            icon: item.icon,
                            title: item.title,
                            subtitle: item.subtitle,
                            recommended: item.value == 'player',
                            onTap: () =>
                                setDialogState(() => scope = item.value),
                          ),
                        ),
                      ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.accentGold,
                        foregroundColor: AppColors.backgroundDeep,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: () => Navigator.pop(
                        context,
                        _PgnReviewChoice(playerSide: side, reviewScope: scope),
                      ),
                      icon: const Icon(Icons.psychology_alt_rounded),
                      label: const Text(
                        'IMPORT & START LEARNING',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _exportPgn() async {
    final List<SavedGameRecord> games = _allSavedGames();
    if (games.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Play or import a game before exporting PGN.'),
        ),
      );
      return;
    }
    final String pgn = _pgn.exportGames(games);
    await FilePicker.saveFile(
      dialogTitle: 'Export ChessVerseAI games',
      fileName: 'chessverseai-games.pgn',
      type: FileType.custom,
      allowedExtensions: const <String>['pgn'],
      bytes: Uint8List.fromList(utf8.encode(pgn)),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Exported ${games.length} game${games.length == 1 ? '' : 's'} as PGN.',
        ),
      ),
    );
  }

  Future<void> _exportFen() async {
    try {
      final fen = _fen.exportPositions(_allSavedGames());
      final count = fen.split('\n').length;
      await FilePicker.saveFile(
        dialogTitle: 'Export ChessVerseAI positions',
        fileName: 'chessverseai-positions.fen',
        type: FileType.custom,
        allowedExtensions: const <String>['fen'],
        bytes: Uint8List.fromList(utf8.encode('$fen\n')),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Exported $count FEN position${count == 1 ? '' : 's'}.',
          ),
        ),
      );
    } on FormatException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  List<SavedGameRecord> _allSavedGames() {
    final Map<String, SavedGameRecord> unique = <String, SavedGameRecord>{};
    for (final SavedGameRecord game in <SavedGameRecord>[
      ...LocalGameArchive.games,
      ..._cloudGames,
      ..._onlineGames.map(_onlineAsSavedGame),
    ]) {
      if (LocalGameArchive.isPuzzleSession(game)) continue;
      unique.putIfAbsent(_gameFingerprint(game), () => game);
    }
    return unique.values.toList(growable: false);
  }

  SavedGameRecord _onlineAsSavedGame(OnlineMatchDto match) => SavedGameRecord(
    mode: 'Online',
    result: match.result ?? '*',
    detail: match.resultReason ?? 'Online arena match',
    moves: match.moves.map((OnlineMoveDto move) => move.uci).toList(),
    playedAt:
        match.finishedAt ??
        match.updatedAt ??
        match.startedAt ??
        DateTime.now(),
    whitePlayer: match.whitePlayerName ?? 'White',
    blackPlayer: match.blackPlayerName ?? 'Black',
    playerSide: match.yourColor.toLowerCase(),
    initialFen: match.fen.trim().isEmpty ? null : match.fen,
  );

  Future<void> _exportSingleGame(SavedGameRecord game, String format) async {
    final String safeName = '${game.whitePlayer}-vs-${game.blackPlayer}'
        .replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '-')
        .toLowerCase();
    try {
      if (format == 'pgn') {
        final String content = _pgn.exportGames(<SavedGameRecord>[game]);
        await FilePicker.saveFile(
          dialogTitle: 'Export this game as PGN',
          fileName: '$safeName.pgn',
          type: FileType.custom,
          allowedExtensions: const <String>['pgn'],
          bytes: Uint8List.fromList(utf8.encode(content)),
        );
      } else {
        final String content = _fen.exportPositions(<SavedGameRecord>[game]);
        await FilePicker.saveFile(
          dialogTitle: 'Export this game as FEN',
          fileName: '$safeName.fen',
          type: FileType.custom,
          allowedExtensions: const <String>['fen'],
          bytes: Uint8List.fromList(utf8.encode('$content\n')),
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Game exported as ${format.toUpperCase()}.')),
      );
    } on FormatException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  Future<void> _showGameActions(
    SavedGameRecord game, {
    bool allowDelete = true,
  }) async {
    final String? action = await showDialog<String>(
      context: context,
      barrierColor: const Color(0xD9000812),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 540),
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppColors.accentGold),
            gradient: const LinearGradient(
              colors: <Color>[Color(0xFF09223B), Color(0xFF040D19)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: const <BoxShadow>[
              BoxShadow(color: Color(0x6645B8FF), blurRadius: 30),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ),
                const Icon(
                  Icons.workspace_premium_rounded,
                  color: Color(0xFFFFD978),
                  size: 44,
                ),
                const SizedBox(height: 8),
                Text(
                  game.summary,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFFFFD978),
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Choose how you want to keep or share this game.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 18),
                _PremiumGameAction(
                  icon: Icons.description_outlined,
                  title: 'EXPORT PGN',
                  subtitle: 'Complete game, players, result and move history',
                  onTap: () => Navigator.pop(context, 'pgn'),
                ),
                const SizedBox(height: 10),
                _PremiumGameAction(
                  icon: Icons.grid_on_rounded,
                  title: 'EXPORT FEN',
                  subtitle: 'Exact saved and engine-reviewed positions',
                  onTap: () => Navigator.pop(context, 'fen'),
                ),
                const SizedBox(height: 10),
                _PremiumGameAction(
                  icon: Icons.library_add_check_rounded,
                  title: 'SELECT MULTIPLE GAMES',
                  subtitle: 'Choose several games and export separate files',
                  onTap: () => Navigator.pop(context, 'select'),
                ),
                if (allowDelete) ...<Widget>[
                  const SizedBox(height: 10),
                  _PremiumGameAction(
                    icon: Icons.delete_outline_rounded,
                    title: 'DELETE GAME',
                    subtitle: 'Remove this game from My Games',
                    danger: true,
                    onTap: () => Navigator.pop(context, 'delete'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
    if (!mounted || action == null) return;
    if (action == 'select') {
      _toggleGameSelection(game);
    } else if (action == 'delete') {
      await _deleteGame(game);
    } else {
      await _exportSingleGame(game, action);
    }
  }

  void _toggleGameSelection(SavedGameRecord game) {
    final String id = _gameFingerprint(game);
    setState(() {
      if (!_selectedGameIds.add(id)) _selectedGameIds.remove(id);
    });
  }

  Future<void> _exportSelectedGames(
    List<SavedGameRecord> games,
    String format,
  ) async {
    final List<SavedGameRecord> selected = games
        .where((game) => _selectedGameIds.contains(_gameFingerprint(game)))
        .toList(growable: false);
    for (final SavedGameRecord game in selected) {
      if (!mounted) return;
      await _exportSingleGame(game, format);
    }
    if (!mounted) return;
    setState(_selectedGameIds.clear);
  }

  Future<void> _chooseImportFormat() async {
    final format = await _chooseArchiveFormat(importing: true);
    if (format == 'pgn') await _importPgn();
    if (format == 'fen') await _importFen();
  }

  Future<void> _chooseExportFormat() async {
    final format = await _chooseArchiveFormat(importing: false);
    if (format == 'pgn') await _exportPgn();
    if (format == 'fen') await _exportFen();
  }

  Future<String?> _chooseArchiveFormat({
    required bool importing,
  }) => showDialog<String>(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: AppColors.backgroundDeep,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: AppColors.accentGold),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: const EdgeInsets.all(26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                '${importing ? 'IMPORT' : 'EXPORT'} CHESS DATA',
                style: const TextStyle(
                  color: AppColors.accentGold,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                importing
                    ? 'Choose whether you are bringing in a complete game or one exact position.'
                    : 'Choose the format you want to keep or share.',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),
              _ArchiveFormatTile(
                icon: Icons.history_rounded,
                title: 'PGN • COMPLETE GAMES',
                subtitle: importing
                    ? 'Import move history from Chess.com or another chess app'
                    : 'Export all saved games with players, result and moves',
                onTap: () => Navigator.pop(context, 'pgn'),
              ),
              const SizedBox(height: 12),
              _ArchiveFormatTile(
                icon: Icons.grid_on_rounded,
                title: 'FEN • BOARD POSITIONS',
                subtitle: importing
                    ? 'Import an exact board setup, side to move and castling rights'
                    : 'Export imported and engine-reviewed positions',
                onTap: () => Navigator.pop(context, 'fen'),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  String _gameFingerprint(SavedGameRecord game) =>
      '${game.whitePlayer.trim().toLowerCase()}|${game.blackPlayer.trim().toLowerCase()}|${game.result}|${game.moves.join(' ')}|${game.initialFen ?? ''}';

  Future<bool> _confirmDelete({
    required String title,
    required String body,
  }) async =>
      await showDialog<bool>(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          backgroundColor: AppColors.backgroundDeep,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: const BorderSide(color: AppColors.accentGold),
          ),
          icon: const Icon(
            Icons.delete_outline_rounded,
            color: AppColors.accentGold,
            size: 34,
          ),
          title: Text(title, textAlign: TextAlign.center),
          content: Text(
            body,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: <Widget>[
            OutlinedButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('KEEP IT'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('DELETE'),
            ),
          ],
        ),
      ) ??
      false;

  Future<void> _deleteGame(SavedGameRecord game) async {
    final bool confirmed = await _confirmDelete(
      title: game.mode.startsWith('Imported ')
          ? 'Delete imported ${game.mode.substring(9)}?'
          : 'Delete saved game?',
      body:
          '${game.summary} will be removed from this device. This cannot be undone.',
    );
    if (!confirmed || !mounted) return;
    LocalGameArchive.removeGame(game);
    setState(() {});
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Game deleted.')));
  }

  Future<void> _deleteAllImported() async {
    final int count = LocalGameArchive.games
        .where((game) => game.mode.startsWith('Imported '))
        .length;
    if (count == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No imported PGN games to delete.')),
      );
      return;
    }
    final bool confirmed = await _confirmDelete(
      title: 'Delete all imported chess data?',
      body:
          'All $count imported game${count == 1 ? '' : 's'} will be removed. Your ChessVerseAI games stay safe.',
    );
    if (!confirmed || !mounted) return;
    final int removed = LocalGameArchive.removeImportedGames();
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Deleted $removed imported PGN game${removed == 1 ? '' : 's'}.',
        ),
      ),
    );
  }

  void _openCompleted(SavedGameRecord game) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text('Saved game')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(game.summary, style: Theme.of(context).textTheme.titleLarge),
              Text('${game.result} · ${_formatDate(game.playedAt)}'),
              Text(game.detail),
              if (game.playerSide != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Chip(
                    avatar: const Icon(Icons.auto_awesome_rounded, size: 18),
                    label: Text(
                      'You played ${game.playerSide == 'white' ? game.whitePlayer : game.blackPlayer} • ${game.reviewScope == 'player'
                          ? 'Reviewing your moves'
                          : game.reviewScope == 'opponent'
                          ? 'Reviewing opponent moves'
                          : 'Reviewing both players'}',
                    ),
                  ),
                ),
              if (game.initialFen != null) ...<Widget>[
                const SizedBox(height: 12),
                const Text(
                  'FEN POSITION',
                  style: TextStyle(
                    color: AppColors.accentGold,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                SelectableText(
                  game.initialFen!,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
              if (game.moves.isNotEmpty)
                Wrap(
                  spacing: 8,
                  children: [
                    FilledButton(
                      onPressed: () => showAdaptiveAiReview(
                        context,
                        report: AiReviewReport.fromMoves(
                          game.moves,
                          newestFirst: false,
                          result: game.result,
                          knownReviews: game.moveReviews,
                          playerSide: game.playerSide,
                          reviewScope: game.reviewScope,
                        ),
                      ),
                      child: const Text('AI Review'),
                    ),
                    if (game.mode == 'Play vs AI')
                      TextButton(
                        onPressed: widget.onPlayAgain == null
                            ? null
                            : _startNewGame,
                        child: const Text('Play Again'),
                      ),
                  ],
                ),
              if (game.moves.isNotEmpty) ...<Widget>[
                const Text('Moves'),
                ...game.moves.indexed.map(
                  (m) =>
                      ListTile(leading: Text('${m.$1 + 1}'), title: Text(m.$2)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
    if (mounted) await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final navigate = widget.onDestinationSelected;
    if (navigate == null || size.width < 700 || size.height < 600) {
      return _buildPage();
    }
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Row(
        children: [
          DesktopAppSidebar(
            selected: 'My Games',
            onHome: () => navigate(0),
            onPlay: () => navigate(1),
            onMyGames: () {},
            onPuzzles: () => navigate(2),
            onLearn: () => navigate(3),
            onProfile: () => navigate(4),
            onFriends: () => navigate(5),
          ),
          Expanded(child: _buildPage(showBackButton: false)),
        ],
      ),
    );
  }

  Widget _buildPage({bool showBackButton = true}) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        automaticallyImplyLeading: showBackButton,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('MY GAMES', style: TextStyle(fontWeight: FontWeight.w900)),
            Text(
              'Review. Learn. Get Better.',
              style: TextStyle(color: Color(0xFFAFC2D1), fontSize: 11),
            ),
          ],
        ),
        backgroundColor: const Color(0xD9071827),
        actions: <Widget>[
          IconButton(
            key: const ValueKey<String>('import-pgn'),
            tooltip: 'Import PGN game or FEN position',
            onPressed: _chooseImportFormat,
            icon: const Icon(Icons.upload_file_rounded),
          ),
          IconButton(
            key: const ValueKey<String>('export-pgn'),
            tooltip: 'Export as PGN or FEN',
            onPressed: _chooseExportFormat,
            icon: const Icon(Icons.download_rounded),
          ),
          PopupMenuButton<String>(
            tooltip: 'Manage saved games',
            onSelected: (String value) {
              if (value == 'delete-imported') _deleteAllImported();
            },
            itemBuilder: (_) => const <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'delete-imported',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    Icons.delete_sweep_rounded,
                    color: AppColors.danger,
                  ),
                  title: Text('Delete imported PGNs'),
                ),
              ),
            ],
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.35,
            colors: <Color>[Color(0xFF0B3151), Color(0xFF04111E)],
          ),
        ),
        child: Column(
          children: [
            FutureBuilder<List<ComputerGameDraft>>(
              future: _drafts,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return ListTile(
                    title: const Text('Saved game could not sync'),
                    trailing: IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: _refresh,
                    ),
                  );
                }
                if (!snapshot.hasData) return const LinearProgressIndicator();
                if (snapshot.data!.isEmpty) {
                  return ListTile(
                    title: const Text('No paused computer game'),
                    trailing: TextButton(
                      onPressed: widget.onPlayAgain == null
                          ? null
                          : _startNewGame,
                      child: const Text('New Game'),
                    ),
                  );
                }
                final draft = snapshot.data!.first;
                return ListTile(
                  title: const Text('Continue computer game'),
                  subtitle: Text(
                    '${draft.whiteName} vs ${draft.blackName} · ${draft.plyCount} half-moves · Level ${draft.level.toInt()}',
                  ),
                  trailing: FilledButton(
                    onPressed: widget.onResume == null
                        ? null
                        : () async {
                            await widget.onResume!(draft);
                            if (mounted) await _refresh();
                          },
                    child: const Text('Continue'),
                  ),
                );
              },
            ),
            _PgnCoachBanner(
              onImport: _chooseImportFormat,
              onExport: _chooseExportFormat,
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refresh,
                child: FutureBuilder<List<OnlineMatchDto>>(
                  future: _online,
                  builder:
                      (
                        BuildContext context,
                        AsyncSnapshot<List<OnlineMatchDto>> snapshot,
                      ) {
                        final List<OnlineMatchDto> online =
                            snapshot.data ?? const <OnlineMatchDto>[];
                        final Map<String, SavedGameRecord> uniqueLocal =
                            <String, SavedGameRecord>{};
                        for (final SavedGameRecord game in <SavedGameRecord>[
                          ...LocalGameArchive.games,
                          ..._cloudGames,
                        ]) {
                          uniqueLocal.putIfAbsent(
                            _gameFingerprint(game),
                            () => game,
                          );
                        }
                        final List<SavedGameRecord> local =
                            uniqueLocal.values.toList()..sort(
                              (a, b) => b.playedAt.compareTo(a.playedAt),
                            );
                        final List<SavedGameRecord> exportableGames =
                            <SavedGameRecord>[
                              ...local,
                              ...online.map(_onlineAsSavedGame),
                            ];
                        if (snapshot.connectionState ==
                                ConnectionState.waiting &&
                            online.isEmpty &&
                            local.isEmpty) {
                          return const SkeletonPage(rows: 5);
                        }
                        if (snapshot.hasError &&
                            online.isEmpty &&
                            local.isEmpty) {
                          return _HistoryMessage(
                            icon: Icons.cloud_off_rounded,
                            message: 'Match history could not be loaded. Pull to retry.',
                            detail: '${snapshot.error}',
                          );
                        }
                        if (online.isEmpty && local.isEmpty) {
                          return const _HistoryMessage(
                            icon: Icons.history_rounded,
                            message: 'Your completed matches will appear here.',
                          );
                        }
                        return ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                          children: <Widget>[
                            if (_historySyncFailed || snapshot.hasError)
                              const Text(
                                'Some account history could not sync. Pull to retry.',
                              ),
                            Builder(
                              builder: (_) {
                                final outcomes = [
                                  ...local
                                      .where(
                                        (g) =>
                                            g.mode == 'Play vs AI' ||
                                            g.mode == '2 Players',
                                      )
                                      .map((g) => g.playerOutcome),
                                  ...online
                                      .where(
                                        (g) => [
                                          '1-0',
                                          '0-1',
                                          '1/2-1/2',
                                        ].contains(g.result),
                                      )
                                      .map(
                                        (g) => _MatchPresentation(g).draw
                                            ? 'draw'
                                            : _MatchPresentation(g).won
                                            ? 'win'
                                            : 'loss',
                                      ),
                                ];
                                final wins = outcomes
                                    .where((o) => o == 'win')
                                    .length;
                                final losses = outcomes
                                    .where((o) => o == 'loss')
                                    .length;
                                final draws = outcomes
                                    .where((o) => o == 'draw')
                                    .length;
                                final total = wins + losses + draws;
                                final gamesPlayed = outcomes.length;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Text(
                                    'Recorded matches: $gamesPlayed games · $wins wins · $losses losses · $draws draws · ${total == 0 ? 0 : (wins * 100 / total).round()}% wins',
                                  ),
                                );
                              },
                            ),
                            Wrap(
                              spacing: 6,
                              children:
                                  [
                                        'All',
                                        'Computer',
                                        'Local',
                                        'Imported',
                                        'Online',
                                      ]
                                      .map(
                                        (f) => ChoiceChip(
                                          label: Text(f),
                                          selected: _filter == f,
                                          onSelected: (_) =>
                                              setState(() => _filter = f),
                                        ),
                                      )
                                      .toList(),
                            ),
                            if (_selectedGameIds.isNotEmpty) ...<Widget>[
                              const SizedBox(height: 12),
                              _MultiSelectToolbar(
                                count: _selectedGameIds.length,
                                onCancel: () =>
                                    setState(_selectedGameIds.clear),
                                onExportPgn: () => _exportSelectedGames(
                                  exportableGames,
                                  'pgn',
                                ),
                                onExportFen: () => _exportSelectedGames(
                                  exportableGames,
                                  'fen',
                                ),
                              ),
                            ],
                            const SizedBox(height: 12),
                            if (online.isNotEmpty &&
                                (_filter == 'All' ||
                                    _filter == 'Online')) ...<Widget>[
                              const _Heading('ONLINE ARENA'),
                              const SizedBox(height: 4),
                              const Text(
                                'Tap a completed game to replay every move.',
                                style: TextStyle(
                                  color: Color(0xFF8FA5B1),
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 10),
                              ...online.map((OnlineMatchDto match) {
                                final SavedGameRecord game = _onlineAsSavedGame(
                                  match,
                                );
                                return _OnlineHistoryCard(
                                  match,
                                  selected: _selectedGameIds.contains(
                                    _gameFingerprint(game),
                                  ),
                                  selectionMode: _selectedGameIds.isNotEmpty,
                                  onTap: () => _selectedGameIds.isNotEmpty
                                      ? _toggleGameSelection(game)
                                      : Navigator.of(context).push<void>(
                                          MaterialPageRoute<void>(
                                            builder: (_) =>
                                                OnlineMatchReplayScreen(
                                                  match: match,
                                                ),
                                          ),
                                        ),
                                  onExport: () => _showGameActions(
                                    game,
                                    allowDelete: false,
                                  ),
                                );
                              }),
                              const SizedBox(height: 20),
                            ],
                            if (local.isNotEmpty &&
                                _filter != 'Online') ...<Widget>[
                              const _Heading('SAVED GAMES'),
                              const SizedBox(height: 10),
                              ...local
                                  .where(
                                    (g) =>
                                        _filter == 'All' ||
                                        (_filter == 'Computer'
                                            ? g.mode == 'Play vs AI'
                                            : _filter == 'Imported'
                                            ? g.mode.startsWith('Imported ')
                                            : g.mode == '2 Players'),
                                  )
                                  .map(
                                    (g) => _LocalHistoryCard(
                                      g,
                                      selected: _selectedGameIds.contains(
                                        _gameFingerprint(g),
                                      ),
                                      selectionMode:
                                          _selectedGameIds.isNotEmpty,
                                      onTap: () => _selectedGameIds.isNotEmpty
                                          ? _toggleGameSelection(g)
                                          : _openCompleted(g),
                                      onLongPress: () => _showGameActions(g),
                                      onActions: () => _showGameActions(g),
                                    ),
                                  ),
                            ],
                          ],
                        );
                      },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PgnReviewChoice {
  const _PgnReviewChoice({required this.playerSide, required this.reviewScope});
  final String playerSide;
  final String reviewScope;
}

class _ArchiveFormatTile extends StatelessWidget {
  const _ArchiveFormatTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(16),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0x8059E4C8)),
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0x2414B8A6),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: const Color(0xFF5EEAD4)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.accentGold,
            ),
          ],
        ),
      ),
    ),
  );
}

class _PgnChoiceTile extends StatelessWidget {
  const _PgnChoiceTile({
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.recommended = false,
  });
  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool recommended;

  @override
  Widget build(BuildContext context) => Material(
    color: selected ? const Color(0xFF123C3E) : AppColors.surface,
    borderRadius: BorderRadius.circular(14),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? const Color(0xFF5EEAD4) : AppColors.border,
            width: selected ? 1.7 : 1,
          ),
        ),
        child: Row(
          children: <Widget>[
            Icon(
              icon,
              color: selected
                  ? const Color(0xFF5EEAD4)
                  : AppColors.textSecondary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      if (recommended)
                        const Text(
                          'BEST',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.accentGold,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle_rounded, color: Color(0xFF5EEAD4)),
          ],
        ),
      ),
    ),
  );
}

class _PgnCoachBanner extends StatelessWidget {
  const _PgnCoachBanner({required this.onImport, required this.onExport});
  final VoidCallback onImport;
  final VoidCallback onExport;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.fromLTRB(16, 6, 16, 4),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0x8059E4C8)),
      gradient: const LinearGradient(
        colors: <Color>[Color(0xFF10374A), Color(0xFF091D31)],
      ),
    ),
    child: Stack(
      children: <Widget>[
        Positioned(
          right: 72,
          top: -24,
          bottom: -24,
          child: Opacity(
            opacity: .35,
            child: Image.asset(
              'assets/pieces/premium_individual/sapphire-elite/black/king.webp',
              width: 110,
              fit: BoxFit.contain,
            ),
          ),
        ),
        Row(
          children: <Widget>[
            const Icon(
              Icons.auto_awesome_rounded,
              color: Color(0xFF59E4C8),
              size: 30,
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'PLAY ANYWHERE. IMPROVE HERE.',
                    style: TextStyle(
                      color: Color(0xFFF1C45A),
                      fontWeight: FontWeight.w900,
                      letterSpacing: .8,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Import or export complete PGN games and exact FEN positions.',
                    style: TextStyle(color: Color(0xFFB8CAD5), fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              tooltip: 'Import PGN or FEN',
              onPressed: onImport,
              icon: const Icon(Icons.upload_file_rounded),
            ),
            IconButton(
              tooltip: 'Export PGN or FEN',
              onPressed: onExport,
              icon: const Icon(Icons.download_rounded),
            ),
          ],
        ),
      ],
    ),
  );
}

class _PremiumGameAction extends StatelessWidget {
  const _PremiumGameAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.danger = false,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0xB70A2038),
    borderRadius: BorderRadius.circular(16),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: danger ? const Color(0x99FF5263) : const Color(0xAA35BFFF),
          ),
        ),
        child: Row(
          children: <Widget>[
            Icon(
              icon,
              color: danger ? const Color(0xFFFF7180) : const Color(0xFF63E3C4),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: TextStyle(
                      color: danger
                          ? const Color(0xFFFF7180)
                          : const Color(0xFFFFD978),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFFFFD978)),
          ],
        ),
      ),
    ),
  );
}

class _MultiSelectToolbar extends StatelessWidget {
  const _MultiSelectToolbar({
    required this.count,
    required this.onCancel,
    required this.onExportPgn,
    required this.onExportFen,
  });
  final int count;
  final VoidCallback onCancel;
  final VoidCallback onExportPgn;
  final VoidCallback onExportFen;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFFFD15C)),
      gradient: const LinearGradient(
        colors: <Color>[Color(0xFF14304A), Color(0xFF07192C)],
      ),
      boxShadow: const <BoxShadow>[
        BoxShadow(color: Color(0x44EABF61), blurRadius: 18),
      ],
    ),
    child: Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Text(
            '$count SELECTED',
            style: const TextStyle(
              color: Color(0xFFFFD978),
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        OutlinedButton.icon(
          onPressed: onExportPgn,
          icon: const Icon(Icons.description_outlined),
          label: const Text('PGN FILES'),
        ),
        OutlinedButton.icon(
          onPressed: onExportFen,
          icon: const Icon(Icons.grid_on_rounded),
          label: const Text('FEN FILES'),
        ),
        IconButton(
          tooltip: 'Cancel selection',
          onPressed: onCancel,
          icon: const Icon(Icons.close_rounded),
        ),
      ],
    ),
  );
}

class _HistoryMessage extends StatelessWidget {
  const _HistoryMessage({
    required this.icon,
    required this.message,
    this.detail,
  });
  final IconData icon;
  final String message;
  final String? detail;

  @override
  Widget build(BuildContext context) => ListView(
    physics: const AlwaysScrollableScrollPhysics(),
    children: <Widget>[
      const SizedBox(height: 180),
      Icon(icon, size: 58, color: const Color(0xFF607A87)),
      const SizedBox(height: 14),
      Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFF9CB0BA)),
        ),
      ),
      if (detail != null) ...<Widget>[
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            detail!,
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xFF607A87), fontSize: 11),
          ),
        ),
      ],
    ],
  );
}

class _Heading extends StatelessWidget {
  const _Heading(this.label);
  final String label;
  @override
  Widget build(BuildContext context) => Text(
    label,
    style: const TextStyle(
      color: AppColors.accentGold,
      letterSpacing: 1.2,
      fontWeight: FontWeight.w900,
    ),
  );
}

class _OnlineHistoryCard extends StatelessWidget {
  const _OnlineHistoryCard(
    this.match, {
    required this.onTap,
    required this.onExport,
    required this.selected,
    required this.selectionMode,
  });
  final OnlineMatchDto match;
  final VoidCallback onTap;
  final VoidCallback onExport;
  final bool selected;
  final bool selectionMode;

  @override
  Widget build(BuildContext context) {
    final _MatchPresentation presentation = _MatchPresentation(match);
    return _HistoryShell(
      accent: selected ? const Color(0xFFFFD15C) : presentation.accent,
      onTap: onTap,
      child: Row(
        children: <Widget>[
          if (selectionMode)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: selected
                    ? const Color(0xFFFFD15C)
                    : const Color(0xFF6D879E),
              ),
            ),
          _PlayerAvatar(
            name: presentation.opponent,
            photoUrl: presentation.opponentPhotoUrl,
            color: presentation.accent,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  presentation.outcome,
                  style: TextStyle(
                    color: presentation.accent,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  'vs ${presentation.opponent}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 3),
                Text(
                  '${presentation.reason}  •  ${match.moves.length} ply  •  ${_formatDuration(match.durationSeconds)}',
                  style: const TextStyle(
                    color: Color(0xFF8FA5B1),
                    fontSize: 11,
                  ),
                ),
                if (match.finishedAt != null)
                  Text(
                    _formatDate(match.finishedAt!),
                    style: const TextStyle(
                      color: Color(0xFF607A87),
                      fontSize: 10,
                    ),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                match.result ?? '—',
                style: TextStyle(
                  color: presentation.accent,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (presentation.ratingDelta != null)
                Text(
                  '${presentation.ratingDelta! >= 0 ? '+' : ''}${presentation.ratingDelta}',
                  style: const TextStyle(fontSize: 11),
                ),
              if (!selectionMode)
                IconButton(
                  tooltip: 'Export PGN or FEN',
                  onPressed: onExport,
                  icon: const Icon(Icons.more_horiz_rounded),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LocalHistoryCard extends StatelessWidget {
  const _LocalHistoryCard(
    this.game, {
    required this.onTap,
    required this.onLongPress,
    required this.onActions,
    required this.selected,
    required this.selectionMode,
  });
  final SavedGameRecord game;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onActions;
  final bool selected;
  final bool selectionMode;
  @override
  Widget build(BuildContext context) => _HistoryShell(
    accent: selected ? const Color(0xFFFFD15C) : const Color(0xFF49DDBB),
    onTap: onTap,
    onLongPress: onLongPress,
    child: Row(
      children: <Widget>[
        if (selectionMode)
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Icon(
              selected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: selected
                  ? const Color(0xFFFFD15C)
                  : const Color(0xFF6D879E),
            ),
          )
        else
          const Padding(
            padding: EdgeInsets.only(right: 12),
            child: Icon(Icons.emoji_events_rounded, color: Color(0xFF63D2B8)),
          ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                game.summary,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              Text(
                '${game.mode} • ${game.moves.length} ply • ${_formatDate(game.playedAt)}',
                style: const TextStyle(color: Color(0xFF8FA5B1), fontSize: 11),
              ),
            ],
          ),
        ),
        Text(game.result, style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(width: 8),
        if (!selectionMode)
          IconButton(
            key: ValueKey<String>(
              'game-actions-${game.playedAt.toIso8601String()}',
            ),
            tooltip: 'Export or manage game',
            onPressed: onActions,
            icon: const Icon(Icons.more_horiz_rounded),
          ),
      ],
    ),
  );
}

class _HistoryShell extends StatelessWidget {
  const _HistoryShell({
    required this.accent,
    required this.child,
    this.onTap,
    this.onLongPress,
  });
  final Color accent;
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: <Color>[Color(0xF20B263B), Color(0xF2071728)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: accent.withValues(alpha: 0.78), width: 1.25),
      boxShadow: <BoxShadow>[
        BoxShadow(
          color: accent.withValues(alpha: .18),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(padding: const EdgeInsets.all(14), child: child),
      ),
    ),
  );
}

class OnlineMatchReplayScreen extends StatefulWidget {
  const OnlineMatchReplayScreen({required this.match, super.key});
  final OnlineMatchDto match;

  @override
  State<OnlineMatchReplayScreen> createState() =>
      _OnlineMatchReplayScreenState();
}

class _OnlineMatchReplayScreenState extends State<OnlineMatchReplayScreen> {
  late final List<Map<String, String>> _positions =
      _ReplayPositionBuilder.build(widget.match.moves);
  int _ply = 0;

  @override
  Widget build(BuildContext context) {
    final OnlineMatchDto match = widget.match;
    final _MatchPresentation presentation = _MatchPresentation(match);
    final bool flipped = match.yourColor.toLowerCase() == 'black';
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('GAME REPLAY'),
        backgroundColor: const Color(0xD9071827),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final double boardSize = constraints.maxWidth
                .clamp(280.0, 620.0)
                .toDouble();
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              children: <Widget>[
                _ReplayPlayers(match: match, presentation: presentation),
                const SizedBox(height: 14),
                Center(
                  child: SizedBox.square(
                    dimension: boardSize - 32,
                    child: _ReplayBoard(
                      pieces: _positions[_ply],
                      flipped: flipped,
                      lastMove: _ply == 0 ? null : match.moves[_ply - 1].uci,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  _ply == 0
                      ? 'Starting position'
                      : 'Move $_ply of ${match.moves.length}: ${match.moves[_ply - 1].uci}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                Slider(
                  key: const ValueKey<String>('game-replay-slider'),
                  value: _ply.toDouble(),
                  max: match.moves.length.toDouble().clamp(1, double.infinity),
                  divisions: match.moves.isEmpty ? null : match.moves.length,
                  label: '$_ply',
                  onChanged: match.moves.isEmpty
                      ? null
                      : (double value) => setState(
                          () =>
                              _ply = value.round().clamp(0, match.moves.length),
                        ),
                ),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _ply == 0
                            ? null
                            : () => setState(() => _ply--),
                        icon: const Icon(Icons.skip_previous_rounded),
                        label: const Text('Previous'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _ply == match.moves.length
                            ? null
                            : () => setState(() => _ply++),
                        icon: const Icon(Icons.skip_next_rounded),
                        label: const Text('Next'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: List<Widget>.generate(match.moves.length, (int i) {
                    final bool active = _ply == i + 1;
                    return ActionChip(
                      backgroundColor: active
                          ? AppColors.accentGold
                          : const Color(0xFF102435),
                      label: Text('${i + 1}. ${match.moves[i].uci}'),
                      onPressed: () => setState(() => _ply = i + 1),
                    );
                  }),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ReplayPlayers extends StatelessWidget {
  const _ReplayPlayers({required this.match, required this.presentation});
  final OnlineMatchDto match;

  final _MatchPresentation presentation;
  @override
  Widget build(BuildContext context) => _HistoryShell(
    accent: presentation.accent,
    child: Column(
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Expanded(child: Text('You • ${match.yourColor}')),
            Text(
              presentation.outcome,
              style: TextStyle(
                color: presentation.accent,
                fontWeight: FontWeight.w900,
              ),
            ),
            Expanded(
              child: Text(
                presentation.opponent,
                textAlign: TextAlign.right,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          '${presentation.reason} • ${_formatDuration(match.durationSeconds)} • ${match.result ?? '—'}',
          style: const TextStyle(color: Color(0xFF8FA5B1), fontSize: 12),
        ),
      ],
    ),
  );
}

class _ReplayBoard extends StatelessWidget {
  const _ReplayBoard({
    required this.pieces,
    required this.flipped,
    this.lastMove,
  });
  final Map<String, String> pieces;
  final bool flipped;
  final String? lastMove;
  @override
  Widget build(BuildContext context) {
    final board = pieces.map(
      (square, code) => MapEntry(
        square,
        ChessPiece(code.toUpperCase(), code == code.toUpperCase()),
      ),
    );
    final from = lastMove?.substring(0, 2);
    final to = lastMove?.substring(2, 4);
    return ChessBoard(
      pieces: board,
      selectedSquare: null,
      legalTargets: const {},
      lastFromSquare: from,
      lastToSquare: to,
      lastCaptureSquare: null,
      lastMovedPiece: to == null ? null : board[to],
      moveSequence: lastMove?.hashCode ?? 0,
      checkedKingSquare: null,
      decisiveSquare: null,
      coachArrowFrom: from,
      coachArrowTo: to,
      flipped: flipped,
      showCoordinates: true,
      palette: boardPalettes[BoardSkin.royalWalnut]!,
      onSquareTap: (_) {},
    );
  }
}

class _ReplayPositionBuilder {
  static List<Map<String, String>> build(List<OnlineMoveDto> moves) {
    final Map<String, String> board = _initialBoard();
    final List<Map<String, String>> result = <Map<String, String>>[
      Map<String, String>.from(board),
    ];
    for (final OnlineMoveDto move in moves) {
      final String uci = move.uci.toLowerCase();
      if (uci.length < 4) {
        result.add(Map<String, String>.from(board));
        continue;
      }
      final String from = uci.substring(0, 2);
      final String to = uci.substring(2, 4);
      String? piece = board.remove(from);
      if (piece == null) {
        result.add(Map<String, String>.from(board));
        continue;
      }
      final bool targetWasEmpty = !board.containsKey(to);
      if (piece.toLowerCase() == 'p' && from[0] != to[0] && targetWasEmpty) {
        board.remove('${to[0]}${from[1]}');
      }
      board.remove(to);
      if (piece.toLowerCase() == 'k' &&
          (from.codeUnitAt(0) - to.codeUnitAt(0)).abs() == 2) {
        final bool kingSide = to.startsWith('g');
        final String rookFrom = '${kingSide ? 'h' : 'a'}${from[1]}';
        final String rookTo = '${kingSide ? 'f' : 'd'}${from[1]}';
        final String? rook = board.remove(rookFrom);
        if (rook != null) board[rookTo] = rook;
      }
      if (uci.length >= 5) {
        piece = piece == piece.toUpperCase()
            ? uci[4].toUpperCase()
            : uci[4].toLowerCase();
      }
      board[to] = piece;
      result.add(Map<String, String>.from(board));
    }
    return result;
  }

  static Map<String, String> _initialBoard() {
    const String files = 'abcdefgh';
    const String back = 'rnbqkbnr';
    final Map<String, String> board = <String, String>{};
    for (int i = 0; i < 8; i++) {
      board['${files[i]}1'] = back[i].toUpperCase();
      board['${files[i]}2'] = 'P';
      board['${files[i]}7'] = 'p';
      board['${files[i]}8'] = back[i];
    }
    return board;
  }
}

class _MatchPresentation {
  _MatchPresentation(this.match)
    : white = match.yourColor.toLowerCase() == 'white' {
    final String result = match.result ?? '';
    won = (result == '1-0' && white) || (result == '0-1' && !white);
    draw = result == '1/2-1/2';
  }
  final OnlineMatchDto match;
  final bool white;
  late final bool won;
  late final bool draw;
  String get opponent => white
      ? (match.blackPlayerName ?? 'Opponent')
      : (match.whitePlayerName ?? 'Opponent');
  String? get opponentPhotoUrl =>
      white ? match.blackPlayerPhotoUrl : match.whitePlayerPhotoUrl;
  String get outcome => draw
      ? 'DRAW'
      : won
      ? 'VICTORY'
      : 'DEFEAT';
  String get reason => (match.resultReason ?? 'FINISHED')
      .replaceAll('_', ' ')
      .toLowerCase()
      .split(' ')
      .map(
        (String word) => word.isEmpty
            ? word
            : '${word[0].toUpperCase()}${word.substring(1)}',
      )
      .join(' ');
  Color get accent => draw
      ? AppColors.accentGold
      : won
      ? const Color(0xFF63D2B8)
      : const Color(0xFFF08A6A);
  int? get ratingDelta =>
      match.ratingBefore == null || match.ratingAfter == null
      ? null
      : match.ratingAfter! - match.ratingBefore!;
}

class _PlayerAvatar extends StatelessWidget {
  const _PlayerAvatar({
    required this.name,
    required this.photoUrl,
    required this.color,
  });
  final String name;
  final String? photoUrl;
  final Color color;
  @override
  Widget build(BuildContext context) {
    final String clean = name.trim();
    final String initials = clean.isEmpty
        ? '?'
        : clean
              .split(RegExp(r'\s+'))
              .take(2)
              .map((String part) => part[0].toUpperCase())
              .join();
    final Uri? uri = Uri.tryParse(photoUrl ?? '');
    final bool networkPhoto =
        uri != null && (uri.scheme == 'https' || uri.scheme == 'http');
    return CircleAvatar(
      backgroundColor: color.withValues(alpha: 0.18),
      backgroundImage: networkPhoto ? NetworkImage(photoUrl!) : null,
      child: networkPhoto
          ? null
          : Text(initials, style: TextStyle(color: color)),
    );
  }
}

String _formatDuration(int? seconds) {
  if (seconds == null) return 'Duration unavailable';
  final int hours = seconds ~/ 3600;
  final int minutes = (seconds % 3600) ~/ 60;
  final int remaining = seconds % 60;
  if (hours > 0) return '${hours}h ${minutes}m';
  return '${minutes}m ${remaining.toString().padLeft(2, '0')}s';
}

String _formatDate(DateTime date) {
  final DateTime local = date.toLocal();
  final String day = local.day.toString().padLeft(2, '0');
  final String month = local.month.toString().padLeft(2, '0');
  final String hour = local.hour.toString().padLeft(2, '0');
  final String minute = local.minute.toString().padLeft(2, '0');
  return '$day/$month/${local.year} • $hour:$minute';
}
