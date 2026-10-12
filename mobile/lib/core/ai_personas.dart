import 'package:flutter/material.dart';

import 'ai_bot_preset_store.dart';

class AiPersona {
  const AiPersona({
    required this.name,
    required this.tagline,
    required this.rating,
    required this.style,
    required this.icon,
    required this.accent,
    required this.backgroundAsset,
  });

  final String name;
  final String tagline;
  final int rating;
  final AiBotStyle style;
  final IconData icon;
  final Color accent;
  final String backgroundAsset;
}

const List<AiPersona> aiPersonas = <AiPersona>[
  AiPersona(
    name: 'Nova the Tactician',
    tagline: 'Sharp attacks · 1400 rating',
    rating: 1400,
    style: AiBotStyle.aggressive,
    icon: Icons.bolt_rounded,
    accent: Color(0xFFFF5B45),
    backgroundAsset: 'assets/backgrounds/home-computer-hero-v1.webp',
  ),
  AiPersona(
    name: 'Sage the Strategist',
    tagline: 'Calm positional play · 1800 rating',
    rating: 1800,
    style: AiBotStyle.balanced,
    icon: Icons.auto_awesome_rounded,
    accent: Color(0xFF9B7BFF),
    backgroundAsset: 'assets/backgrounds/home-puzzles-hero-v1.webp',
  ),
  AiPersona(
    name: 'Onyx the Guardian',
    tagline: 'Solid defence · 2200 rating',
    rating: 2200,
    style: AiBotStyle.defensive,
    icon: Icons.shield_rounded,
    accent: Color(0xFF8B9BAA),
    backgroundAsset: 'assets/backgrounds/home-analysis-hero-v1.webp',
  ),
  AiPersona(
    name: 'Mira the Mentor',
    tagline: 'Friendly beginner practice · 900 rating',
    rating: 900,
    style: AiBotStyle.balanced,
    icon: Icons.school_rounded,
    accent: Color(0xFF55D6C2),
    backgroundAsset: 'assets/backgrounds/home-learn-hero-v1.webp',
  ),
];
