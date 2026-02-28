import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Horizontally scrollable category chips for quick searches.
class CategoryChips extends StatefulWidget {
  const CategoryChips({super.key});

  @override
  State<CategoryChips> createState() => _CategoryChipsState();
}

class _CategoryChipsState extends State<CategoryChips> {
  int _selected = 0;

  static const _categories = [
    'All',
    'Nature',
    'Abstract',
    'Dark',
    'Space',
    'City',
    'Ocean',
    'Mountains',
    'Minimal',
    'Anime',
    'Flowers',
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final isActive = index == _selected;
          return ChoiceChip(
            label: Text(_categories[index]),
            selected: isActive,
            selectedColor: AppColors.primary,
            backgroundColor: Theme.of(context).cardColor,
            labelStyle: TextStyle(
              color: isActive ? Colors.white : Colors.grey,
              fontWeight: FontWeight.w600,
            ),
            onSelected: (_) => setState(() => _selected = index),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          );
        },
      ),
    );
  }
}
