class CombatOnboardingUserPayload {
  final String id;
  final String? phone;
  final String appmetricaId;
  final DateTime firstOpenDate;
  final bool endOnbord;
  final String lastOnbordpage;
  final Map<String, String> answersOnbord;

  const CombatOnboardingUserPayload({
    required this.id,
    required this.phone,
    required this.appmetricaId,
    required this.firstOpenDate,
    required this.endOnbord,
    required this.lastOnbordpage,
    required this.answersOnbord,
  });

  Map<String, dynamic> toFirestoreMap() {
    final map = <String, dynamic>{
      'id': id,
      'appmetricaId': appmetricaId,
      'firstOpenDate': firstOpenDate,
      'endOnbord': endOnbord,
      'lastOnbordpage': lastOnbordpage,
      'answersOnbord': answersOnbord,
    };
    if (phone != null) {
      map['phone'] = phone;
    }
    return map;
  }
}

