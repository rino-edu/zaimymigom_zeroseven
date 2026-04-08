import 'package:firebase_auth/firebase_auth.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth;

  FirebaseAuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  /// Гарантирует, что пользователь залогинен анонимно.
  /// Если уже есть currentUser — повторно не логинимся.
  Future<User> ensureAnonymousSignIn() async {
    final current = _auth.currentUser;
    if (current != null) {
      return current;
    }
    final cred = await _auth.signInAnonymously();
    final user = cred.user;
    if (user == null) {
      throw StateError('Anonymous sign-in failed: user is null');
    }
    return user;
  }
}

