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

          // Раскрывающаяся область с полями
          _buildExpandableFields(fields),

          // Кнопка действия (во всю ширину карточки)
          _buildActionButton(),
        ],
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
            children: [
              // Логотип
              _buildLogo(),
              const SizedBox(width: 12),
              Spacer(),
              // Рейтинг
              _buildRating(),
            ],
          ),
          const SizedBox(height: 4),
          // Название по центру под логотипом
          Center(
            child: Text(
              widget.offer.name,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  /// Логотип оффера
  Widget _buildLogo() {
    return SizedBox(
      width: 160, // Увеличиваем размер логотипа
      height: 100,
      child: _buildImage(),
    );
  }

  /// Построение изображения (SVG или PNG)
  Widget _buildImage() {
    if (widget.offer.image.isEmpty) {
      // Заглушка если нет изображения
      return Icon(Icons.business, color: Colors.grey[400], size: 80);
    }

    if (widget.offer.isSvgImage) {
      // SVG изображение
      return SvgPicture.network(
        widget.offer.image,
        fit: BoxFit.contain, // Изображение влезает полностью без обрезки
        placeholderBuilder: (context) => Container(
          color: Colors.grey[200],
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        errorBuilder: (context, error, stackTrace) =>
            Icon(Icons.error_outline, color: Colors.grey[400], size: 80),
      );
    } else {
      // PNG/JPG изображение
      return Image.network(
        widget.offer.image,
        fit: BoxFit.contain, // Изображение влезает полностью без обрезки
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: Colors.grey[200],
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) =>
            Icon(Icons.error_outline, color: Colors.grey[400], size: 80),
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

  /// Раскрывающаяся область с полями
  Widget _buildExpandableFields(List<OfferField> fields) {
    // Проверяем есть ли валидные поля (не пустые названия и значения)
    final validFields = fields
        .where(
          (field) =>
              field.name.trim().isNotEmpty && field.value.trim().isNotEmpty,
        )
        .toList();

    if (validFields.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[50], // Светлее основного цвета карточки
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // Кнопка для раскрытия/сворачивания
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Всегда показываем первые 2 поля
                  Expanded(
                    child: _buildFieldsGrid(_getFirstValidFields(fields, 2)),
                  ),
                  // Анимированная стрелка
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: Icon(
                      size: 30,
                      _isExpanded ? Icons.expand_circle_down : Icons.expand_circle_down_outlined,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Анимированное раскрытие дополнительных полей
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _isExpanded
                ? Container(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: _buildAdditionalFields(fields),
                  )
                : const SizedBox.shrink(),
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
      padding: const EdgeInsets.only(top: 16.0),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(12),
            bottomRight: Radius.circular(12),
          ),
        ),
        child: ElevatedButton(
          onPressed: () => _onButtonTap(),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green[600],
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
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
