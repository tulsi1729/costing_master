import 'package:costing_master/auth/notifiers/auth_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SignInButton extends ConsumerWidget {
  final bool isFromLogin;

  const SignInButton({super.key, this.isFromLogin = true});

  void signINWithGoogle(BuildContext context, WidgetRef ref) {
    ref.read(authProvider.notifier).signInWithGoogle(isFromLogin);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: ElevatedButton(
        onPressed: () => signINWithGoogle(context, ref),
        child: Text("Sign in Google"),
      ),
    );
  }
}
