import 'package:costing_master/theme/motion.dart';
import 'package:flutter/material.dart';

/// Fades and slides [child] in, staggered by [index]. Runs once per element.
class Entrance extends StatefulWidget {
  final int index;
  final bool enabled;
  final Widget child;

  const Entrance({
    super.key,
    required this.index,
    required this.child,
    this.enabled = true,
  });

  @override
  State<Entrance> createState() => _EntranceState();
}

class _EntranceState extends State<Entrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: Motion.medium);
  late final Animation<double> _curve =
      CurvedAnimation(parent: _controller, curve: Motion.emphasized);
  late final Animation<Offset> _slide =
      Tween(begin: const Offset(0, 0.08), end: Offset.zero).animate(_curve);
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (!widget.enabled || Motion.of(context, Motion.medium) == Duration.zero) {
      _controller.value = 1;
      return;
    }
    final delay = Duration(milliseconds: 40 * widget.index.clamp(0, 8));
    Future.delayed(delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _curve,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}
