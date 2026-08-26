import 'package:flutter/material.dart';

class SkeletonLoader extends StatefulWidget {
  const SkeletonLoader({
    this.height = 18,
    this.width,
    this.borderRadius = 10,
    super.key,
  });

  final double height;
  final double? width;
  final double borderRadius;

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _controller,
        builder: (BuildContext context, Widget? child) {
          final double value = _controller.value;
          return Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              gradient: LinearGradient(
                begin: Alignment(-1.5 + value * 3, 0),
                end: Alignment(-.5 + value * 3, 0),
                colors: const <Color>[
                  Color(0xFF10283B),
                  Color(0xFF23465E),
                  Color(0xFF10283B),
                ],
              ),
            ),
          );
        },
      );
}

class SkeletonPage extends StatelessWidget {
  const SkeletonPage({this.rows = 5, super.key});

  final int rows;

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: rows,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (_, int index) => Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xA6081C2B),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF17384F)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SkeletonLoader(height: 20, width: index.isEven ? 190 : 145),
                const SizedBox(height: 12),
                const SkeletonLoader(height: 13),
                const SizedBox(height: 8),
                const SkeletonLoader(height: 13, width: 240),
              ],
            ),
          ),
        ),
      );
}
