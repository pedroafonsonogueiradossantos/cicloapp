import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../domain/repositories/auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({GoogleSignIn? googleSignIn}) : _googleSignIn = googleSignIn ?? GoogleSignIn();

  final GoogleSignIn _googleSignIn;

  @override
  Stream<bool> get authStateChanges =>
      FirebaseAuth.instance.authStateChanges().map((user) => user != null);

  @override
  bool get isSignedIn => FirebaseAuth.instance.currentUser != null;

  @override
  Future<void> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) throw AuthCancelledException();

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    await FirebaseAuth.instance.signInWithCredential(credential);
  }

  @override
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await FirebaseAuth.instance.signOut();
  }
}
