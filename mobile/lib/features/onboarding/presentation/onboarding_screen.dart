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
      body: 'Play brilliant games, build real skills, and improve every day.',
      asset: 'assets/backgrounds/onboarding-mastery-v1.png',
      wideAsset: 'assets/backgrounds/onboarding-mastery-wide-v2.png',
      accent: Color(0xFF56E3CF),
    ),
    _OnboardingPageData(
      eyebrow: 'YOUR PERSONAL CHESS MENTOR',
      title: 'AI Coach\nAlways With You',
      body: 'Understand every mistake with clear, personalised feedback.',
      asset: 'assets/backgrounds/onboarding-ai-coach-v1.png',
      wideAsset: 'assets/backgrounds/onboarding-ai-coach-wide-v2.png',
      accent: Color(0xFF55C9FF),
    ),
    _OnboardingPageData(
      eyebrow: 'THE WORLD IS YOUR BOARD',
      title: 'Challenge Players\nWorldwide',
      body: 'Find worthy rivals, climb the ranks, and join live tournaments.',
      asset: 'assets/backgrounds/onboarding-worldwide-v1.png',
      wideAsset: 'assets/backgrounds/onboarding-worldwide-wide-v2.png',
      accent: Color(0xFFF3BE4F),
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
      duration: const Duration(milliseconds: 420),
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
            final bool wide = constraints.maxWidth >= 760;
            final bool compact = constraints.maxHeight < 620;
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1180),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    wide ? 32 : 16,
                    compact ? 8 : 14,
                    wide ? 32 : 16,
                    compact ? 10 : 18,
                  ),
                  child: Column(
                    children: <Widget>[
                      _OnboardingHeader(
                        page: _page,
                        pageCount: _pages.length,
                        onBack: _page == 0
                            ? null
                            : () => _controller.previousPage(
                                duration: const Duration(milliseconds: 360),
                                curve: Curves.easeOutCubic,
                              ),
                        onSkip: widget.onComplete,
                      ),
                      SizedBox(height: compact ? 8 : 14),
                      Expanded(
                        child: PageView.builder(
                          controller: _controller,
                          itemCount: _pages.length,
                          onPageChanged: (int value) =>
                              setState(() => _page = value),
                          itemBuilder: (_, int index) => _OnboardingStoryCard(
                            data: _pages[index],
                            wide: wide,
                            compact: compact,
                          ),
                        ),
                      ),
                      SizedBox(height: compact ? 10 : 16),
                      _OnboardingFooter(
                        page: _page,
                        pageCount: _pages.length,
                        accent: _pages[_page].accent,
                        onNext: _next,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    ),
  );
}

class _OnboardingHeader extends StatelessWidget {
  const _OnboardingHeader({
    required this.page,
    required this.pageCount,
    required this.onBack,
    required this.onSkip,
  });
  final int page;
  final int pageCount;
  final VoidCallback? onBack;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 44,
    child: Row(
      children: <Widget>[
        SizedBox(
          width: 82,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 180),
            opacity: onBack == null ? 0 : 1,
            child: Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                tooltip: 'Previous',
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_rounded),
              ),
            ),
          ),
        ),
        Expanded(
          child: Text(
            '${page + 1} / $pageCount',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.4,
            ),
          ),
        ),
        SizedBox(
          width: 82,
          child: Align(
            alignment: Alignment.centerRight,
            child: TextButton(onPressed: onSkip, child: const Text('Skip')),
          ),
        ),
      ],
    ),
  );
}

class _OnboardingStoryCard extends StatelessWidget {
  const _OnboardingStoryCard({
    required this.data,
    required this.wide,
    required this.compact,
  });
  final _OnboardingPageData data;
  final bool wide;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final double radius = wide ? 34 : 28;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: wide ? 8 : 2),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: data.accent.withValues(alpha: .62)),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: data.accent.withValues(alpha: .18),
              blurRadius: 34,
              spreadRadius: -8,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius - 1),
          child: wide ? _wideStory() : _portraitStory(),
        ),
      ),
    );
  }

  Widget _wideStory() => Stack(
    fit: StackFit.expand,
    children: <Widget>[
      Image.asset(data.wideAsset, fit: BoxFit.cover),
      const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            stops: <double>[0, .4, .72, 1],
            colors: <Color>[
              Color(0xE8051422),
              Color(0xA8051422),
              Color(0x20051422),
              Color(0x05051422),
            ],
          ),
        ),
      ),
      Positioned(
        left: compact ? 34 : 54,
        bottom: compact ? 28 : 46,
        width: compact ? 390 : 470,
        child: _OnboardingCopy(data: data, wide: true, compact: compact),
      ),
    ],
  );

  Widget _portraitStory() => Stack(
    fit: StackFit.expand,
    children: <Widget>[
      Image.asset(data.asset, fit: BoxFit.cover, alignment: Alignment.center),
      const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: <double>[0, .42, .72, 1],
            colors: <Color>[
              Color(0x16051422),
              Color(0x26051422),
              Color(0xCC051422),
              Color(0xFF051422),
            ],
          ),
        ),
      ),
      Positioned(
        left: 24,
        right: 24,
        bottom: compact ? 22 : 34,
        child: _OnboardingCopy(data: data, wide: false, compact: compact),
      ),
    ],
  );
}

class _OnboardingCopy extends StatelessWidget {
  const _OnboardingCopy({
    required this.data,
    required this.wide,
    required this.compact,
  });
  final _OnboardingPageData data;
  final bool wide;
  final bool compact;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 28,
            height: 2,
            decoration: BoxDecoration(
              color: data.accent,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              data.eyebrow,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: data.accent,
                fontSize: compact ? 10 : 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.45,
              ),
            ),
          ),
        ],
      ),
      SizedBox(height: compact ? 8 : 13),
      Text(
        data.title,
        maxLines: 2,
        style: TextStyle(
          color: AppColors.textPrimary,
          height: .98,
          fontSize: wide ? (compact ? 34 : 46) : (compact ? 28 : 38),
          fontWeight: FontWeight.w900,
          letterSpacing: -.7,
          shadows: const <Shadow>[
            Shadow(color: Color(0xAA000000), blurRadius: 16),
          ],
        ),
      ),
      SizedBox(height: compact ? 9 : 14),
      Text(
        data.body,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: const Color(0xFFD7E1EA),
          height: 1.4,
          fontSize: compact ? 13 : 16,
          fontWeight: FontWeight.w500,
          shadows: const <Shadow>[
            Shadow(color: Color(0xDD000000), blurRadius: 12),
          ],
        ),
      ),
    ],
  );
}

class _OnboardingFooter extends StatelessWidget {
  const _OnboardingFooter({
    required this.page,
    required this.pageCount,
    required this.accent,
    required this.onNext,
  });
  final int page;
  final int pageCount;
  final Color accent;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) => Row(
    children: <Widget>[
      Expanded(
        child: Row(
          children: List<Widget>.generate(
            pageCount,
            (int index) => AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              margin: const EdgeInsets.only(right: 7),
              width: index == page ? 30 : 7,
              height: 7,
              decoration: BoxDecoration(
                color: index == page ? accent : AppColors.border,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
        ),
      ),
      ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 178),
        child: SizedBox(
          height: 52,
          child: FilledButton(
            key: const ValueKey<String>('onboarding-primary-action'),
            onPressed: onNext,
            style: FilledButton.styleFrom(
              backgroundColor: accent,
              foregroundColor: const Color(0xFF04111C),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  page == pageCount - 1 ? 'Get Started' : 'Next',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_rounded, size: 19),
              ],
            ),
          ),
        ),
      ),
    ],
  );
}

class _OnboardingPageData {
  const _OnboardingPageData({
    required this.eyebrow,
    required this.title,
    required this.body,
    required this.asset,
    required this.wideAsset,
    required this.accent,
  });
  final String eyebrow;
  final String title;
  final String body;
  final String asset;
  final String wideAsset;
  final Color accent;
}
