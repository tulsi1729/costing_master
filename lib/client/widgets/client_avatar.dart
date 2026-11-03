import 'package:costing_master/settings/app_settings.dart';
import 'package:flutter/material.dart';

/// A client's initials on a soft colour picked from their name, so each
/// client keeps the same colour everywhere.
class ClientAvatar extends StatelessWidget {
  final String name;
  final double radius;

  const ClientAvatar({super.key, required this.name, this.radius = 24});

  @override
  Widget build(BuildContext context) {
    final color =
        quoteAccents[name.trim().hashCode.abs() % quoteAccents.length];
    // A Gujarati letter carries its vowel signs and conjuncts, so two of
    // them read like a broken syllable; one is cleaner. Latin names get two.
    final latin = RegExp(r'^[A-Za-z]').hasMatch(name.trim());
    final initials = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .take(latin ? 2 : 1)
        .map((w) => w.characters.first.toUpperCase())
        .join();
    return CircleAvatar(
      radius: radius,
      backgroundColor: color.withValues(alpha: 0.15),
      child: initials.isEmpty
          ? Icon(Icons.person_outline_rounded, color: color, size: radius)
          : Text(
              initials,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: radius * 0.7,
              ),
            ),
    );
  }
}
