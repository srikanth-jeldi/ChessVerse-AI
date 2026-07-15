import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    required this.onComplete,
    super.key,
  });

  final VoidCallback onComplete;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _page = 0;

  static const List<_OnboardingPageData> _pages = <_OnboardingPageData>[
    _OnboardingPageData(
      title: 'Welcome to ChessVerse AI',
      subtitle: 'Your intelligent chess companion.',
      body:
          'Play, learn and improve with AI coaching, puzzles and rich game analysis.',
      icon: Icons.auto_awesome_rounded,
    ),
    _OnboardingPageData(
      title: 'Daily checkmate',
      subtitle: 'One fresh tactical mission every day.',
      body: 'Solve 3, 4 or 5-move forcing lines and build a daily streak.',
      icon: Icons.emoji_events_rounded,
    ),
    _OnboardingPageData(
      title: 'Built for every screen',
      subtitle: 'Portrait, landscape, tablet and web.',
      body: 'The board and controls adapt so the game always feels native.',
      icon: Icons.devices_rounded,
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final bool landscape =
                  constraints.maxWidth > constraints.maxHeight;
              final bool tight = constraints.maxHeight < 430;
              final EdgeInsets padding = EdgeInsets.symmetric(
                horizontal: landscape ? 28 : 20,
                vertical: tight ? 8 : 20,
              );

              return Padding(
                padding: padding,
                child: Column(
                  children: <Widget>[
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: widget.onComplete,
                        child: const Text('Skip'),
                      ),
                    ),
                    Expanded(
                      child: PageView.builder(
                        controller: _controller,
                        itemCount: _pages.length,
                        onPageChanged: (int value) =>
                            setState(() => _page = value),
                        itemBuilder: (BuildContext context, int index) {
                          return _OnboardingPage(data: _pages[index]);
                        },
                      ),
                    ),
                    SizedBox(height: tight ? 4 : 10),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Row(
                            children: List<Widget>.generate(
                              _pages.length,
                              (int index) => AnimatedContainer(
                                duration: const Duration(milliseconds: 220),
                                margin: const EdgeInsets.only(right: 8),
                                width: index == _page ? 28 : 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: index == _page
                                      ? AppColors.primary
                                      : AppColors.border,
                                  borderRadius: BorderRadius.circular(99),
                                ),
                              ),
                            ),
                          ),
                        ),
                        FilledButton(
                          onPressed: () {
                            if (_page == _pages.length - 1) {
                              widget.onComplete();
                            } else {
                              _controller.nextPage(
                                duration: const Duration(milliseconds: 260),
                                curve: Curves.easeOutCubic,
                              );
                            }
                          },
                          child: Text(
                              _page == _pages.length - 1 ? 'Start' : 'Next'),
                        ),
                      ],
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
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({required this.data});

  final _OnboardingPageData data;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool compact = constraints.maxHeight < 620;
        final bool landscape = constraints.maxWidth > constraints.maxHeight;
        final bool tightLandscape = landscape && constraints.maxHeight < 360;
        final double artSize = landscape
            ? (constraints.maxHeight * (tightLandscape ? 0.34 : 0.42))
                .clamp(78.0, 136.0)
            : compact
                ? 150
                : 210;
        final Widget art = Container(
          width: artSize,
          height: artSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: <Color>[
                AppColors.primary.withValues(alpha: 0.42),
                AppColors.primaryDark.withValues(alpha: 0.18),
                Colors.transparent,
              ],
            ),
          ),
          child: Center(
            child: Container(
              width: artSize * 0.72,
              height: artSize * 0.72,
              padding: EdgeInsets.all(landscape ? 14 : 22),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(landscape ? 24 : 34),
                border: Border.all(color: AppColors.border),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.26),
                    blurRadius: 46,
                  ),
                ],
              ),
              child: Icon(
                data.icon,
                color: AppColors.accentGold,
                size: landscape
                    ? 42
                    : compact
                        ? 56
                        : 78,
              ),
            ),
          ),
        );

        final Widget copy = Flexible(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 470),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    data.title,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontSize: landscape
                              ? (tightLandscape ? 22 : 28)
                              : compact
                                  ? 30
                                  : 34,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
                SizedBox(
                    height: tightLandscape
                        ? 3
                        : landscape
                            ? 6
                            : 10),
                Text(
                  data.subtitle,
                  textAlign: TextAlign.center,
                  maxLines: landscape ? 1 : null,
                  overflow: TextOverflow.fade,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.accentGold,
                      ),
                ),
                if (!tightLandscape) ...<Widget>[
                  SizedBox(height: landscape ? 10 : 18),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.surface.withValues(alpha: 0.82),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(landscape ? 14 : 18),
                      child: Text(
                        data.body,
                        textAlign: TextAlign.center,
                        maxLines: landscape ? 3 : null,
                        overflow: TextOverflow.fade,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );

        if (landscape) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              art,
              const SizedBox(width: 28),
              copy,
            ],
          );
        }

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            art,
            SizedBox(height: compact ? 20 : 34),
            copy,
          ],
        );
      },
    );
  }
}

class _OnboardingPageData {
  const _OnboardingPageData({
    required this.title,
    required this.subtitle,
    required this.body,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final String body;
  final IconData icon;
}
