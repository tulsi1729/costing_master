import 'package:costing_master/auth/repository/auth_repository.dart';
import 'package:costing_master/model/user_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthNotifier extends AsyncNotifier<UserModel?> {
  late final AuthRepository _authRepository;

  @override
  Future<UserModel?> build() async {
    _authRepository = ref.watch(authRepositoryProvider);
    return getUserModel();
  }

    Future<UserModel?> getUserModel() async {
    final user = _authRepository.currentUser;
    if (user == null) return null;

    return await _authRepository.getUserData(user.uid).first;
  }

 Future<void> signInWithGoogle(bool isFromLogin) async {
    state = const AsyncValue.loading();
    final userModel = await _authRepository.signInWithGoogle(isFromLogin);
    state = AsyncValue.data(userModel);
  }

  Future<void> logOut() async {
    await _authRepository.logOut();
    state = const AsyncValue.data(null);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    final UserModel? userModel = await getUserModel();
    state = AsyncData(userModel);
  }
}

final authProvider =
    AsyncNotifierProvider<AuthNotifier, UserModel?>(AuthNotifier.new);
