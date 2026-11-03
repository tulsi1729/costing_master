import 'package:flutter/material.dart';

enum SnackType { info, success, error }

void showAppSnack(
  BuildContext context,
  String message, {
  SnackType type = SnackType.info,
  SnackBarAction? action,
}) {
  final scheme = Theme.of(context).colorScheme;
  final (icon, background, foreground) = switch (type) {
    SnackType.success => (
        Icons.check_circle_rounded,
        const Color(0xFF1B5E20),
        Colors.white
      ),
    SnackType.error => (Icons.error_rounded, scheme.error, scheme.onError),
    SnackType.info => (
        Icons.info_rounded,
        scheme.inverseSurface,
        scheme.onInverseSurface
      ),
  };
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        backgroundColor: background,
        action: action,
        content: Row(
          children: [
            Icon(icon, color: foreground, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message, style: TextStyle(color: foreground)),
            ),
          ],
        ),
      ),
    );
}
