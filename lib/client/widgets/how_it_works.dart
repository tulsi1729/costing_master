import 'package:costing_master/theme/app_theme.dart';
import 'package:flutter/material.dart';

const _steps = [
  (Icons.person_add_alt_1_rounded, 'વેપારી ઉમેરો'),
  (Icons.calculate_outlined, 'કોસ્ટિંગ કરો'),
  (Icons.send_rounded, 'WhatsApp કરો'),
];

/// The app in three steps, shown until the first costing is saved.
class HowItWorks extends StatelessWidget {
  const HowItWorks({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final (i, (icon, label)) in _steps.indexed) ...[
          if (i > 0)
            Icon(Icons.chevron_right_rounded,
                size: 18, color: context.colors.outline),
          Expanded(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: context.colors.primaryContainer,
                  foregroundColor: context.colors.onPrimaryContainer,
                  child: Icon(icon, size: 18),
                ),
                const SizedBox(height: 6),
                Text(
                  '${i + 1}. $label',
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: context.text.labelMedium,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
