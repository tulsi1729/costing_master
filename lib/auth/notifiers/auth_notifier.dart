import 'package:costing_master/auth/repository/auth_repository.dart';
import 'package:costing_master/model/user_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthNotifier extends AsyncNotifier<UserModel?> {
  late AuthRepository _authRepository;

  @override
  Future<UserModel?> build() async {
    _authRepository = ref.watch(authRepositoryProvider);
    return _authRepository.getCurrentUserModel();
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_authRepository.signInWithGoogle);
  }

  Future<void> logOut() async {
    await _authRepository.logOut();
    state = const AsyncData(null);
  }
}

final authProvider =
    AsyncNotifierProvider<AuthNotifier, UserModel?>(AuthNotifier.new);
