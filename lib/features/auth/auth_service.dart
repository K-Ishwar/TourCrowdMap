import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<User?> get userChanges => _auth.userChanges();

  Future<UserCredential> signInWithEmailPassword(
    String email,
    String password,
  ) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<UserCredential> registerWithEmailPassword(
    String email,
    String password,
  ) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<UserCredential> signInWithGoogle() async {
    // For web, we use signInWithPopup.
    // For mobile, we would need google_sign_in package configuration.
    // Assuming Web primarily as per request.
    GoogleAuthProvider googleProvider = GoogleAuthProvider();
    googleProvider.addScope('email');
    googleProvider.setCustomParameters({'login_hint': 'user@example.com'});

    if (kIsWeb) {
      return await _auth.signInWithPopup(googleProvider);
    } else {
      // Fallback or error for now if not web specific setup
      throw UnimplementedError(
        'Google Sign In only implemented for Web in this step',
      );
    }
  }
}
