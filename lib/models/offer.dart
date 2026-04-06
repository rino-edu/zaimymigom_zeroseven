/// Модель оффера из Firebase Firestore
/// Коллекции: boy_offers_[код региона] и vpn_offers
class Offer {
  final int id;
  final bool isShow;
  final String link;
  final String image;
  final String buttonText;
  final String name;
  final String stars; // строка, чтобы поддерживать дробные числа
  final String? field1Name;
  final String? field1Value;
  final String? field2Name;
  final String? field2Value;
  final String? field3Name;
  final String? field3Value;
  final String? field4Name;
  final String? field4Value;
  final String? field5Name;
  final String? field5Value;
  final String? field6Name;
  final String? field6Value;
  final String? field7Name;
  final String? field7Value;
  final String? field8Name;
  final String? field8Value;

  /// Цвет фона бейджа (hex, с `#` или без)
  final String? backgroundColorBadgeText;
  /// Текст на бейдже
  final String? badgeText;
  /// Цвет бордера карточки (hex, с `#` или без)
  final String? borderColorOffer;

  Offer({
    required this.id,
    required this.isShow,
    required this.link,
    required this.image,
    required this.buttonText,
    required this.name,
    required this.stars,
    this.field1Name,
    this.field1Value,
    this.field2Name,
    this.field2Value,
    this.field3Name,
    this.field3Value,
    this.field4Name,
    this.field4Value,
    this.field5Name,
    this.field5Value,
    this.field6Name,
    this.field6Value,
    this.field7Name,
    this.field7Value,
    this.field8Name,
    this.field8Value,
    this.backgroundColorBadgeText,
    this.badgeText,
    this.borderColorOffer,
  });

  /// Создание объекта из документа Firestore
  factory Offer.fromFirestore(Map<String, dynamic> data, String documentId) {
    return Offer(
      id: data['id'] as int? ?? 0,
      isShow: data['is_show'] as bool? ?? false,
      link: data['link'] as String? ?? '',
      image: data['image'] as String? ?? '',
      buttonText: data['button_text'] as String? ?? '',
      name: data['name'] as String? ?? '',
      stars: data['stars']?.toString() ?? '0',
      field1Name: data['field_1_name'] as String?,
      field1Value: data['field_1_value'] as String?,
      field2Name: data['field_2_name'] as String?,
      field2Value: data['field_2_value'] as String?,
      field3Name: data['field_3_name'] as String?,
      field3Value: data['field_3_value'] as String?,
      field4Name: data['field_4_name'] as String?,
      field4Value: data['field_4_value'] as String?,
      field5Name: data['field_5_name'] as String?,
      field5Value: data['field_5_value'] as String?,
      field6Name: data['field_6_name'] as String?,
      field6Value: data['field_6_value'] as String?,
      field7Name: data['field_7_name'] as String?,
      field7Value: data['field_7_value'] as String?,
      field8Name: data['field_8_name'] as String?,
      field8Value: data['field_8_value'] as String?,
      backgroundColorBadgeText:
          data['background_color_badge_text']?.toString(),
      badgeText: data['badge_text']?.toString(),
      borderColorOffer: data['border_color_offer']?.toString(),
    );
  }

  /// Преобразование объекта в Map для Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'is_show': isShow,
      'link': link,
      'image': image,
      'button_text': buttonText,
      'name': name,
      'stars': stars,
      if (field1Name != null) 'field_1_name': field1Name,
      if (field1Value != null) 'field_1_value': field1Value,
      if (field2Name != null) 'field_2_name': field2Name,
      if (field2Value != null) 'field_2_value': field2Value,
      if (field3Name != null) 'field_3_name': field3Name,
      if (field3Value != null) 'field_3_value': field3Value,
      if (field4Name != null) 'field_4_name': field4Name,
      if (field4Value != null) 'field_4_value': field4Value,
      if (field5Name != null) 'field_5_name': field5Name,
      if (field5Value != null) 'field_5_value': field5Value,
      if (field6Name != null) 'field_6_name': field6Name,
      if (field6Value != null) 'field_6_value': field6Value,
      if (field7Name != null) 'field_7_name': field7Name,
      if (field7Value != null) 'field_7_value': field7Value,
      if (field8Name != null) 'field_8_name': field8Name,
      if (field8Value != null) 'field_8_value': field8Value,
      if (backgroundColorBadgeText != null &&
          backgroundColorBadgeText!.trim().isNotEmpty)
        'background_color_badge_text': backgroundColorBadgeText,
      if (badgeText != null && badgeText!.trim().isNotEmpty)
        'badge_text': badgeText,
      if (borderColorOffer != null && borderColorOffer!.trim().isNotEmpty)
        'border_color_offer': borderColorOffer,
    };
  }

  /// Получить все поля (name-value пары)
  List<OfferField> getFields() {
    List<OfferField> fields = [];

    if (field1Name != null && field1Value != null) {
      fields.add(OfferField(name: field1Name!, value: field1Value!));
    }
    if (field2Name != null && field2Value != null) {
      fields.add(OfferField(name: field2Name!, value: field2Value!));
    }
    if (field3Name != null && field3Value != null) {
      fields.add(OfferField(name: field3Name!, value: field3Value!));
    }
    if (field4Name != null && field4Value != null) {
      fields.add(OfferField(name: field4Name!, value: field4Value!));
    }
    if (field5Name != null && field5Value != null) {
      fields.add(OfferField(name: field5Name!, value: field5Value!));
    }
    if (field6Name != null && field6Value != null) {
      fields.add(OfferField(name: field6Name!, value: field6Value!));
    }
    if (field7Name != null && field7Value != null) {
      fields.add(OfferField(name: field7Name!, value: field7Value!));
    }
    if (field8Name != null && field8Value != null) {
      fields.add(OfferField(name: field8Name!, value: field8Value!));
    }

    return fields;
  }

  /// Проверка, поддерживает ли image формат SVG
  bool get isSvgImage => image.toLowerCase().endsWith('.svg');

  /// Проверка, поддерживает ли image формат PNG
  bool get isPngImage => image.toLowerCase().endsWith('.png');

  /// Получить рейтинг как число (с поддержкой дробных значений)
  double get starsAsDouble {
    try {
      return double.parse(stars);
    } catch (e) {
      return 0.0;
    }
  }

  /// Вывод данных в лог
  void logData() {
    //print('=== Offer ===');
    //print('id: $id');
    //print('isShow: $isShow');
    //print('link: $link');
    //print('image: $image (SVG: $isSvgImage, PNG: $isPngImage)');
    //print('buttonText: $buttonText');
    //print('name: $name');
    //print('stars: $stars (${starsAsDouble})');

    final fields = getFields();
    if (fields.isNotEmpty) {
      //print('Fields:');
      for (int i = 0; i < fields.length; i++) {
        //print('  ${i + 1}. ${fields[i].name}: ${fields[i].value}');
      }
    }
    //print('=============');
  }

  @override
  String toString() {
    return 'Offer(id: $id, name: $name, isShow: $isShow, stars: $stars)';
  }
}

/// Вспомогательный класс для представления поля оффера
class OfferField {
  final String name;
  final String value;

  OfferField({required this.name, required this.value});

  @override
  String toString() => '$name: $value';
}
