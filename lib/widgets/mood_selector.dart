import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/preferences_provider.dart';
import '../theme/app_theme.dart';

enum TodayMood { healing, spacing, laughing, tired }

final todayMoodProvider = StateProvider<TodayMood?>((ref) => null);

class MoodSelectorSheet extends ConsumerWidget {
  const MoodSelectorSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const MoodSelectorSheet(),
    );
  }

  static const _moods = [
    (TodayMood.healing, '🌸', 'ただ癒されたい'),
    (TodayMood.laughing, '😄', '笑いたい'),
    (TodayMood.spacing, '😶‍🌫️', 'ぼーっとしたい'),
    (TodayMood.tired, '🫂', '心が疲れてる'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(todayMoodProvider);

    return Container(
      decoration: const BoxDecoration(
        color: MofuColors.cream,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: MofuColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            '今日はどんな気分？',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w300),
          ),
          const SizedBox(height: 24),
          ...(_moods.map((item) => _MoodTile(
                mood: item.$1,
                emoji: item.$2,
                label: item.$3,
                isSelected: current == item.$1,
                onTap: () {
                  ref.read(todayMoodProvider.notifier).state = item.$1;
                  if (item.$1 == TodayMood.tired) {
                    ref.read(preferencesProvider.notifier).setTiredMode(true);
                  } else {
                    ref.read(preferencesProvider.notifier).setTiredMode(false);
                  }
                  Navigator.of(context).pop();
                },
              ))),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _MoodTile extends StatelessWidget {
  final TodayMood mood;
  final String emoji;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _MoodTile({
    required this.mood,
    required this.emoji,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isTired = mood == TodayMood.tired;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? (isTired ? MofuColors.softLavender : MofuColors.softPeach)
              : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? MofuColors.warmTan : MofuColors.divider,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 26)),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                fontSize: 17,
                color: MofuColors.textDark,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            const Spacer(),
            if (isTired)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: MofuColors.softLavender,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text('特別モード',
                    style: TextStyle(fontSize: 11, color: MofuColors.softBrown)),
              ),
          ],
        ),
      ),
    );
  }
}
