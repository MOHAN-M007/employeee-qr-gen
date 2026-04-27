import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // 🔐 LOGIN
  static Future<User?> login(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } catch (e) {
      print("Login Error: $e");
      return null;
    }
  }

  // 🔓 LOGOUT
  static Future<void> logout() async {
    await _auth.signOut();
  }

  // 👤 CURRENT USER
  static User? get currentUser => _auth.currentUser;
}