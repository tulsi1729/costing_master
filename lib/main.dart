import 'package:costing_master/auth/notifiers/auth_notifier.dart';
import 'package:costing_master/auth/screens/login.dart';
import 'package:costing_master/client/screen/client_listing.dart';
import 'package:costing_master/common/extension/async_value.dart';
import 'package:costing_master/loading/loading_notifier.dart';
import 'package:costing_master/loading/loading_wrapper.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(authProvider).whenWidget(
      (user) {
        bool isAuthanticated = user != null;
        bool isLoading = ref.watch(loadingProvider);

        return MaterialApp(
          home: isAuthanticated
              ? Stack(
                  children: [
                    const ClientListing(),
                    isLoading ? const LoadingWrapper() : Container()
                  ],
                )
              : const LoginScreen(),
        );
      },
    );
  }
}
