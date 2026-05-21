import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../favorites/favorites_screen.dart';
import '../feed/feed_screen.dart';
import '../settings/settings_screen.dart';
import '../sleep/sleep_screen.dart';

final _tabIndexProvider = StateProvider<int>((ref) => 0);

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabIndex = ref.watch(_tabIndexProvider);

    return Scaffold(
      body: IndexedStack(
        index: tabIndex,
        children: const [
          FeedScreen(),
          FavoritesScreen(),
          SleepScreen(),
          SettingsScreen(),
        ],
      ),
      bottomNavigationBar: _MofuBottomNav(
        currentIndex: tabIndex,
        onTap: (i) => ref.read(_tabIndexProvider.notifier).state = i,
      ),
    );
  }
}

class _MofuBottomNav extends StatelessWidget {
  final int currentIndex;
  final void Function(int) onTap;

  const _MofuBottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: MofuColors.divider)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 58,
          child: Row(
            children: [
              _NavItem(emoji: '🐾', label: 'フィード',
                  isSelected: currentIndex == 0, onTap: () => onTap(0)),
              _NavItem(emoji: '❤️', label: 'お気に入り',
                  isSelected: currentIndex == 1, onTap: () => onTap(1)),
              _NavItem(emoji: '🌙', label: '睡眠',
                  isSelected: currentIndex == 2, onTap: () => onTap(2)),
              _NavItem(emoji: '⚙️', label: '設定',
                  isSelected: currentIndex == 3, onTap: () => onTap(3)),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final String emoji;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.emoji,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: isSelected ? MofuColors.warmTan : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji,
                  style: TextStyle(fontSize: isSelected ? 24 : 20)),
              const SizedBox(height: 2),
              Text(label,
                  style: TextStyle(
                    fontSize: 10,
                    color: isSelected
                        ? MofuColors.warmTan
                        : MofuColors.textLight,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.w400,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
