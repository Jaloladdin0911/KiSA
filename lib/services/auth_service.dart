import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // Lazy getter — Firebase yo'q bo'lsa null qaytaradi, crash bo'lmaydi
  FirebaseAuth? get _auth {
    try {
      return FirebaseAuth.instance;
    } catch (_) {
      return null;
    }
  }

  User? get currentUser => _auth?.currentUser;
  String get userId => _auth?.currentUser?.uid ?? 'local_user';
  bool get isLoggedIn => _auth?.currentUser != null;

  Stream<User?> get authStateChanges =>
      _auth?.authStateChanges() ?? const Stream.empty();

  // ─── EMAIL / PAROL ────────────────────────────────────────────────────────

  Future<UserCredential?> signUp({
    required String email,
    required String password,
  }) async {
    final auth = _auth;
    if (auth == null) throw 'Firebase mavjud emas';
    try {
      return await auth.createUserWithEmailAndPassword(
          email: email, password: password);
    } on FirebaseAuthException catch (e) {
      throw _authError(e.code);
    }
  }

  Future<UserCredential?> signIn({
    required String email,
    required String password,
  }) async {
    final auth = _auth;
    if (auth == null) throw 'Firebase mavjud emas';
    try {
      return await auth.signInWithEmailAndPassword(
          email: email, password: password);
    } on FirebaseAuthException catch (e) {
      throw _authError(e.code);
    }
  }

  Future<void> signOut() async {
    await _auth?.signOut();
  }

  /// Akkauntni butunlay o'chiradi (Apple App Store talabi 5.1.1(v)).
  /// Sessiya eski bo'lsa Firebase qayta kirishni talab qiladi.
  Future<void> deleteAccount() async {
    final user = _auth?.currentUser;
    if (user == null) throw 'Akkaunt topilmadi';
    try {
      await user.delete();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw 'reauth';
      }
      throw _authError(e.code);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_name');
  }

  Future<void> resetPassword(String email) async {
    await _auth?.sendPasswordResetEmail(email: email);
  }

  // ─── DISPLAY NAME ─────────────────────────────────────────────────────────

  Future<void> updateDisplayName(String name) async {
    await _auth?.currentUser?.updateDisplayName(name);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', name);
  }

  String get displayName {
    final fromFirebase = _auth?.currentUser?.displayName;
    if (fromFirebase != null && fromFirebase.isNotEmpty) return fromFirebase;
    // SharedPreferences'dan sinxron o'qib bo'lmaydi — fallback
    return 'Foydalanuvchi';
  }

  // ─── XATO XABARLARI ───────────────────────────────────────────────────────

  String _authError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return "Bu email allaqachon ro'yxatdan o'tgan";
      case 'invalid-email':
        return "Email noto'g'ri formatda";
      case 'weak-password':
        return 'Parol kamida 6 ta belgi bo\'lishi kerak';
      case 'user-not-found':
        return 'Foydalanuvchi topilmadi';
      case 'wrong-password':
        return "Parol noto'g'ri";
      case 'too-many-requests':
        return "Ko'p urinish. Keyinroq qaytadan urining";
      default:
        return 'Xato yuz berdi. Qaytadan urining';
    }
  }
}
