import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import '../providers/auth_provider.dart';


final authControllerProvider = StateNotifierProvider<AuthController, AsyncValue<void>>((ref) {
  return AuthController(ref);
});
class AuthController extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;


  AuthController(this._ref) : super(const AsyncData(null));

  AuthService get _service => _ref.read(authServiceProvider);

  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    try {
      await _service.login(email, password);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> register(String email, String password, String displayName) async {
    state = const AsyncLoading();
    try {
      await _service.register(email, password, displayName);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> logout() async {
    await _service.logout();
  }
}
