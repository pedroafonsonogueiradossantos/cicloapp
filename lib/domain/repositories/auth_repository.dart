
class AuthCancelledException implements Exception {}

abstract class AuthRepository {
  Stream<bool> get authStateChanges;

  bool get isSignedIn;

  Future<void> signInWithGoogle();

  Future<void> signOut();
}