import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../services/appmetrica_service.dart';
import '../models/combat_onboarding_user_payload.dart';
import 'combat_onboarding_firestore_service.dart';
import 'combat_onboarding_local_state.dart';
import 'installation_id_service.dart';

class CombatOnboardingUserWriter {
  final CombatOnboardingFirestoreService _firestore;
  final InstallationIdService _installationIdService;
  final CombatOnboardingLocalState _localState;

  CombatOnboardingUserWriter({
    CombatOnboardingFirestoreService? firestore,
    InstallationIdService? installationIdService,
    CombatOnboardingLocalState? localState,
  })  : _firestore = firestore ?? CombatOnboardingFirestoreService(),
        _installationIdService = installationIdService ?? InstallationIdService(),
        _localState = localState ?? CombatOnboardingLocalState();

  Future<void> writeNotShownIfFirstOpen({required bool isFirstOpen}) async {
    if (!isFirstOpen) return;

    final id = await _installationIdService.getUserId();
    final appmetricaId = await AppMetricaService.getDeviceIdHash();
    final firstOpenDate = await _localState.getOrSetFirstOpenDate();

    final payload = CombatOnboardingUserPayload(
      id: id,
      phone: null,
      appmetricaId: appmetricaId,
      firstOpenDate: firstOpenDate,
      endOnbord: false,
      lastOnbordpage: 'Not shown',
      answersOnbord: const {},
    );

    // ignore: avoid_print
    debugPrint(
      'CombatOnboardingUserWriter: writeNotShown userId=$id firstOpenDate=$firstOpenDate',
    );
    await _firestore.upsertUser(payload);
    // ignore: avoid_print
    debugPrint('CombatOnboardingUserWriter: writeNotShown success userId=$id');
  }

  Future<void> writeResult({
    required bool endOnbord,
    required String lastOnbordpage,
    required Map<String, String> answersOnbord,
    required String? phone,
  }) async {
    final id = await _installationIdService.getUserId();
    final appmetricaId = await AppMetricaService.getDeviceIdHash();
    final firstOpenDate = await _localState.getOrSetFirstOpenDate();

    final payload = CombatOnboardingUserPayload(
      id: id,
      phone: phone,
      appmetricaId: appmetricaId,
      firstOpenDate: firstOpenDate,
      endOnbord: endOnbord,
      lastOnbordpage: lastOnbordpage,
      answersOnbord: answersOnbord,
    );

    // ignore: avoid_print
    debugPrint(
      'CombatOnboardingUserWriter: writeResult start userId=$id endOnbord=$endOnbord lastOnbordpage=$lastOnbordpage phoneSet=${phone != null} answers=${answersOnbord.length}',
    );
    await _firestore
        .upsertUser(payload)
        .timeout(const Duration(seconds: 10), onTimeout: () {
      throw TimeoutException('upsertUser timeout');
    });
    // ignore: avoid_print
    debugPrint('CombatOnboardingUserWriter: writeResult success userId=$id');
  }
}

