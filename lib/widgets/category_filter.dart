import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/video_post.dart';
import '../theme/app_theme.dart';

// 選択中のカテゴリ（nullは全部）
final categoryFilterProvider = StateProvider<AnimalType?>((ref) => null);

const _categories = [
  (null,                 '🐾', '全部'),
  (AnimalType.cat,       '🐱', '猫'),
  (AnimalType.dog,       '🐶', '犬'),
  (AnimalType.smallAnimal,'🐹', '小動物'),
  (AnimalType.bird,      '🐦', '鳥'),
  (AnimalType.otter,     '🦦', 'カワウソ'),
  (AnimalType.mixedSpecies,'🤝', '異種'),
  (AnimalType.babyAnimal,'🍼', '赤ちゃん'),
];

class CategoryFilter extends ConsumerWidget {
  const CategoryFilter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(categoryFilterProvider);

    return SliverToBoxAdapter(
      child: SizedBox(
        height: 44,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: _categories.length,
          itemBuilder: (_, i) {
            final item = _categories[i];
            final isSelected = selected == item.$1;
            return GestureDetector(
              onTap: () =>
                  ref.read(categoryFilterProvider.notifier).state = item.$1,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? MofuColors.warmTan : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? MofuColors.warmTan : MofuColors.divider,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(item.$2, style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 4),
                    Text(item.$3,
                        style: TextStyle(
                          fontSize: 12,
                          color: isSelected ? Colors.white : MofuColors.textDark,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                        )),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
