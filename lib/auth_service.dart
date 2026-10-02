import 'package:firebase_auth/firebase_auth.dart';

class AuthResult {
  final bool success;
  final String? message;
  final Map<String, dynamic>? data;

  AuthResult({required this.success, this.message, this.data});
}

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static Future<AuthResult> login(
    String email,
    String password,
  ) async {
    if (email.trim().isEmpty || password.isEmpty) {
      return AuthResult(
        success: false,
        message: 'Please enter your email and password.',
      );
    }

    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      return AuthResult(
        success: credential.user != null,
        message: credential.user == null ? 'Login failed.' : null,
      );
    } on FirebaseAuthException catch (e) {
      String message;

      switch (e.code) {
        case 'user-not-found':
        case 'invalid-credential':
        case 'wrong-password':
          message = 'Invalid email or password.';
          break;
        case 'invalid-email':
          message = 'Please enter a valid email address.';
          break;
        case 'too-many-requests':
          message = 'Too many attempts. Please try again later.';
          break;
        case 'network-request-failed':
          message = 'Network error. Check your internet connection.';
          break;
        default:
          message = e.message ?? 'Sign-in failed.';
      }

      return AuthResult(success: false, message: message);
    } catch (_) {
      return AuthResult(
        success: false,
        message: 'Something went wrong. Please try again.',
      );
    }
  }
}
