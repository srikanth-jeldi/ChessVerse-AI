import 'package:flutter/material.dart';

/// Remote profile pictures are optional; an offline/expired image keeps initials.
class PlayerAvatar extends StatelessWidget {
  const PlayerAvatar({
    super.key,
    this.photoUrl,
    required this.name,
    this.radius = 20,
    this.backgroundColor,
  });

  final String? photoUrl;
  final String name;
  final double radius;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final url = photoUrl?.trim() ?? '';
    final uri = Uri.tryParse(url);
    final valid =
        uri != null &&
        uri.host.isNotEmpty &&
        (uri.scheme == 'https' || uri.scheme == 'http');
    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor,
      foregroundImage: valid ? NetworkImage(url) : null,
      onForegroundImageError: valid ? (_, _) {} : null,
      child: Text(
        name.trim().isEmpty ? '?' : name.trim().characters.first.toUpperCase(),
        style: TextStyle(fontSize: radius * 0.7, fontWeight: FontWeight.w700),
      ),
    );
  }
}
