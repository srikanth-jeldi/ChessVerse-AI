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
                              color: const Color(
                                0xFF02070D,
                              ).withValues(alpha: 0.72),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: const Color(
                                  0xFFFFCE6A,
                                ).withValues(alpha: 0.42),
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
                          color: const Color(
                            0xFF63D2B8,
                          ).withValues(alpha: 0.34),
                          blurRadius: 52,
                          spreadRadius: 10,
                        ),
                        BoxShadow(
                          color: const Color(
                            0xFFD6A84F,
                          ).withValues(alpha: 0.18),
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
      backgroundColor: const Color(0xFF02070D),
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final Size viewport = MediaQuery.sizeOf(context);
          final bool wide =
              viewport.shortestSide >= 600 && constraints.maxWidth >= 800;
          return Stack(
            fit: StackFit.expand,
            children: <Widget>[
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(0, -0.05),
                    radius: 1.05,
                    colors: <Color>[
                      Color(0xFF0A5A50),
                      Color(0xFF071B22),
                      Color(0xFF02070D),
                    ],
                  ),
                ),
              ),
              SafeArea(
                child: wide
                    ? const _WideChessVerseLoadingPanel()
                    : const _MobileChessVerseLoadingPanel(),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MobileChessVerseLoadingPanel extends StatelessWidget {
  const _MobileChessVerseLoadingPanel();

  @override
  Widget build(BuildContext context) {
    final bool compact = MediaQuery.sizeOf(context).height < 700;
    return Center(
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        padding: EdgeInsets.symmetric(
          horizontal: 30,
          vertical: compact ? 18 : 32,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 390),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _LoadingLogo(size: compact ? 102 : 124),
              SizedBox(height: compact ? 22 : 30),
              const _LoadingBrand(centered: true),
              SizedBox(height: compact ? 40 : 64),
              const _LoadingProgress(centered: true),
              SizedBox(height: compact ? 22 : 34),
              const _MobileLoadingFeatures(),
            ],
          ),
        ),
      ),
    );
  }
}

class _WideChessVerseLoadingPanel extends StatelessWidget {
  const _WideChessVerseLoadingPanel();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.all(28),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: Container(
            constraints: const BoxConstraints(minHeight: 610),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: const Color(0xE6041018),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: const Color(0x66566D70), width: 2),
              boxShadow: const <BoxShadow>[
                BoxShadow(color: Color(0x6600B9A8), blurRadius: 48),
              ],
            ),
            child: Stack(
              children: <Widget>[
                Positioned.fill(
                  left: 500,
                  child: Image.asset(
                    'assets/backgrounds/home-online-hero-v1.webp',
                    fit: BoxFit.cover,
                    alignment: Alignment.centerRight,
                  ),
                ),
                const Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: <Color>[
                          Color(0xFF031019),
                          Color(0xF2031019),
                          Color(0x70031019),
                          Color(0x12031019),
                        ],
                        stops: <double>[0, .37, .62, 1],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(68, 62, 68, 38),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Row(
                        children: <Widget>[
                          _LoadingLogo(size: 116),
                          SizedBox(width: 28),
                          _LoadingBrand(centered: false),
                        ],
                      ),
                      const SizedBox(height: 42),
                      const SizedBox(
                        width: 520,
                        child: _LoadingProgress(centered: false),
                      ),
                      const SizedBox(height: 42),
                      const _LoadingFeatureStrip(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LoadingLogo extends StatelessWidget {
  const _LoadingLogo({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * .08),
      decoration: BoxDecoration(
        color: const Color(0xE6071520),
        borderRadius: BorderRadius.circular(size * .25),
        border: Border.all(color: const Color(0xFFE0B85E), width: 1.4),
        boxShadow: const <BoxShadow>[
          BoxShadow(color: Color(0x554DE1C8), blurRadius: 42, spreadRadius: 5),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * .18),
        child: Image.asset('assets/branding/app_icon.png', fit: BoxFit.cover),
      ),
    );
  }
}

class _LoadingBrand extends StatelessWidget {
  const _LoadingBrand({required this.centered});

  final bool centered;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: centered
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: <Widget>[
        Text.rich(
          const TextSpan(
            children: <InlineSpan>[
              TextSpan(text: 'CHESSVERSE'),
              TextSpan(
                text: ' AI',
                style: TextStyle(color: Color(0xFFF2BF4D)),
              ),
            ],
          ),
          textAlign: centered ? TextAlign.center : TextAlign.left,
          style: TextStyle(
            color: const Color(0xFFF8F2E4),
            fontSize: centered ? 30 : 42,
            height: 1,
            fontWeight: FontWeight.w900,
            letterSpacing: centered ? .4 : .8,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Think  •  Move  •  Master',
          textAlign: centered ? TextAlign.center : TextAlign.left,
          style: TextStyle(
            color: const Color(0xFFE0B85E),
            fontSize: centered ? 16 : 22,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}

class _LoadingProgress extends StatelessWidget {
  const _LoadingProgress({required this.centered});

  final bool centered;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: centered
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Preparing your board',
          textAlign: centered ? TextAlign.center : TextAlign.left,
          style: TextStyle(
            color: const Color(0xFFF8F2E4),
            fontSize: centered ? 18 : 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 17),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: const LinearProgressIndicator(
            minHeight: 8,
            backgroundColor: Color(0x332F5757),
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF59D4C1)),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Loading pieces, puzzles, and your profile',
          textAlign: centered ? TextAlign.center : TextAlign.left,
          style: TextStyle(
            color: const Color(0xFFAAAEB5),
            fontSize: centered ? 14 : 17,
          ),
        ),
      ],
    );
  }
}

class _LoadingFeatureStrip extends StatelessWidget {
  const _LoadingFeatureStrip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 22),
      decoration: BoxDecoration(
        color: const Color(0xD9061822),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x443E6E72)),
      ),
      child: const Row(
        children: <Widget>[
          Expanded(
            child: _LoadingFeature(
              icon: Icons.extension_rounded,
              title: 'Smart Puzzles',
              subtitle: 'Train your mind daily',
            ),
          ),
          VerticalDivider(color: Color(0x445A7178)),
          Expanded(
            child: _LoadingFeature(
              icon: Icons.emoji_events_outlined,
              title: 'Compete',
              subtitle: 'Challenge players worldwide',
            ),
          ),
          VerticalDivider(color: Color(0x445A7178)),
          Expanded(
            child: _LoadingFeature(
              icon: Icons.trending_up_rounded,
              title: 'Track Progress',
              subtitle: 'Improve and climb ranks',
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingFeature extends StatelessWidget {
  const _LoadingFeature({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Icon(icon, color: const Color(0xFF59D4C1), size: 38),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(color: Color(0xFFADB7C1), fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }
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
