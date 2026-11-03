import 'package:costing_master/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// A softly pulsing placeholder shown while content loads.
class Skeleton extends StatefulWidget {
  final double? width;
  final double? height;
  final BorderRadius borderRadius;

  const Skeleton({
    super.key,
    this.width,
    this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
  });

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
    lowerBound: 0.45,
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: context.colors.surfaceContainerHighest,
          borderRadius: widget.borderRadius,
        ),
      ),
    );
  }
}
