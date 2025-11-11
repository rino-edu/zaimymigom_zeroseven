import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/locale_keys.dart';

class FaqScreen extends StatefulWidget {
  const FaqScreen({super.key});

  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

enum _FaqCategory {
  all,
  general,
  application,
  repayment,
  rates,
  creditHistory,
  security,
  technical,
}

class _FaqItem {
  final String id;
  final _FaqCategory category;
  final String questionKey;
  final String answerKey;
  final List<String> keywords;

  const _FaqItem({
    required this.id,
    required this.category,
    required this.questionKey,
    required this.answerKey,
    this.keywords = const [],
  });
}

class _FaqScreenState extends State<FaqScreen> {
  static const _prefsFavoritesKey = 'faq_favorites';
  static const _prefsRatingsKey = 'faq_ratings';

  final TextEditingController _searchController = TextEditingController();
  _FaqCategory _selectedCategory = _FaqCategory.all;
  bool _favoritesOnly = false;
  Set<String> _favoriteIds = <String>{};
  Map<String, bool?> _ratings = <String, bool?>{};
  String _expandedId = '';

  // Демонстрационные вопросы и ответы. Текст берём из переводов по ключам.
  static const List<_FaqItem> _allFaqs = <_FaqItem>[
    _FaqItem(
      id: 'faq_general_1',
      category: _FaqCategory.general,
      questionKey: 'faq.samples.general_1.question',
      answerKey: 'faq.samples.general_1.answer',
      keywords: ['займ', 'кредит', 'что такое'],
    ),
    _FaqItem(
      id: 'faq_general_2',
      category: _FaqCategory.general,
      questionKey: 'faq.samples.general_2.question',
      answerKey: 'faq.samples.general_2.answer',
      keywords: ['микрозайм', 'отличие'],
    ),
    _FaqItem(
      id: 'faq_application_1',
      category: _FaqCategory.application,
      questionKey: 'faq.samples.application_1.question',
      answerKey: 'faq.samples.application_1.answer',
      keywords: ['оформить', 'заявка', 'документы'],
    ),
    _FaqItem(
      id: 'faq_application_2',
      category: _FaqCategory.application,
      questionKey: 'faq.samples.application_2.question',
      answerKey: 'faq.samples.application_2.answer',
      keywords: ['время', 'рассмотрение', 'одобрение'],
    ),
    _FaqItem(
      id: 'faq_repayment_1',
      category: _FaqCategory.repayment,
      questionKey: 'faq.samples.repayment_1.question',
      answerKey: 'faq.samples.repayment_1.answer',
      keywords: ['погашение', 'досрочное', 'как'],
    ),
    _FaqItem(
      id: 'faq_repayment_2',
      category: _FaqCategory.repayment,
      questionKey: 'faq.samples.repayment_2.question',
      answerKey: 'faq.samples.repayment_2.answer',
      keywords: ['просрочка', 'штраф', 'что делать'],
    ),
    _FaqItem(
      id: 'faq_rates_1',
      category: _FaqCategory.rates,
      questionKey: 'faq.samples.rates_1.question',
      answerKey: 'faq.samples.rates_1.answer',
      keywords: ['процент', 'ставка', 'ПСК'],
    ),
    _FaqItem(
      id: 'faq_rates_2',
      category: _FaqCategory.rates,
      questionKey: 'faq.samples.rates_2.question',
      answerKey: 'faq.samples.rates_2.answer',
      keywords: ['комиссия', 'дополнительные платежи'],
    ),
    _FaqItem(
      id: 'faq_credit_1',
      category: _FaqCategory.creditHistory,
      questionKey: 'faq.samples.credit_1.question',
      answerKey: 'faq.samples.credit_1.answer',
      keywords: ['кредитная история', 'БКИ', 'проверка'],
    ),
    _FaqItem(
      id: 'faq_credit_2',
      category: _FaqCategory.creditHistory,
      questionKey: 'faq.samples.credit_2.question',
      answerKey: 'faq.samples.credit_2.answer',
      keywords: ['кредитоспособность', 'оценка'],
    ),
    _FaqItem(
      id: 'faq_security_1',
      category: _FaqCategory.security,
      questionKey: 'faq.samples.security_1.question',
      answerKey: 'faq.samples.security_1.answer',
      keywords: ['безопасность', 'данные', 'защита'],
    ),
    _FaqItem(
      id: 'faq_security_2',
      category: _FaqCategory.security,
      questionKey: 'faq.samples.security_2.question',
      answerKey: 'faq.samples.security_2.answer',
      keywords: ['персональные данные', 'конфиденциальность'],
    ),
    _FaqItem(
      id: 'faq_technical_1',
      category: _FaqCategory.technical,
      questionKey: 'faq.samples.technical_1.question',
      answerKey: 'faq.samples.technical_1.answer',
      keywords: ['приложение', 'не работает', 'ошибка'],
    ),
    _FaqItem(
      id: 'faq_technical_2',
      category: _FaqCategory.technical,
      questionKey: 'faq.samples.technical_2.question',
      answerKey: 'faq.samples.technical_2.answer',
      keywords: ['обновление', 'версия'],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadFavorites();
    _loadRatings();
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_prefsFavoritesKey) ?? <String>[];
    setState(() {
      _favoriteIds = list.toSet();
    });
  }

  Future<void> _loadRatings() async {
    final prefs = await SharedPreferences.getInstance();
    final ratingsJson = prefs.getString(_prefsRatingsKey);
    if (ratingsJson != null && ratingsJson.isNotEmpty) {
      // Простое хранение: "id1:true,id2:false"
      final Map<String, bool?> ratings = <String, bool?>{};
      final parts = ratingsJson.split(',');
      for (final part in parts) {
        final kv = part.split(':');
        if (kv.length == 2) {
          ratings[kv[0]] = kv[1] == 'true';
        }
      }
      setState(() {
        _ratings = ratings;
      });
    }
  }

  Future<void> _toggleFavorite(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final isFav = _favoriteIds.contains(id);
    setState(() {
      if (isFav) {
        _favoriteIds.remove(id);
      } else {
        _favoriteIds.add(id);
      }
    });
    await prefs.setStringList(_prefsFavoritesKey, _favoriteIds.toList());
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isFav
              ? FaqKeys.removedFromFavorites.tr()
              : FaqKeys.addedToFavorites.tr(),
        ),
      ),
    );
  }

  Future<void> _rateAnswer(String id, bool helpful) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _ratings[id] = helpful;
    });
    // Сохраняем рейтинги
    final ratingsList = _ratings.entries
        .map((e) => '${e.key}:${e.value == true}')
        .join(',');
    await prefs.setString(_prefsRatingsKey, ratingsList);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          helpful
              ? FaqKeys.ratingHelpful.tr()
              : FaqKeys.ratingNotHelpful.tr(),
        ),
      ),
    );
  }

  List<_FaqItem> _filteredFaqs() {
    final query = _searchController.text.trim().toLowerCase();
    return _allFaqs.where((f) {
      if (_favoritesOnly && !_favoriteIds.contains(f.id)) return false;
      if (_selectedCategory != _FaqCategory.all &&
          f.category != _selectedCategory) {
        return false;
      }
      if (query.isEmpty) return true;
      // Поиск по ключевым словам и по локализованным question/answer
      final localizedQuestion = tr(f.questionKey).toLowerCase();
      final localizedAnswer = tr(f.answerKey).toLowerCase();
      final keywordHit = f.keywords.any((k) => k.toLowerCase().contains(query));
      return keywordHit ||
          localizedQuestion.contains(query) ||
          localizedAnswer.contains(query);
    }).toList();
  }

  String _categoryLabel(_FaqCategory c) {
    switch (c) {
      case _FaqCategory.all:
        return FaqKeys.categoryAll.tr();
      case _FaqCategory.general:
        return FaqKeys.categoryGeneral.tr();
      case _FaqCategory.application:
        return FaqKeys.categoryApplication.tr();
      case _FaqCategory.repayment:
        return FaqKeys.categoryRepayment.tr();
      case _FaqCategory.rates:
        return FaqKeys.categoryRates.tr();
      case _FaqCategory.creditHistory:
        return FaqKeys.categoryCreditHistory.tr();
      case _FaqCategory.security:
        return FaqKeys.categorySecurity.tr();
      case _FaqCategory.technical:
        return FaqKeys.categoryTechnical.tr();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final faqs = _filteredFaqs();
    return Scaffold(
      appBar: AppBar(
        title: Text(FaqKeys.title.tr()),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: FaqKeys.searchPlaceholder.tr(),
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 44,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                scrollDirection: Axis.horizontal,
                children: [
                  for (final c in _FaqCategory.values)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ChoiceChip(
                        label: Text(_categoryLabel(c)),
                        selected: _selectedCategory == c,
                        onSelected: (_) {
                          setState(() => _selectedCategory = c);
                        },
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(FaqKeys.favoritesOnly.tr()),
                      const SizedBox(width: 8),
                      Switch(
                        value: _favoritesOnly,
                        onChanged: (v) => setState(() => _favoritesOnly = v),
                      ),
                    ],
                  ),
                  TextButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text(FaqKeys.askQuestionTitle.tr()),
                          content: Text(FaqKeys.askQuestionMessage.tr()),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text(LocaleKeys.actionsCancel.tr()),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(FaqKeys.askQuestionSent.tr()),
                                  ),
                                );
                              },
                              child: Text(LocaleKeys.actionsConfirm.tr()),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: const Icon(Icons.help_outline),
                    label: Text(FaqKeys.askQuestion.tr()),
                  ),
                ],
              ),
            ),
            Expanded(
              child: faqs.isEmpty
                  ? Center(
                      child: Text(
                        FaqKeys.empty.tr(),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                      itemCount: faqs.length,
                      itemBuilder: (context, index) {
                        final faq = faqs[index];
                        final isExpanded = _expandedId == faq.id;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _FaqCard(
                            faq: faq,
                            isFavorite: _favoriteIds.contains(faq.id),
                            onToggleFavorite: () => _toggleFavorite(faq.id),
                            categoryLabel: _categoryLabel(faq.category),
                            isExpanded: isExpanded,
                            onExpandedChanged: (expanded) {
                              setState(() {
                                _expandedId = expanded ? faq.id : '';
                              });
                            },
                            rating: _ratings[faq.id],
                            onRate: (helpful) => _rateAnswer(faq.id, helpful),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FaqCard extends StatelessWidget {
  final _FaqItem faq;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;
  final String categoryLabel;
  final bool isExpanded;
  final ValueChanged<bool> onExpandedChanged;
  final bool? rating;
  final ValueChanged<bool> onRate;

  const _FaqCard({
    required this.faq,
    required this.isFavorite,
    required this.onToggleFavorite,
    required this.categoryLabel,
    required this.isExpanded,
    required this.onExpandedChanged,
    this.rating,
    required this.onRate,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => onExpandedChanged(!isExpanded),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tr(faq.questionKey),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 8,
                          children: [
                            Chip(
                              label: Text(categoryLabel),
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite
                          ? Theme.of(context).colorScheme.error
                          : null,
                    ),
                    onPressed: onToggleFavorite,
                    tooltip: isFavorite
                        ? LocaleKeys.actionsRemove.tr()
                        : LocaleKeys.actionsAdd.tr(),
                  ),
                  Icon(
                    isExpanded
                        ? Icons.expand_less
                        : Icons.expand_more,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr(faq.answerKey),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        FaqKeys.wasHelpful.tr(),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(
                          rating == true
                              ? Icons.thumb_up
                              : Icons.thumb_up_outlined,
                          color: rating == true
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                        onPressed: rating == true
                            ? null
                            : () => onRate(true),
                        tooltip: FaqKeys.helpful.tr(),
                      ),
                      IconButton(
                        icon: Icon(
                          rating == false
                              ? Icons.thumb_down
                              : Icons.thumb_down_outlined,
                          color: rating == false
                              ? Theme.of(context).colorScheme.error
                              : null,
                        ),
                        onPressed: rating == false
                            ? null
                            : () => onRate(false),
                        tooltip: FaqKeys.notHelpful.tr(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

