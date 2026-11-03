import 'package:costing_master/auth/notifiers/auth_notifier.dart';
import 'package:costing_master/connectivity/notifier/connectivity_notifier.dart';
import 'package:costing_master/theme/app_theme.dart';
import 'package:costing_master/theme/motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SignInButton extends ConsumerWidget {
  const SignInButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final online =
        ref.watch(connectivityProvider.select((state) => state.value ?? true));
    final loading = ref.watch(authProvider.select((s) => s.isLoading));

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: online && !loading
                ? () => ref.read(authProvider.notifier).signInWithGoogle()
                : null,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF1F1F1F),
              disabledBackgroundColor: Colors.white.withValues(alpha: 0.6),
              minimumSize: const Size.fromHeight(56),
            ),
            child: AnimatedSwitcher(
              duration: Motion.of(context, Motion.fast),
              child: loading
                  ? SizedBox.square(
                      key: const ValueKey('loading'),
                      dimension: 24,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: context.brand.heroStart),
                    )
                  : const Row(
                      key: ValueKey('label'),
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _GoogleG(),
                        SizedBox(width: 12),
                        Text('Google થી બેકઅપ ચાલુ કરો'),
                      ],
                    ),
            ),
          ),
        ),
        AnimatedSize(
          duration: Motion.of(context, Motion.medium),
          child: online
              ? const SizedBox(width: double.infinity)
              : const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.wifi_off_rounded,
                          color: Colors.white70, size: 18),
                      SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'બેકઅપ માટે ઇન્ટરનેટ જરૂરી છે',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}

class _GoogleG extends StatelessWidget {
  const _GoogleG();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'G',
      style: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w900,
        color: Color(0xFF4285F4),
      ),
    );
  }
}
