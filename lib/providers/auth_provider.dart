import 'package:flutter/foundation.dart';

import '../domain/repositories/auth_repository.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._authRepository) {
    _authRepository.authStateChanges.listen(_onAuthStateChanged);
  }

  final AuthRepository _authRepository;

  AuthStatus status = AuthStatus.unknown;
  String? errorMessage;
  bool isLoading = false;

  void _onAuthStateChanged(bool signedIn) {
    status = signedIn ? AuthStatus.authenticated : AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<bool> signInWithGoogle() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      await _authRepository.signInWithGoogle();
      return true;
    } on AuthCancelledException {
      errorMessage = 'Login cancelado.';
      return false;
    } catch (e) {
      errorMessage = 'Falha ao entrar: $e';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _authRepository.signOut();
  }
}
