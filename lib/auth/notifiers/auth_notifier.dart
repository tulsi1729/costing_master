import 'package:costing_master/auth/repository/auth_repository.dart';
import 'package:costing_master/model/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthNotifier extends AsyncNotifier<UserModel?> {
  late final AuthRepository _authRepository;

  @override
  Future<UserModel?> build() async {
    _authRepository = ref.watch(authRepositoryProvider);
    return getUserModel();
  }

  Future<UserModel?> getUserModel() async {
    final authStream = _authRepository.authStateChange;
    final User? user = await authStream.first;
    if (user == null) {
      return null;
    }

    return await _authRepository.signInWithGoogle(true);
  }

  void signInWithGoogle(bool isFromLogin) async {
    final userModel = await _authRepository.signInWithGoogle(isFromLogin);
    state = AsyncValue.data(userModel);
  }

  void logOut() async {
    _authRepository.logOut();
    await ref.read(authProvider.notifier).refresh();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    final UserModel? userModel = await getUserModel();
    state = AsyncData(userModel);
  }
}

final authProvider =
    AsyncNotifierProvider<AuthNotifier, UserModel?>(AuthNotifier.new);
