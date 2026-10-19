import 'package:flutter/material.dart';

import '../../../core/club_learning_strings.dart';
import '../../../core/shop_localizations.dart';

/// Seven-day reward cycle, rendered from confirmed server progress only.
class ClubStreakCard extends StatelessWidget {
  const ClubStreakCard({
    super.key,
    required this.reward,
    required this.language,
  });
  final Map<String, dynamic> reward;
  final String language;
  static const amounts = [5, 10, 15, 15, 15, 15, 25];

  @override
  Widget build(BuildContext context) {
    String l(String key) => clubLearningText(key, language);
    final streak = (reward['streak'] as num?)?.toInt() ?? 0;
    final earned = reward['earnedToday'] == true;
    final completed = streak <= 0 ? 0 : (streak - 1) % 7 + 1;
    final displayedCompleted = completed == 7 && !earned ? 0 : completed;
    final award = (reward['awardedCoins'] as num?)?.toInt() ?? 0;
    final shownAward = award > 0
        ? award
        : reward['creditedCoins'] is num
        ? (reward['creditedCoins'] as num).toInt()
        : earned && completed > 0
        ? amounts[completed - 1]
        : 0;
    final next = (reward['nextCoins'] as num?)?.toInt() ?? 5;
    final te = language == 'te';
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF31576A)),
        gradient: const RadialGradient(
          center: Alignment(-.5, -.3),
          radius: 1.4,
          colors: [Color(0xFF10354A), Color(0xFF071D2A)],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '${te ? 'రోజువారీ స్ట్రీక్' : l('streak')} ',
                      ),
                      const WidgetSpan(
                        child: Icon(
                          Icons.local_fire_department_rounded,
                          color: Color(0xFFFF843B),
                          size: 27,
                        ),
                      ),
                    ],
                  ),
                  style: const TextStyle(
                    color: Color(0xFFF1F5FA),
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF005D60),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFF00AAA3)),
                ),
                child: Text(
                  shopText('days', language, {'count': streak}),
                  style: const TextStyle(
                    color: Color(0xFF74F6E0),
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = (constraints.maxWidth - 24) / 4;
              Widget day(int index) {
                final claimed = index < displayedCompleted;
                final upcoming =
                    index == displayedCompleted && displayedCompleted < 7;
                return Container(
                  key: ValueKey('streak-day-${index + 1}'),
                  width: width,
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: claimed
                          ? [const Color(0xFF006D63), const Color(0xFF003B3D)]
                          : [const Color(0xFF152F42), const Color(0xFF091C29)],
                    ),
                    border: Border.all(
                      color: claimed
                          ? const Color(0xFF00AF9E)
                          : upcoming
                          ? const Color(0xFFFFCF57)
                          : const Color(0xFF355970),
                      width: upcoming ? 2 : 1.2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: claimed
                              ? Colors.white
                              : const Color(0xFFB6C9E2),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const _CrownCoin(size: 38),
                          if (claimed)
                            const Positioned(
                              right: -5,
                              bottom: -2,
                              child: Icon(
                                Icons.check_circle,
                                size: 22,
                                color: Color(0xFF5EF5D9),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '+${amounts[index]}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [for (var i = 0; i < 4; i++) day(i)],
                  ),
                  const SizedBox(height: 9),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 4; i < 7; i++) ...[
                        if (i > 4) const SizedBox(width: 8),
                        day(i),
                      ],
                    ],
                  ),
                ],
              );
            },
          ),
          if (shownAward > 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 114,
                    height: 80,
                    child: Stack(
                      children: [
                        Positioned(
                          left: 0,
                          top: 12,
                          child: SizedBox(
                            width: 20,
                            height: 50,
                            child: CustomPaint(painter: _CoinShinePainter()),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 2,
                          child: _CrownCoin(size: 43),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 9,
                          child: _CrownCoin(size: 43),
                        ),
                        Positioned(
                          left: 22,
                          top: 0,
                          child: _CrownCoin(size: 72),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 18),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '+$shownAward ${l('coins')}',
                          key: const ValueKey('club-coins-awarded'),
                          style: const TextStyle(
                            color: Color(0xFF59F3DB),
                            fontSize: 29,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF07565B),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.check_circle,
                                color: Color(0xFF69F8DF),
                                size: 17,
                              ),
                              Padding(
                                padding: EdgeInsetsDirectional.only(start: 6),
                                child: Text(
                                  shopText('received', language),
                                  style: TextStyle(
                                    color: Color(0xFF69F8DF),
                                    fontWeight: FontWeight.w700,
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
            )
          else
            const SizedBox(height: 14),
          const Divider(color: Color(0xFF2A4B5A), height: 1),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 20,
                color: Color(0xFFFFCF57),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  te && earned
                      ? 'రేపు మళ్ళీ ఆడి +$next కాయిన్లు పొందండి.'
                      : '${earned ? l('tomorrow') : l('next')} · +$next ${l('coins')}',
                  style: const TextStyle(
                    color: Color(0xFFDFE8F0),
                    height: 1.5,
                    fontSize: 13,
                  ),
                ),
              ),
              Tooltip(
                message: l('rewardRules'),
                child: InkWell(
                  onTap: () => showDialog<void>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(l('streak')),
                      content: Text(l('rewardRules')),
                      actions: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(5),
                    child: Icon(
                      Icons.info_outline,
                      color: Color(0xFF89A8B9),
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CrownCoin extends StatelessWidget {
  const _CrownCoin({required this.size});
  final double size;
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFF0A4), Color(0xFFFFCD45), Color(0xFFE68C10)],
      ),
      border: Border.all(color: const Color(0xFFFFDF75), width: 2),
      boxShadow: const [
        BoxShadow(
          color: Color(0xFF9C5709),
          offset: Offset(2, 3),
          blurRadius: 0,
        ),
      ],
    ),
    padding: EdgeInsets.all(size * .12),
    child: Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFC07C16), width: 1.5),
      ),
      child: CustomPaint(painter: _CrownPainter()),
    ),
  );
}

class _CoinShinePainter extends CustomPainter {
  const _CoinShinePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFFD65C)
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(11, 2), const Offset(18, 10), paint);
    canvas.drawLine(const Offset(2, 25), const Offset(13, 26), paint);
    canvas.drawLine(const Offset(11, 48), const Offset(18, 41), paint);
  }

  @override
  bool shouldRepaint(_CoinShinePainter oldDelegate) => false;
}

class _CrownPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Path()
      ..moveTo(size.width * .2, size.height * .72)
      ..lineTo(size.width * .12, size.height * .3)
      ..lineTo(size.width * .35, size.height * .43)
      ..lineTo(size.width * .5, size.height * .15)
      ..lineTo(size.width * .65, size.height * .43)
      ..lineTo(size.width * .88, size.height * .3)
      ..lineTo(size.width * .8, size.height * .72)
      ..close();
    canvas.drawPath(p, Paint()..color = const Color(0xFFFFE88B));
    canvas.drawPath(
      p,
      Paint()
        ..color = const Color(0xFFB7750F)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3,
    );
  }

  @override
  bool shouldRepaint(_CrownPainter oldDelegate) => false;
}
