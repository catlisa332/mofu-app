import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/feed_provider.dart';
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
    final scrollToTop = ref.watch(feedScrollToTopProvider);
    final topPad = MediaQuery.of(context).padding.top;

    final scaffold = Scaffold(
      extendBody: true, // コンテンツをタブバーの下まで延ばす（iOS スタイル）
      body: IndexedStack(
        index: tabIndex,
        children: const [
          FeedScreen(),
          FavoritesScreen(),
          SleepScreen(),
          SettingsScreen(),
        ],
      ),
      bottomNavigationBar: _AppleTabBar(
        currentIndex: tabIndex,
        onTap: (i) => ref.read(_tabIndexProvider.notifier).state = i,
      ),
    );

    // フィードタブ表示中かつステータスバー領域がある場合のみ透明タップ領域を重ねる
    // HomeScreen レベルなので top: 0 が画面最上部（物理ステータスバー位置）と一致する
    if (!kIsWeb && tabIndex == 0 && topPad > 0 && scrollToTop != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          scaffold,
          Positioned(
            top: 0, left: 0, right: 0,
            height: topPad,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: scrollToTop,
            ),
          ),
        ],
      );
    }
    return scaffold;
  }
}

// ─── iOS スタイル タブバー（frosted glass）────────────────────────
class _AppleTabBar extends StatelessWidget {
  final int currentIndex;
  final void Function(int) onTap;

  const _AppleTabBar({required this.currentIndex, required this.onTap});

  static const _items = [
    _TabItem(icon: Icons.house_rounded,    outIcon: Icons.house_outlined,     label: 'ホーム'),
    _TabItem(icon: Icons.bookmark_rounded, outIcon: Icons.bookmark_border_rounded, label: 'お気に入り'),
    _TabItem(icon: Icons.bedtime_rounded,  outIcon: Icons.bedtime_outlined,   label: 'おやすみ'),
    _TabItem(icon: Icons.person_rounded,   outIcon: Icons.person_outline_rounded, label: '設定'),
  ];

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.85),
            border: const Border(
              top: BorderSide(color: MofuColors.separator, width: 0.5),
            ),
          ),
          child: SizedBox(
            height: 49 + bottomPad,
            child: Padding(
              padding: EdgeInsets.only(bottom: bottomPad),
              child: Row(
                children: List.generate(_items.length, (i) {
                  final item = _items[i];
                  final selected = currentIndex == i;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => onTap(i),
                      behavior: HitTestBehavior.opaque,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 150),
                            child: Icon(
                              selected ? item.icon : item.outIcon,
                              key: ValueKey(selected),
                              size: 24,
                              color: selected
                                  ? MofuColors.accent
                                  : MofuColors.tertiaryLabel,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            item.label,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: selected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: selected
                                  ? MofuColors.accent
                                  : MofuColors.tertiaryLabel,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TabItem {
  final IconData icon;
  final IconData outIcon;
  final String label;
  const _TabItem({required this.icon, required this.outIcon, required this.label});
}
