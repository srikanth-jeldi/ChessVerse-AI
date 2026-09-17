import 'package:flutter/material.dart';

/// A readable next-step card with one tap target and a trailing direction cue.
class AcademyContinueButton extends StatelessWidget {
  const AcademyContinueButton({
    required this.label,
    required this.title,
    required this.onPressed,
    this.isLastLesson = false,
    super.key,
  });

  final String label;
  final String title;
  final VoidCallback onPressed;
  final bool isLastLesson;

  @override
  Widget build(BuildContext context) => FilledButton(
    onPressed: onPressed,
    style: FilledButton.styleFrom(
      backgroundColor: const Color(0xFFF0C66A),
      foregroundColor: const Color(0xFF071827),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      minimumSize: const Size.fromHeight(88),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFFFDF95)),
      ),
    ),
    child: Row(
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.3,
                  fontWeight: FontWeight.w600,
                  letterSpacing: .8,
                  color: Color(0xFF5B451D),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                title,
                textAlign: TextAlign.start,
                style: const TextStyle(
                  fontSize: 17,
                  height: 1.25,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0x16071827),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(
            isLastLesson ? Icons.school_rounded : Icons.arrow_forward_rounded,
            size: 23,
          ),
        ),
      ],
    ),
  );
}
