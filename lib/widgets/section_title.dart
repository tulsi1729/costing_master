import 'package:costing_master/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// A bold Gujarati heading with a quieter English line beside it.
class SectionTitle extends StatelessWidget {
  final String gu;
  final String en;
  const SectionTitle(this.gu, this.en, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
      child: Text.rich(TextSpan(children: [
        TextSpan(
            text: gu,
            style: context.text.titleMedium
                ?.copyWith(fontWeight: FontWeight.w800)),
        TextSpan(
            text: '   $en',
            style: context.text.labelMedium
                ?.copyWith(color: context.colors.onSurfaceVariant)),
      ])),
    );
  }
}
