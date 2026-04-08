import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/combat_onboarding_config.dart';
import '../models/combat_onboarding_theme.dart';
import '../models/combat_onboarding_user_payload.dart';

class CombatOnboardingFirestoreService {
  final FirebaseFirestore _firestore;

  CombatOnboardingFirestoreService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<CombatOnboardingConfig> fetchConfigWithOneRetry() async {
    try {
      return await fetchConfig();
    } catch (_) {
      return await fetchConfig();
    }
  }

  Future<CombatOnboardingConfig> fetchConfig() async {
    final onboardingCol = _firestore.collection('onboarding');

    final snapshot = await onboardingCol.get();
    final byId = <String, Map<String, dynamic>>{};
    for (final doc in snapshot.docs) {
      byId[doc.id] = doc.data();
    }

    final startData = byId['start'] ?? const <String, dynamic>{};
    final theme = CombatOnboardingTheme.fromMap(
      (startData['theme'] as Map?)?.cast<String, dynamic>(),
    );
    final start = CombatOnboardingStartConfig(
      title: (startData['title'] as String?) ??
          'Поможем подобрать займ с максимальным шансом одобрения на лучших условиях для вашей ситуации.',
      body: (startData['body'] as String?) ?? 'Ответьте анонимно на 5 коротких вопросов.',
      primaryButtonText: (startData['primaryButtonText'] as String?) ?? 'Начать',
      theme: theme,
    );

    final pages = <CombatOnboardingQuestionPageConfig>[];
    for (final entry in byId.entries) {
      final id = entry.key;
      final match = RegExp(r'^page(\d+)$').firstMatch(id);
      if (match == null) continue;
      final num = int.tryParse(match.group(1) ?? '');
      if (num == null) continue;

      final data = entry.value;
      final question = (data['question'] as String?) ?? 'Вопрос';
      final rawOptions = (data['options'] as List?)?.map((e) => e.toString()).toList() ?? const <String>[];
      final options = _normalizeOptions(rawOptions);

      pages.add(
        CombatOnboardingQuestionPageConfig(
          docId: id,
          pageNumber: num,
          question: question,
          options: options,
        ),
      );
    }
    pages.sort((a, b) => a.pageNumber.compareTo(b.pageNumber));

    final finalData = byId['final'] ?? const <String, dynamic>{};
    final finalStep = CombatOnboardingFinalConfig(
      title: (finalData['title'] as String?) ?? 'Введите номер телефона',
      body: (finalData['body'] as String?) ?? 'Чтобы получить персональное предложение по займу,',
      primaryButtonText: (finalData['primaryButtonText'] as String?) ?? 'Продолжить',
      consentText: (finalData['consentText'] as String?) ??
          'Согласен(а) на обработку персональных данных',
    );

    CombatOnboardingAnimationConfig parseAnim(String id, String defaultTitle) {
      final data = byId[id] ?? const <String, dynamic>{};
      final title = (data['title'] as String?) ?? defaultTitle;
      final duration = (data['durationSeconds'] as num?)?.toInt() ?? 2;
      return CombatOnboardingAnimationConfig(
        title: title,
        durationSeconds: duration <= 0 ? 2 : duration,
      );
    }

    final animation1 = parseAnim('animation1', 'Подбираем предложения…');
    final animation2 = parseAnim('animation2', 'Почти готово…');

    return CombatOnboardingConfig(
      start: start,
      pagesSorted: pages,
      finalStep: finalStep,
      animation1: animation1,
      animation2: animation2,
    );
  }

  Future<void> upsertUser(CombatOnboardingUserPayload payload) async {
    await _firestore
        .collection('users')
        .doc(payload.id)
        .set(payload.toFirestoreMap(), SetOptions(merge: true));
  }

  static List<String> _normalizeOptions(List<String> raw) {
    final options = <String>[];
    for (final s in raw) {
      final v = s.trim();
      if (v.isNotEmpty) options.add(v);
      if (options.length == 4) break;
    }
    while (options.length < 4) {
      options.add('Вариант ${options.length + 1}');
    }
    return options;
  }
}

