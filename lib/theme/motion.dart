import 'package:flutter/widgets.dart';

/// Shared animation timings so motion feels consistent across the app.
abstract final class Motion {
  static const fast = Duration(milliseconds: 180);
  static const medium = Duration(milliseconds: 320);
  static const slow = Duration(milliseconds: 400);

  static const emphasized = Cubic(0.2, 0, 0, 1);
  static const decelerate = Curves.easeOutCubic;

  /// Returns [duration], or zero when the user asked the OS to reduce motion.
  static Duration of(BuildContext context, Duration duration) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false
          ? Duration.zero
          : duration;
}
