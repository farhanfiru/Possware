import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CategorySelector extends StatelessWidget {
  final List<String> categories;
  final String selectedCategory;
  final Function(String) onSelectCategory;

  const CategorySelector({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.onSelectCategory,
  });

  String _getCategoryEmoji(String category) {
    final lower = category.toLowerCase();
    if (lower == 'all') return '🍽️';
    if (lower.contains('coffee') || lower.contains('tea') || lower.contains('chai')) return '☕';
    if (lower.contains('burger')) return '🍔';
    if (lower.contains('pizza')) return '🍕';
    if (lower.contains('snack') || lower.contains('fry') || lower.contains('fries')) return '🍟';
    if (lower.contains('drink') || lower.contains('shake') || lower.contains('juice') || lower.contains('beverage')) return '🥤';
    if (lower.contains('dessert') || lower.contains('cake') || lower.contains('sweet') || lower.contains('ice')) return '🍰';
    if (lower.contains('rice') || lower.contains('biryani') || lower.contains('meal') || lower.contains('curry')) return '🍛';
    if (lower.contains('sandwich') || lower.contains('toast')) return '🥪';
    if (lower.contains('noodle') || lower.contains('pasta') || lower.contains('chinese')) return '🍜';
    if (lower.contains('soup')) return '🍲';
    return '🍴';
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = cat.toLowerCase() == selectedCategory.toLowerCase();
          final emoji = _getCategoryEmoji(cat);

          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => onSelectCategory(cat),
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primaryBurgundy : AppTheme.surfaceWhite,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? AppTheme.primaryBurgundy : AppTheme.cardBorder,
                    width: 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppTheme.primaryBurgundy.withOpacity(0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          )
                        ]
                      : [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          )
                        ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 15)),
                    const SizedBox(width: 6),
                    Text(
                      cat,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                        color: isSelected ? Colors.white : AppTheme.textDark,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
