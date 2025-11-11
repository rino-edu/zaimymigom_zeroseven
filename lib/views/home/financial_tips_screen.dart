import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/locale_keys.dart';

class FinancialTipsScreen extends StatefulWidget {
  const FinancialTipsScreen({super.key});

  @override
  State<FinancialTipsScreen> createState() => _FinancialTipsScreenState();
}

enum _TipCategory {
  all,
  budget,
  loans,
  savings,
  literacy,
  antiFraud,
}

class _TipItem {
  final String id;
  final _TipCategory category;
  final String titleKey;
  final String contentKey;
  final List<String> keywords;

  const _TipItem({
    required this.id,
    required this.category,
    required this.titleKey,
    required this.contentKey,
    this.keywords = const [],
  });
}

class _FinancialTipsScreenState extends State<FinancialTipsScreen> {
  static const _prefsFavoritesKey = 'financial_tips_favorites';

  final TextEditingController _searchController = TextEditingController();
  _TipCategory _selectedCategory = _TipCategory.all;
  bool _favoritesOnly = false;
  Set<String> _favoriteIds = <String>{};

  // Демонстрационные советы. Текст берём из переводов по ключам.
  static const List<_TipItem> _allTips = <_TipItem>[
    _TipItem(
      id: 'tip_budget_1',
      category: _TipCategory.budget,
      titleKey: 'financial_tips.samples.budget_1.title',
      contentKey: 'financial_tips.samples.budget_1.content',
      keywords: ['budget', 'лимит', 'учёт'],
    ),
    _TipItem(
      id: 'tip_budget_2',
      category: _TipCategory.budget,
      titleKey: 'financial_tips.samples.budget_2.title',
      contentKey: 'financial_tips.samples.budget_2.content',
      keywords: ['категории', 'план'],
    ),
    _TipItem(
      id: 'tip_loans_1',
      category: _TipCategory.loans,
      titleKey: 'financial_tips.samples.loans_1.title',
      contentKey: 'financial_tips.samples.loans_1.content',
      keywords: ['займ', 'платёж', 'проценты'],
    ),
    _TipItem(
      id: 'tip_loans_2',
      category: _TipCategory.loans,
      titleKey: 'financial_tips.samples.loans_2.title',
      contentKey: 'financial_tips.samples.loans_2.content',
      keywords: ['досрочное', 'переплата'],
    ),
    _TipItem(
      id: 'tip_savings_1',
      category: _TipCategory.savings,
      titleKey: 'financial_tips.samples.savings_1.title',
      contentKey: 'financial_tips.samples.savings_1.content',
      keywords: ['накопления', 'подушка'],
    ),
    _TipItem(
      id: 'tip_savings_2',
      category: _TipCategory.savings,
      titleKey: 'financial_tips.samples.savings_2.title',
      contentKey: 'financial_tips.samples.savings_2.content',
      keywords: ['инвестиции', 'диверсификация'],
    ),
    _TipItem(
      id: 'tip_literacy_1',
      category: _TipCategory.literacy,
      titleKey: 'financial_tips.samples.literacy_1.title',
      contentKey: 'financial_tips.samples.literacy_1.content',
      keywords: ['финансовая грамотность', 'обучение'],
    ),
    _TipItem(
      id: 'tip_anti_fraud_1',
      category: _TipCategory.antiFraud,
      titleKey: 'financial_tips.samples.anti_fraud_1.title',
      contentKey: 'financial_tips.samples.anti_fraud_1.content',
      keywords: ['мошенничество', 'безопасность'],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_prefsFavoritesKey) ?? <String>[];
    setState(() {
      _favoriteIds = list.toSet();
    });
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
              ? FinancialTipsKeys.removedFromFavorites.tr()
              : FinancialTipsKeys.addedToFavorites.tr(),
        ),
      ),
    );
  }

  List<_TipItem> _filteredTips() {
    final query = _searchController.text.trim().toLowerCase();
    return _allTips.where((t) {
      if (_favoritesOnly && !_favoriteIds.contains(t.id)) return false;
      if (_selectedCategory != _TipCategory.all &&
          t.category != _selectedCategory) {
        return false;
      }
      if (query.isEmpty) return true;
      // Поиск по ключевым словам и по локализованным title/content
      final localizedTitle = tr(t.titleKey).toLowerCase();
      final localizedContent = tr(t.contentKey).toLowerCase();
      final keywordHit = t.keywords.any((k) => k.toLowerCase().contains(query));
      return keywordHit ||
          localizedTitle.contains(query) ||
          localizedContent.contains(query);
    }).toList();
  }

  _TipItem _tipOfTheDay() {
    if (_allTips.isEmpty) {
      return const _TipItem(
        id: 'empty',
        category: _TipCategory.budget,
        titleKey: 'financial_tips.empty',
        contentKey: 'financial_tips.empty',
      );
    }
    final idx = DateTime.now().day % _allTips.length;
    return _allTips[idx];
  }

  String _categoryLabel(_TipCategory c) {
    switch (c) {
      case _TipCategory.all:
        return FinancialTipsKeys.categoryAll.tr();
      case _TipCategory.budget:
        return FinancialTipsKeys.categoryBudget.tr();
      case _TipCategory.loans:
        return FinancialTipsKeys.categoryLoans.tr();
      case _TipCategory.savings:
        return FinancialTipsKeys.categorySavings.tr();
      case _TipCategory.literacy:
        return FinancialTipsKeys.categoryLiteracy.tr();
      case _TipCategory.antiFraud:
        return FinancialTipsKeys.categoryAntiFraud.tr();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tips = _filteredTips();
    final tipOfTheDay = _tipOfTheDay();
    return Scaffold(
      appBar: AppBar(
        title: Text(FinancialTipsKeys.title.tr()),
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
                  hintText: FinancialTipsKeys.searchPlaceholder.tr(),
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
                  for (final c in _TipCategory.values)
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
                      const Icon(Icons.wb_sunny_outlined, size: 18),
                      const SizedBox(width: 6),
                      Text(FinancialTipsKeys.tipOfTheDay.tr()),
                    ],
                  ),
                  Row(
                    children: [
                      Text(FinancialTipsKeys.favoritesOnly.tr()),
                      const SizedBox(width: 8),
                      Switch(
                        value: _favoritesOnly,
                        onChanged: (v) => setState(() => _favoritesOnly = v),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: tips.isEmpty
                  ? Center(
                      child: Text(
                        FinancialTipsKeys.empty.tr(),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                      itemCount: tips.length,
                      itemBuilder: (context, index) {
                        final tip = tips[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _TipCard(
                            tip: tip,
                            isFavorite: _favoriteIds.contains(tip.id),
                            onToggleFavorite: () => _toggleFavorite(tip.id),
                            categoryLabel: _categoryLabel(tip.category),
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

class _TipCard extends StatelessWidget {
  final _TipItem tip;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;
  final String categoryLabel;

  const _TipCard({
    required this.tip,
    required this.isFavorite,
    required this.onToggleFavorite,
    required this.categoryLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    tr(tip.titleKey),
                    style: Theme.of(context).textTheme.titleMedium,
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
              ],
            ),
            const SizedBox(height: 8),
            Text(
              tr(tip.contentKey),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
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
    );
  }
}


