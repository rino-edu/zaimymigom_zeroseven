import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/offer.dart';
import '../views/webview/webview_screen.dart';

/// Карточка оффера с раскрывающимися полями
class OfferCard extends StatefulWidget {
  final Offer offer;
  final VoidCallback? onButtonTap;

  const OfferCard({super.key, required this.offer, this.onButtonTap});

  @override
  State<OfferCard> createState() => _OfferCardState();
}

class _OfferCardState extends State<OfferCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final fields = widget.offer.getFields();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20, // Размытие тени
            spreadRadius: 5, // Распространение тени во все стороны
            offset: const Offset(0, 8), // Смещение тени вниз
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 15,
            spreadRadius: 3,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок карточки с логотипом, названием и рейтингом
          _buildCardHeader(),
          _buildField8Badge(),
          // Раскрывающаяся область с полями
          _buildExpandableFields(fields),

          // Кнопка действия (во всю ширину карточки)
          _buildActionButton(),
        ],
      ),
    );
  }

  /// Контейнер с field8Name
  Widget _buildField8Badge() {
    // Если field8Name пустой, не показываем контейнер
    if (widget.offer.field1Name == null || widget.offer.field1Name!.isEmpty) {
      debugPrint("пустой field1Name");
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
          colors: [
            Color(0xFFEFEFEF), // #3DB592
            Color(0xFFDDDDDD), // #3AB08E
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        widget.offer.field1Name!,
        style: const TextStyle(
          fontSize: 14,
          color: Colors.black,
          fontWeight: FontWeight.w800, // Полужирный
        ),
      ),
    );
  }

  /// Заголовок карточки
  Widget _buildCardHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              // Логотип
              _buildLogo(),
              const SizedBox(width: 12),
              //Spacer(),
              Text(
                widget.offer.name,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          // const SizedBox(height: 16),
          // // Название по центру под логотипом
          // Center(
          //   child: Text(
          //     widget.offer.name,
          //     style: Theme.of(context).textTheme.headlineLarge?.copyWith(
          //       fontWeight: FontWeight.w600,
          //       color: Colors.grey[600],
          //     ),
          //     textAlign: TextAlign.center,
          //   ),
          // ),
        ],
      ),
    );
  }

  /// Логотип оффера
  Widget _buildLogo() {
    return Container(
      width: 60, // Увеличиваем размер логотипа
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.black26,
        )
      ),
      child: _buildImage(),
    );
  }

  /// Построение изображения (SVG или PNG)
  Widget _buildImage() {
    if (widget.offer.image.isEmpty) {
      // Заглушка если нет изображения
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          color: Colors.white,
          child: Icon(Icons.business, color: Colors.grey[400], size: 80),
        ),
      );
    }

    if (widget.offer.isSvgImage) {
      // SVG изображение
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SvgPicture.network(
          widget.offer.image,
          fit: BoxFit.contain, // Изображение влезает полностью без обрезки
          placeholderBuilder: (context) => Container(
            color: Colors.white,
            child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          errorBuilder: (context, error, stackTrace) => Container(
            color: Colors.white,
            child: Icon(Icons.error_outline, color: Colors.grey[400], size: 80),
          ),
        ),
      );
    } else {
      // PNG/JPG изображение
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.network(
          widget.offer.image,
          fit: BoxFit.contain, // Изображение влезает полностью без обрезки
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              color: Colors.white,
              child: const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) => Container(
            color: Colors.white,
            child: Icon(Icons.error_outline, color: Colors.grey[400], size: 80),
          ),
        ),
      );
    }
  }

  /// Рейтинг оффера
  Widget _buildRating() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: AlignmentDirectional.center,
          children: [
            Icon(Icons.star, color: Colors.black54, size: 28),
            Icon(Icons.star, color: Colors.yellow, size: 22),
          ],
        ),
        const SizedBox(width: 6),
        Text(
          widget.offer.stars,
          style: TextStyle(
            fontWeight: FontWeight.w900, // Жирнее
            color: Colors.grey[600],
            fontSize: 18, // Больше
          ),
        ),
      ],
    );
  }

  /// Статичная область с полями в две колонки
  Widget _buildExpandableFields(List<OfferField> fields) {
    final validFields = fields
        .where(
          (field) =>
      field.name.trim().isNotEmpty && field.value.trim().isNotEmpty,
    )
        .toList();

    if (validFields.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: validFields.asMap().entries.map((entry) {
        final index = entry.key;
        final field = entry.value;
        return _buildFieldRow(field, isFirst: index == 0);
      }).toList(),
    );
  }


  /// Строка с полем: название слева (серое), значение справа (первое жирное)
  Widget _buildFieldRow(OfferField field, {bool isFirst = false}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Row(
        children: [
          // Левая колонка: название (серое, выровнено по левому краю)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text(
                field.name.trim(),
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 18,
                ),
                textAlign: TextAlign.left,
              ),
            ),
          ),
          // Правая колонка: значение (первое жирное, выровнено по правому краю)
          Expanded(
            child: Text(
              field.value.trim(),
              style: TextStyle(
                color: Colors.black87,
                fontSize: 18,
                fontWeight: isFirst ? FontWeight.w900 : FontWeight.normal,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }


  /// Получить первые N валидных полей
  List<OfferField> _getFirstValidFields(List<OfferField> fields, int count) {
    final validFields = fields
        .where(
          (field) =>
      field.name.trim().isNotEmpty && field.value.trim().isNotEmpty,
    )
        .toList();

    return validFields.take(count).toList();
  }

  /// Получить дополнительные поля (начиная с 3-го)
  List<OfferField> _getAdditionalFields(List<OfferField> fields) {
    final validFields = fields
        .where(
          (field) =>
      field.name.trim().isNotEmpty && field.value.trim().isNotEmpty,
    )
        .toList();

    // Возвращаем поля начиная с 3-го (индекс 2)
    return validFields.skip(2).toList();
  }

  /// Построение дополнительных полей
  Widget _buildAdditionalFields(List<OfferField> fields) {
    final additionalFields = _getAdditionalFields(fields);

    if (additionalFields.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        // Разделитель
        Container(
          height: 1,
          color: Colors.grey[200],
          margin: const EdgeInsets.symmetric(vertical: 8),
        ),
        // Дополнительные поля
        _buildFieldsGrid(additionalFields),
      ],
    );
  }

  /// Сетка полей в 2 колонки
  Widget _buildFieldsGrid(List<OfferField> fields) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Фильтруем поля с пустыми названиями или значениями
        final validFields = fields
            .where(
              (field) =>
          field.name.trim().isNotEmpty && field.value.trim().isNotEmpty,
        )
            .toList();

        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: validFields.map((field) {
            return SizedBox(
              width: (constraints.maxWidth - 8) / 2,
              child: _buildFieldItem(field),
            );
          }).toList(),
        );
      },
    );
  }

  /// Отдельное поле
  Widget _buildFieldItem(OfferField field) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Заголовок поля
        Text(
          field.name,
          style: TextStyle(
            fontSize: 14, // Больше
            color: Colors.grey[500],
            fontWeight: FontWeight.w500, // Чуть жирнее
          ),
        ),
        const SizedBox(height: 4),
        // Значение поля
        Text(
          field.value,
          style: TextStyle(
            fontSize: 16, // Больше
            color: Colors.grey[700],
            fontWeight: FontWeight.w700, // Жирнее
          ),
        ),
      ],
    );
  }

  /// Кнопка действия
  Widget _buildActionButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16),
      child: Container(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => _onButtonTap(),
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xff7DB265),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 0, // Убираем тень чтобы кнопка была на уровне карточки
          ),
          child: Text(
            widget.offer.buttonText,
            style: const TextStyle(
              fontSize: 20, // Больше размер шрифта
              fontWeight: FontWeight.bold, // Жирнее текст
            ),
          ),
        ),
      ),
    );
  }

  /// Обработка нажатия на кнопку
  void _onButtonTap() {
    // Если есть кастомный обработчик, используем его
    if (widget.onButtonTap != null) {
      widget.onButtonTap!();
      return;
    }

    // Иначе открываем WebView
    if (widget.offer.link.isNotEmpty) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => WebViewScreen(offer: widget.offer),
        ),
      );
    } else {
      // Показываем сообщение, если ссылка пустая
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ссылка недоступна'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}