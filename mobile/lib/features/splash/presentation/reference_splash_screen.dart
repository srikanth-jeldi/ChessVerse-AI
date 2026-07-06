import 'package:flutter/material.dart';

class ReferenceSplashScreen extends StatefulWidget {
  const ReferenceSplashScreen({super.key});

  @override
  State<ReferenceSplashScreen> createState() => _ReferenceSplashScreenState();
}

class _ReferenceSplashScreenState extends State<ReferenceSplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1350),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.sizeOf(context);
    final bool wide = size.width > size.height;
    final double logoSize = wide ? 118 : 104;
    final double boardHeight = wide ? size.height * 0.28 : size.height * 0.34;

    return Scaffold(
      backgroundColor: const Color(0xFF02070D),
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  Color(0xFF071B33),
                  Color(0xFF02070D),
                  Color(0xFF010409),
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: boardHeight,
            child: const _ReferenceBoardBottom(),
          ),
          SafeArea(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (BuildContext context, Widget? child) {
                final double fade = Curves.easeOutCubic.transform(_controller.value);
                final double scale = 0.94 + (0.06 * fade);
                return Opacity(
                  opacity: fade,
                  child: Transform.scale(scale: scale, child: child),
                );
              },
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: wide ? size.width * 0.18 : 28,
                  vertical: wide ? 28 : 36,
                ),
                child: Column(
                  children: <Widget>[
                    const Spacer(flex: 2),
                    Image.asset(
                      'assets/branding/app_icon.png',
                      width: logoSize,
                      height: logoSize,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'CHESSVERSE AI',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: const Color(0xFFF8F1E6),
                        fontSize: wide ? 31 : 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 7),
                    const Text(
                      'Play · Learn · Master',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFFD6A84F),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(flex: 3),
                    const Text(
                      'Loading...',
                      style: TextStyle(
                        color: Color(0xFFD6A84F),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: SizedBox(
                        width: 76,
                        height: 4,
                        child: DecoratedBox(
                          decoration: const BoxDecoration(color: Color(0xFF1C2736)),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: AnimatedBuilder(
                              animation: _controller,
                              builder: (BuildContext context, Widget? child) {
                                return FractionallySizedBox(
                                  widthFactor: _controller.value.clamp(0.08, 1),
                                  child: child,
                                );
                              },
                              child: const DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: <Color>[
                                      Color(0xFFD6A84F),
                                      Color(0xFF7C4DFF),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: boardHeight * 0.42),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReferenceBoardBottom extends StatelessWidget {
  const _ReferenceBoardBottom();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        CustomPaint(painter: _ReferenceBoardPainter()),
        Align(
          alignment: const Alignment(0, 0.05),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: const <Widget>[
              _GoldPiece(size: 20),
              _GoldPiece(size: 30),
              _GoldPiece(size: 42),
              _GoldPiece(size: 64),
              _GoldPiece(size: 42),
              _GoldPiece(size: 30),
              _GoldPiece(size: 20),
            ],
          ),
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[
                Color(0x0002070D),
                Color(0x3302070D),
                Color(0xDD02070D),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _GoldPiece extends StatelessWidget {
  const _GoldPiece({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size * 0.62,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFD6A84F).withValues(alpha: 0.76),
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(size * 0.34),
          bottom: Radius.circular(size * 0.12),
        ),
        boxShadow: const <BoxShadow>[
          BoxShadow(color: Colors.black, blurRadius: 18, offset: Offset(0, 8)),
        ],
      ),
    );
  }
}

class _ReferenceBoardPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const int rows = 4;
    const int cols = 8;
    final Paint dark = Paint()..color = const Color(0xFF21160D).withValues(alpha: 0.78);
    final Paint light = Paint()..color = const Color(0xFFD6A84F).withValues(alpha: 0.22);
    for (int r = 0; r < rows; r++) {
      final double topT = r / rows;
      final double bottomT = (r + 1) / rows;
      final double topY = size.height * (0.16 + topT * 0.84);
      final double bottomY = size.height * (0.16 + bottomT * 0.84);
      final double topLeft = size.width * (0.14 * (1 - topT));
      final double topRight = size.width - topLeft;
      final double bottomLeft = size.width * (0.14 * (1 - bottomT));
      final double bottomRight = size.width - bottomLeft;
      for (int c = 0; c < cols; c++) {
        final Path square = Path()
          ..moveTo(topLeft + (topRight - topLeft) * c / cols, topY)
          ..lineTo(topLeft + (topRight - topLeft) * (c + 1) / cols, topY)
          ..lineTo(bottomLeft + (bottomRight - bottomLeft) * (c + 1) / cols, bottomY)
          ..lineTo(bottomLeft + (bottomRight - bottomLeft) * c / cols, bottomY)
          ..close();
        canvas.drawPath(square, (r + c).isEven ? light : dark);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
