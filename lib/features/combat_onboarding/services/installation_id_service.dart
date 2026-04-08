import 'package:firebase_app_installations/firebase_app_installations.dart';
import 'package:firebase_auth/firebase_auth.dart';

class InstallationIdService {
  /// Возвращает userId для Firestore документа.
  ///
  /// После включения анонимного Firebase Auth используем UID, чтобы
  /// можно было безопасно ограничить доступ правилами:
  /// `request.auth.uid == userId`.
  Future<String> getUserId() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) return user.uid;
    // fallback (на случай, если кто-то вызовет до авторизации)
    return FirebaseInstallations.instance.getId();
  }

  /// Installation ID можно сохранить в поле, если нужно.
  Future<String> getInstallationId() => FirebaseInstallations.instance.getId();
}

