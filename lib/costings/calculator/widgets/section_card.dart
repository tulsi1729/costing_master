import 'package:costing_master/costings/calculator/costing_draft.dart';
import 'package:costing_master/domain/labels.dart';
import 'package:costing_master/theme/app_theme.dart';
import 'package:costing_master/theme/motion.dart';
import 'package:costing_master/widgets/animated_amount.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A collapsible calculator section whose header shows a live subtotal.
class SectionCard extends ConsumerStatefulWidget {
  final DraftProvider draft;
  final Label label;
  final IconData icon;
  final double Function(CostingDraft) subtotal;
  final bool initiallyExpanded;
  final List<Widget> children;

  const SectionCard({
    super.key,
    required this.draft,
    required this.label,
    required this.icon,
    required this.subtotal,
    required this.children,
    this.initiallyExpanded = false,
  });

  @override
  ConsumerState<SectionCard> createState() => _SectionCardState();
}

class _SectionCardState extends ConsumerState<SectionCard> {
  late bool _expanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final subtotal = ref.watch(widget.draft.select(widget.subtotal));
    final active = subtotal != 0;
    final duration = Motion.of(context, Motion.medium);

    return Container(
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: active
              ? context.colors.primary.withValues(alpha: 0.6)
              : context.colors.outlineVariant.withValues(alpha: 0.5),
          width: active ? 1.4 : 1,
        ),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: active
                          ? context.colors.primaryContainer
                          : context.colors.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      widget.icon,
                      size: 20,
                      color: active
                          ? context.colors.onPrimaryContainer
                          : context.colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.label.gu,
                          style: context.text.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          widget.label.en,
                          style: context.text.labelSmall?.copyWith(
                              color: context.colors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  AnimatedAmount(
                    subtotal,
                    animate: false,
                    style: context.text.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: active
                          ? context.colors.onSurface
                          : context.colors.outline,
                    ),
                  ),
                  const SizedBox(width: 4),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: duration,
                    curve: Motion.emphasized,
                    child: Icon(Icons.expand_more_rounded,
                        color: context.colors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
          ClipRect(
            child: AnimatedSize(
              duration: duration,
              curve: Motion.emphasized,
              alignment: Alignment.topCenter,
              child: _expanded
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      child: Column(children: widget.children),
                    )
                  : const SizedBox(width: double.infinity),
            ),
          ),
        ],
      ),
    );
  }
}
