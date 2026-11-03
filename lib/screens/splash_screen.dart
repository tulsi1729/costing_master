import 'dart:async';

import 'package:costing_master/client/screen/client_listing.dart';
import 'package:costing_master/settings/settings_notifier.dart';
import 'package:costing_master/theme/app_theme.dart';
import 'package:costing_master/widgets/brand_mark.dart';
import 'package:costing_master/widgets/network_thumb.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Plays the brand animation, then opens the clients home. There is no
/// login step: backup with Google is offered later, from inside the app.
///
/// Once the business has uploaded its logo, it joins the mark after the
/// animation, side by side like a collaboration.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  /// The mark's animation plus a beat to see it finished.
  static const _minimumShowTime = Duration(milliseconds: 2500);

  /// Extra time for the business logo to arrive and be seen.
  static const _collabShowTime = Duration(milliseconds: 500);

  bool _collab = false;
  Timer? _collabTimer;

  @override
  void initState() {
    super.initState();
    _collabTimer = Timer(BrandMark.animationDuration, () {
      if (mounted) setState(() => _collab = true);
    });
    _route();
  }

  @override
  void dispose() {
    _collabTimer?.cancel();
    super.dispose();
  }

  String get _logo => ref.read(settingsProvider).value?.profile.logoUrl ?? '';

  Future<void> _route() async {
    await Future<void>.delayed(_minimumShowTime);
    if (mounted && _logo.isNotEmpty) {
      await Future<void>.delayed(_collabShowTime);
    }
    if (!mounted) return;
    Navigator.of(context).pushReplacement(PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (_, __, ___) => const ClientListing(),
      transitionsBuilder: (_, animation, __, child) =>
          FadeTransition(opacity: animation, child: child),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(settingsProvider).value?.profile;
    final logo = profile?.logoUrl ?? '';
    final businessName = profile?.businessName.trim() ?? '';
    final collab = _collab && logo.isNotEmpty;
    const reveal = Duration(milliseconds: 550);

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(gradient: context.brand.heroGradient),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Hero(
                      tag: 'brand-mark',
                      child: BrandMark(size: 132, animate: true)),
                  if (collab)
                    // The partner's side widens from nothing, so the
                    // centred mark glides left to make room.
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: reveal,
                      curve: Curves.easeOutCubic,
                      builder: (context, width, child) => Align(
                        alignment: Alignment.centerLeft,
                        widthFactor: width,
                        child: child,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(width: 16),
                          const _Reveal(
                            duration: reveal,
                            child: Text(
                              '×',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w300,
                                color: brandGold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          _Reveal(
                            duration: reveal,
                            delay: const Duration(milliseconds: 150),
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: brandGold,
                              ),
                              child: ClipOval(
                                child: SizedBox.square(
                                  dimension: 104,
                                  child: NetworkThumb(url: logo),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              const _FadeIn(
                delay: Duration(milliseconds: 1300),
                child: BrandWordmark(color: Colors.white),
              ),
              if (collab && businessName.isNotEmpty)
                _Reveal(
                  duration: reveal,
                  delay: const Duration(milliseconds: 300),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      '× $businessName',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: brandGold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Fades and scales its child in once, after [delay].
class _Reveal extends StatelessWidget {
  final Duration duration;
  final Duration delay;
  final Widget child;

  const _Reveal({
    required this.duration,
    this.delay = Duration.zero,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final total = duration + delay;
    final start = delay.inMicroseconds / total.inMicroseconds;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: total,
      curve: Interval(start, 1, curve: Curves.easeOutBack),
      builder: (context, t, child) => Opacity(
        opacity: t.clamp(0.0, 1.0),
        child: Transform.scale(scale: 0.6 + 0.4 * t, child: child),
      ),
      child: child,
    );
  }
}

class _FadeIn extends StatefulWidget {
  final Duration delay;
  final Widget child;
  const _FadeIn({required this.delay, required this.child});

  @override
  State<_FadeIn> createState() => _FadeInState();
}

class _FadeInState extends State<_FadeIn> {
  bool _visible = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.delay, () => setState(() => _visible = true));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      offset: _visible ? Offset.zero : const Offset(0, 0.2),
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
      child: AnimatedOpacity(
        opacity: _visible ? 1 : 0,
        duration: const Duration(milliseconds: 450),
        child: widget.child,
      ),
    );
  }
}
