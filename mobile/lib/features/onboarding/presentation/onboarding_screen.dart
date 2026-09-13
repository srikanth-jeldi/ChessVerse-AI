import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({required this.onComplete, super.key});
  final VoidCallback onComplete;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _page = 0;

  static const List<_OnboardingPageData> _pages = <_OnboardingPageData>[
    _OnboardingPageData(
      eyebrow: 'PLAY · LEARN · IMPROVE',
      title: 'More Than\nJust a Game',
      body: 'Play, learn, and improve with an AI-powered chess universe.',
      asset: 'assets/backgrounds/home-learn-hero-v1.webp',
      icon: Icons.auto_awesome_rounded,
    ),
    _OnboardingPageData(
      eyebrow: 'YOUR PERSONAL CHESS MENTOR',
      title: 'AI Coach\nAlways With You',
      body:
          'Get personalised feedback, clear explanations, and improve faster.',
      asset: 'assets/backgrounds/home-analysis-hero-v1.webp',
      icon: Icons.psychology_alt_rounded,
    ),
    _OnboardingPageData(
      eyebrow: 'THE WORLD IS YOUR BOARD',
      title: 'Challenge Players\nWorldwide',
      body: 'Climb the ranks, meet worthy rivals, and join live tournaments.',
      asset: 'assets/backgrounds/home-online-hero-v1.webp',
      icon: Icons.public_rounded,
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_page == _pages.length - 1) {
      widget.onComplete();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: DecoratedBox(
      decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final bool landscape = constraints.maxWidth > constraints.maxHeight;
            final bool tight = constraints.maxHeight < 430;
            return Padding(
              padding: EdgeInsets.fromLTRB(
                landscape ? 28 : 18,
                tight ? 6 : 12,
                landscape ? 28 : 18,
                tight ? 8 : 18,
              ),
              child: Column(
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      AnimatedOpacity(
                        duration: const Duration(milliseconds: 180),
                        opacity: _page == 0 ? 0 : 1,
                        child: IconButton(
                          tooltip: 'Previous',
                          onPressed: _page == 0
                              ? null
                              : () => _controller.previousPage(
                                  duration: const Duration(milliseconds: 320),
                                  curve: Curves.easeOutCubic,
                                ),
                          icon: const Icon(Icons.arrow_back_rounded),
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: widget.onComplete,
                        child: const Text('Skip'),
                      ),
                    ],
                  ),
                  Expanded(
                    child: PageView.builder(
                      controller: _controller,
                      itemCount: _pages.length,
                      onPageChanged: (int value) =>
                          setState(() => _page = value),
                      itemBuilder: (_, int index) => _OnboardingPage(
                        data: _pages[index],
                        landscape: landscape,
                        tight: tight,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List<Widget>.generate(
                      _pages.length,
                      (int index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 240),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: index == _page ? 26 : 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: index == _page
                              ? AppColors.primary
                              : AppColors.border,
                          borderRadius: BorderRadius.circular(99),
                          boxShadow: index == _page
                              ? <BoxShadow>[
                                  BoxShadow(
                                    color: AppColors.primary.withValues(
                                      alpha: .45,
                                    ),
                                    blurRadius: 10,
                                  ),
                                ]
                              : null,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: tight ? 8 : 16),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton(
                        key: const ValueKey<String>(
                          'onboarding-primary-action',
                        ),
                        onPressed: _next,
                        style: FilledButton.styleFrom(
                          backgroundColor: _page == _pages.length - 1
                              ? AppColors.accentGold
                              : AppColors.primary,
                          foregroundColor: const Color(0xFF04111C),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Text(
                              _page == _pages.length - 1
                                  ? 'Get Started'
                                  : 'Next',
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward_rounded, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    ),
  );
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({
    required this.data,
    required this.landscape,
    required this.tight,
  });

  final _OnboardingPageData data;
  final bool landscape;
  final bool tight;

  @override
  Widget build(BuildContext context) {
    final Widget artwork = Container(
      constraints: BoxConstraints(
        maxWidth: landscape ? 430 : 520,
        maxHeight: landscape ? 300 : 420,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.primary.withValues(alpha: .7)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.primary.withValues(alpha: .22),
            blurRadius: 34,
            spreadRadius: -8,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(27),
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            Image.asset(data.asset, fit: BoxFit.cover),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[Color(0x14000000), Color(0xD9041320)],
                ),
              ),
            ),
            Center(
              child: Container(
                width: landscape ? 76 : 92,
                height: landscape ? 76 : 92,
                decoration: BoxDecoration(
                  color: const Color(0xD9071929),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary, width: 1.5),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: .35),
                      blurRadius: 28,
                    ),
                  ],
                ),
                child: Icon(data.icon, color: AppColors.accentGold, size: 42),
              ),
            ),
          ],
        ),
      ),
    );

    final Widget copy = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 500),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            data.eyebrow,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.accentGold,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.7,
            ),
          ),
          SizedBox(height: tight ? 5 : 10),
          Text(
            data.title,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: TextStyle(
              color: AppColors.textPrimary,
              height: 1.04,
              fontSize: landscape ? 34 : (tight ? 26 : 38),
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: tight ? 6 : 14),
          Text(
            data.body,
            textAlign: TextAlign.center,
            maxLines: landscape ? 2 : 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.textSecondary,
              height: 1.45,
              fontSize: tight ? 13 : 16,
            ),
          ),
        ],
      ),
    );

    if (landscape) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Expanded(child: artwork),
          const SizedBox(width: 34),
          Expanded(child: copy),
        ],
      );
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Expanded(child: artwork),
        SizedBox(height: tight ? 10 : 24),
        copy,
      ],
    );
  }
}

class _OnboardingPageData {
  const _OnboardingPageData({
    required this.eyebrow,
    required this.title,
    required this.body,
    required this.asset,
    required this.icon,
  });

  final String eyebrow;
  final String title;
  final String body;
  final String asset;
  final IconData icon;
}
