/// Нормализация телефона для LeadGid Universal API.
///
/// В API передаётся номер с кодом оператора без ведущей «7» страны,
/// например `9119100002` (max 15 символов по схеме).
class LeadGidPhoneFormatter {
  LeadGidPhoneFormatter._();

  /// Из нормализованного РФ номера `+7XXXXXXXXXX` → `9XXXXXXXXX` (10 цифр).
  static String? toApiPhone(String normalizedRuPhone) {
    final digits = normalizedRuPhone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length != 11 || !digits.startsWith('7')) {
      return null;
    }
    final withoutCountry = digits.substring(1);
    if (withoutCountry.length != 10) {
      return null;
    }
    return withoutCountry;
  }
}
