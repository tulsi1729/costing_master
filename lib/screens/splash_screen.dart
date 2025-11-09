import 'dart:async';
import 'package:costing_master/auth/notifiers/auth_notifier.dart';
import 'package:costing_master/auth/screens/login.dart';
import 'package:costing_master/client/screen/client_listing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(seconds: 2));

    final authState = ref.read(authProvider);
    authState.when(
      data: (user) {
        final isAuthenticated = user != null;
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  isAuthenticated ? const ClientListing() : const LoginScreen(),
            ),
          );
        }
      },
      loading: () {
        Future.delayed(const Duration(milliseconds: 500), _navigate);
      },
      error: (_, __) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/icon/icon.png',
                fit: BoxFit.cover, height: 200),
            const SizedBox(height: 20),
            const Text(
              "Costing Master",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
