part of '../main.dart';

enum _RootStage { splash, loading, onboarding, auth, home }

class BrandedSplash extends StatelessWidget {
  const BrandedSplash({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF02070D),
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          // Landscape always gets the dedicated edge-to-edge composition.
          // Portrait phones retain the compact splash used on mobile.
          final Size viewport = MediaQuery.sizeOf(context);
          final bool phoneSized = viewport.shortestSide < 600;
          final bool landscape = viewport.width > viewport.height;
          final bool wide =
              landscape ||
              (!phoneSized &&
                  (constraints.maxWidth >= 720 || constraints.maxWidth <= 0));
          const String wideAsset =
              'assets/branding/chessverse_king_dual_splash.jpg';
          const String mobileAsset =
              'assets/branding/splash_screen_mobile_v2.jpg';
          if (!wide) {
            return Stack(
              fit: StackFit.expand,
              children: <Widget>[
                const Opacity(
                  opacity: 0.34,
                  child: Image(
                    image: AssetImage(mobileAsset),
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                    filterQuality: FilterQuality.medium,
                  ),
                ),
                const Image(
                  key: ValueKey<String>('branded-splash-image'),
                  image: AssetImage(mobileAsset),
                  fit: BoxFit.contain,
                  alignment: Alignment.center,
                  filterQuality: FilterQuality.high,
                ),
                IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: <Color>[
                          const Color(0xFF02070D).withValues(alpha: 0.04),
                          Colors.transparent,
                          const Color(0xFF02070D).withValues(alpha: 0.20),
                          const Color(0xFF02070D).withValues(alpha: 0.96),
                        ],
                        stops: const <double>[0, 0.46, 0.70, 1],
                      ),
                    ),
                  ),
                ),
                SafeArea(
                  minimum: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                    child: Column(
                      children: <Widget>[
                        const Spacer(flex: 7),
                        ShaderMask(
                          shaderCallback: (Rect bounds) => const LinearGradient(
                            colors: <Color>[
                              Color(0xFFFFE2A0),
                              Color(0xFFF8F4E8),
                              Color(0xFF75C9FF),
                            ],
                          ).createShader(bounds),
                          child: const Text(
                            'CHESSVERSEAI',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 34,
                              height: 1,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2.6,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'PLAY  •  LEARN  •  MASTER',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.72),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2.2,
                          ),
                        ),
                        const SizedBox(height: 26),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: const SizedBox(
                            width: 132,
                            child: LinearProgressIndicator(
                              minHeight: 3,
                              backgroundColor: Color(0x332F8DFF),
                              color: Color(0xFFFFCE6A),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 260),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF02070D)
                                  .withValues(alpha: 0.72),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: const Color(0xFFFFCE6A)
                                    .withValues(alpha: 0.42),
                              ),
                            ),
                            child: const FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'Powered by EpitomeHub',
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                style: TextStyle(
                                  color: Color(0xFFFFD77D),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.7,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }
          return Stack(
            fit: StackFit.expand,
            children: <Widget>[
              const ColoredBox(
                color: Color(0xFF02070D),
                child: Image(
                  key: ValueKey<String>('branded-splash-image-wide'),
                  image: AssetImage(wideAsset),
                  fit: BoxFit.contain,
                  alignment: Alignment.center,
                  filterQuality: FilterQuality.high,
                ),
              ),
              IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: <Color>[
                        Color(0x1202070D),
                        Colors.transparent,
                        Color(0x2602070D),
                      ],
                      stops: <double>[0, 0.62, 1],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// Kept as a lightweight code-only fallback for devices that cannot decode the
// high-resolution splash artwork.
// ignore: unused_element
class _MobilePremiumSplash extends StatelessWidget {
  const _MobilePremiumSplash();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.28),
          radius: 1.18,
          colors: <Color>[
            Color(0xFF0C5F5A),
            Color(0xFF081B33),
            Color(0xFF02070D),
          ],
          stops: <double>[0, 0.45, 1],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          const _PremiumSplashBoardGlow(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 30),
              child: Column(
                children: <Widget>[
                  const Spacer(flex: 2),
                  Container(
                    width: 126,
                    height: 126,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(34),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: <Color>[Color(0xFF0D1F37), Color(0xFF061018)],
                      ),
                      border: Border.all(
                        color: const Color(0xFFE0B85E),
                        width: 1.4,
                      ),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: const Color(0xFF63D2B8)
                              .withValues(alpha: 0.34),
                          blurRadius: 52,
                          spreadRadius: 10,
                        ),
                        BoxShadow(
                          color: const Color(0xFFD6A84F)
                              .withValues(alpha: 0.18),
                          blurRadius: 30,
                          offset: const Offset(0, 14),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.asset(
                        'assets/branding/app_icon.png',
                        fit: BoxFit.cover,
                        filterQuality: FilterQuality.high,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  FittedBox(
                    child: Text(
                      'CHESSVERSEAI',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: const Color(0xFFF8F2E4),
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Think • Move • Master',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: const Color(0xFFE0B85E),
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Container(
                    height: 7,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: const Color(0xFF2B160B),
                      border: Border.all(
                        color: const Color(0xFF795022).withValues(alpha: 0.7),
                      ),
                    ),
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: 0.76,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          gradient: const LinearGradient(
                            colors: <Color>[
                              Color(0xFFE0B85E),
                              Color(0xFF63D2B8),
                              Color(0xFF7C4DFF),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Spacer(flex: 3),
                  Text(
                    'Powered by EpitomeHub',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: const Color(0xCCF8F2E4),
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumSplashBoardGlow extends StatelessWidget {
  const _PremiumSplashBoardGlow();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Opacity(
        opacity: 0.055,
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 8,
          ),
          itemCount: 96,
          itemBuilder: (BuildContext context, int index) {
            final int row = index ~/ 8;
            final int col = index % 8;
            return ColoredBox(
              color: (row + col).isEven
                  ? const Color(0xFFDCC58A)
                  : const Color(0xFF063B35),
            );
          },
        ),
      ),
    );
  }
}

class ChessVerseLoadingScreen extends StatelessWidget {
  const ChessVerseLoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF021018),
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Image.asset(
            'assets/branding/loading-cinematic-v1.webp',
            fit: BoxFit.cover,
            excludeFromSemantics: true,
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                radius: .95,
                colors: <Color>[Color(0x18001018), Color(0x66001018)],
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final bool landscape =
                    constraints.maxWidth > constraints.maxHeight;
                final double canvasWidth = landscape ? 760 : 390;
                final double canvasHeight = landscape ? 480 : 800;
                return Center(
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: SizedBox(
                      width: canvasWidth,
                      height: canvasHeight,
                      child: landscape ? _landscape() : _portrait(),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _portrait() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 34),
    child: Column(
      children: <Widget>[
        const SizedBox(height: 14),
        const Align(
          alignment: Alignment.centerRight,
          child: Text(
            'A SMARTER\nPLAYER\nA BRIGHTER\nYOU',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontFamily: 'ChessVerseSerif',
              color: Color(0xFF92BCC6),
              fontSize: 8,
              height: 1.9,
              letterSpacing: 3,
            ),
          ),
        ),
        const SizedBox(height: 24),
        const _LoadingLogo(size: 142),
        const SizedBox(height: 24),
        const _LoadingBrand(),
        const SizedBox(height: 16),
        const _LoadingCrown(),
        const SizedBox(height: 28),
        const _LoadingProgress(),
        const SizedBox(height: 28),
        const _CinematicLoadingFeatures(),
        const Spacer(),
        const Text(
          'MORE THAN A GAME\nA BRIGHTER MIND',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'ChessVerseSerif',
            color: Color(0xFFBED0D2),
            fontSize: 8,
            height: 2.3,
            letterSpacing: 4,
          ),
        ),
        const SizedBox(height: 18),
      ],
    ),
  );

  Widget _landscape() => Padding(
    padding: const EdgeInsets.all(38),
    child: Row(
      children: <Widget>[
        const Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              _LoadingLogo(size: 152),
              SizedBox(height: 24),
              _LoadingBrand(),
              SizedBox(height: 20),
              _LoadingCrown(),
            ],
          ),
        ),
        const SizedBox(width: 40),
        const Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              _LoadingProgress(),
              SizedBox(height: 32),
              _CinematicLoadingFeatures(),
            ],
          ),
        ),
      ],
    ),
  );
}

class _LoadingLogo extends StatelessWidget {
  const _LoadingLogo({required this.size});
  final double size;
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: const Color(0xFF031320),
      borderRadius: BorderRadius.circular(size * .26),
      border: Border.all(color: const Color(0xFFFFDB7B), width: 2.5),
      boxShadow: const <BoxShadow>[
        BoxShadow(color: Color(0x6672F5C9), blurRadius: 34, spreadRadius: 3),
        BoxShadow(color: Color(0x55FFD477), blurRadius: 10),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(size * .18),
      child: Image.asset(
        'assets/branding/app_icon.png',
        semanticLabel: 'ChessVerse AI',
        fit: BoxFit.cover,
      ),
    ),
  );
}

class _LoadingBrand extends StatelessWidget {
  const _LoadingBrand();
  @override
  Widget build(BuildContext context) => const Column(
    children: <Widget>[
      FittedBox(
        child: Text.rich(
          TextSpan(
            children: <InlineSpan>[
              TextSpan(text: 'CHESSVERSE '),
              TextSpan(
                text: 'AI',
                style: TextStyle(color: Color(0xFFFFCF69)),
              ),
            ],
          ),
          style: TextStyle(
            fontFamily: 'ChessVerseSerif',
            fontFamilyFallback: <String>['Noto Serif', 'serif'],
            color: Color(0xFFFFFAEF),
            fontSize: 37,
            height: 1.1,
            fontWeight: FontWeight.w600,
            shadows: <Shadow>[Shadow(color: Color(0x5534C6B7), blurRadius: 14)],
          ),
        ),
      ),
      SizedBox(height: 7),
      Text(
        'Think • Move • Master',
        style: TextStyle(
          fontFamily: 'ChessVerseSerif',
          color: Color(0xFFF1C86E),
          fontSize: 16,
          letterSpacing: 2.6,
        ),
      ),
    ],
  );
}

class _LoadingCrown extends StatelessWidget {
  const _LoadingCrown();
  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: <Widget>[
      SizedBox(width: 82, child: Divider(color: Color(0xFFBD974B))),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: ClipPath(
          clipper: _LoadingCrownClipper(),
          child: const SizedBox(
            width: 22,
            height: 18,
            child: ColoredBox(color: Color(0xFFF5C55F)),
          ),
        ),
      ),
      SizedBox(width: 82, child: Divider(color: Color(0xFFBD974B))),
    ],
  );
}

class _LoadingCrownClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) => Path()
    ..moveTo(0, 2)
    ..lineTo(size.width * .27, size.height * .48)
    ..lineTo(size.width * .5, 0)
    ..lineTo(size.width * .73, size.height * .48)
    ..lineTo(size.width, 2)
    ..lineTo(size.width * .85, size.height)
    ..lineTo(size.width * .15, size.height)
    ..close();
  @override
  bool shouldReclip(_LoadingCrownClipper oldClipper) => false;
}

class _LoadingProgress extends StatelessWidget {
  const _LoadingProgress();
  @override
  Widget build(BuildContext context) => Column(
    children: <Widget>[
      const Text(
        'Preparing your board',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'ChessVerseSerif',
          color: Color(0xFFFFFAEF),
          fontSize: 23,
        ),
      ),
      const SizedBox(height: 18),
      Semantics(
        label: 'Loading your chess workspace',
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(40),
            border: Border.all(color: const Color(0xFF69E8E5)),
            color: const Color(0xCC03242D),
            boxShadow: const <BoxShadow>[
              BoxShadow(color: Color(0x5536F4DE), blurRadius: 18),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: LinearProgressIndicator(
              minHeight: 10,
              color: const Color(0xFF37F2DA),
              backgroundColor: const Color(0xFF123B42),
              value: MediaQuery.disableAnimationsOf(context) ? .65 : null,
            ),
          ),
        ),
      ),
      const SizedBox(height: 13),
      const Text(
        'Loading pieces, puzzles, and your profile',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'ChessVerseSerif',
          color: Color(0xFFA5C6D1),
          fontSize: 13,
          height: 1.5,
        ),
      ),
    ],
  );
}

class _CinematicLoadingFeatures extends StatelessWidget {
  const _CinematicLoadingFeatures();
  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceAround,
    children: <Widget>[
      _feature(Icons.extension_rounded, 'Puzzles'),
      _feature(Icons.emoji_events_outlined, 'Compete'),
      _feature(Icons.stacked_bar_chart_rounded, 'Progress'),
    ],
  );
  Widget _feature(IconData icon, String title) => Column(
    children: <Widget>[
      Container(
        width: 57,
        height: 57,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const RadialGradient(
            colors: <Color>[Color(0xBB09535D), Color(0xEE021923)],
          ),
          border: Border.all(color: const Color(0xFF4BCEC9)),
          boxShadow: const <BoxShadow>[
            BoxShadow(color: Color(0x3341F3D5), blurRadius: 12),
          ],
        ),
        child: Icon(icon, size: 29, color: const Color(0xFF5EF7E4)),
      ),
      const SizedBox(height: 7),
      Text(
        title,
        style: const TextStyle(
          fontFamily: 'ChessVerseSerif',
          color: Color(0xFFFAF7EF),
          fontSize: 14,
        ),
      ),
    ],
  );
}

class ChessVerseTheme {
  static ThemeData dark() {
    const ink = Color(0xFF101014);
    const brass = Color(0xFFD6A84F);
    const mint = Color(0xFF63D2B8);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: brass,
        secondary: mint,
        surface: Color(0xFF1A1B20),
        onSurface: Color(0xFFF6F1E8),
      ),
      scaffoldBackgroundColor: Colors.transparent,
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xD9071827),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        toolbarHeight: 64,
        titleTextStyle: TextStyle(
          color: Color(0xFFF6F1E8),
          fontSize: 20,
          fontWeight: FontWeight.w900,
          letterSpacing: .8,
        ),
      ),
      fontFamily: 'Roboto',
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          color: Color(0xFFF6F1E8),
          fontSize: 30,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        ),
        titleLarge: TextStyle(
          color: Color(0xFFF6F1E8),
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
        titleMedium: TextStyle(
          color: Color(0xFFE6D8BC),
          fontSize: 14,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
        bodyMedium: TextStyle(
          color: Color(0xFFC8C1B6),
          height: 1.35,
          letterSpacing: 0,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: brass,
          foregroundColor: ink,
          minimumSize: const Size(48, 46),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFF6F1E8),
          side: const BorderSide(color: Color(0xFF61553F)),
          minimumSize: const Size(48, 46),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: const Color(0xFFF6F1E8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}
