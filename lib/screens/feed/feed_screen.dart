import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/dislike_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/feed_provider.dart';
import '../../providers/learning_provider.dart';
import '../../providers/preferences_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/mood_selector.dart';
import '../../widgets/skeleton_card.dart';
import '../../widgets/animated_card_wrapper.dart';
import '../../widgets/category_filter.dart';
import '../../widgets/daily_pick_card.dart';
import '../../widgets/install_banner.dart';
import '../../widgets/video_card.dart';
import '../detail/detail_screen.dart';

// 🌿ヒントを表示済みかどうか
final _hintShownProvider = FutureProvider<bool>((ref) async {
  final sp = await SharedPreferences.getInstance();
  return sp.getBool('leaf_hint_shown') ?? false;
});

final _hintVisibleProvider = StateProvider<bool>((ref) => true);

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final prefsAsync = ref.watch(preferencesProvider);
    final feedAsync = ref.watch(feedProvider);
    final todayMood = ref.watch(todayMoodProvider);
    final dislikedAsync = ref.watch(dislikeProvider);

    final isTired = prefsAsync.valueOrNull?.isTiredMode ?? false;
    final dislikedIds = dislikedAsync.valueOrNull ?? {};
    final categoryFilter = ref.watch(categoryFilterProvider);
    final statusBarHeight = MediaQuery.of(context).padding.top;

    return Stack(
      fit: StackFit.expand,
      children: [
      Scaffold(
      backgroundColor: MofuColors.systemBackground,
      body: NotificationListener<ScrollEndNotification>(
        onNotification: (n) {
          // PC(Web) のみ：末尾近くで自動追加読み込み
          if (kIsWeb) {
            final m = n.metrics;
            if (m.pixels >= m.maxScrollExtent - 500) {
              ref.read(feedProvider.notifier).loadMore();
            }
          }
          return false;
        },
        child: RefreshIndicator(
        color: MofuColors.warmTan,
        backgroundColor: Colors.white,
        displacement: 60,
        onRefresh: () => ref.read(feedProvider.notifier).refresh(),
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
          _AppBar(isTired: isTired, onLogoTap: _scrollToTop),
          if (isTired) const _TiredModeBanner(),
          _LeafHintBanner(ref: ref),
          if (!isTired) const DailyPickCard(),
          const CategoryFilter(),
          feedAsync.when(
            loading: () => const SkeletonFeed(count: 4),
            error: (e, _) => SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('😿', style: TextStyle(fontSize: 48)),
                    const SizedBox(height: 12),
                    const Text('読み込めませんでした'),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => ref.read(feedProvider.notifier).refresh(),
                      child: const Text('もう一度'),
                    ),
                  ],
                ),
              ),
            ),
            data: (posts) {
              final prefs = prefsAsync.valueOrNull;
              final avoidTags = prefs?.avoidTags ?? [];
              final favoriteAnimals = prefs?.favoriteAnimals ?? [];

              // ① しんどい・疲れモード・苦手タグを除外
              var filtered = posts
                  .where((p) => !dislikedIds.contains(p.id))
                  .where((p) => !isTired || p.isSafeForTiredMode)
                  .where((p) => !p.tags.any(avoidTags.contains))
                  .where((p) => categoryFilter == null || p.animalType == categoryFilter)
                  .toList();

              // ② 好きな動物を70%優先（仕様書Section 16）
              if (favoriteAnimals.isNotEmpty) {
                final favPosts = filtered
                    .where((p) => favoriteAnimals.contains(p.animalType))
                    .toList();
                final otherPosts = filtered
                    .where((p) => !favoriteAnimals.contains(p.animalType))
                    .toList();
                // 70% 好き / 30% その他
                final favCount = (filtered.length * 0.7).round();
                filtered = [
                  ...favPosts.take(favCount),
                  ...otherPosts.take(filtered.length - favCount),
                ]..shuffle();
              }

              // ③ 今日の気分でフィルター・並べ替え
              switch (todayMood) {
                case TodayMood.healing:
                  // 穏やか順（デフォルト）
                  filtered.sort((a, b) => b.calmScore.compareTo(a.calmScore));
                case TodayMood.laughing:
                  // GIF・動きのあるコンテンツを優先
                  filtered.sort((a, b) {
                    if (a.isGif && !b.isGif) return -1;
                    if (!a.isGif && b.isGif) return 1;
                    return 0;
                  });
                case TodayMood.spacing:
                  // 非常に穏やか・静止画のみ
                  filtered = filtered
                      .where((p) => p.calmScore > 0.84 && !p.isGif)
                      .toList()
                    ..sort((a, b) => b.calmScore.compareTo(a.calmScore));
                case TodayMood.tired:
                  // おやすみモードと同じく安全なコンテンツのみ
                  filtered = filtered.where((p) => p.isSafeForTiredMode).toList();
                case null:
                  break;
              }

              if (filtered.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(categoryFilter == null ? '😿' : '🔍',
                            style: const TextStyle(fontSize: 48)),
                        const SizedBox(height: 16),
                        Text(
                          categoryFilter == null
                              ? 'まだ画像がないよ'
                              : 'このカテゴリーの画像がまだないよ',
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w300,
                              color: MofuColors.textDark),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () =>
                              ref.read(feedProvider.notifier).refresh(),
                          child: const Text('🔄 読み込み直す'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => AnimatedCardWrapper(
                    index: i,
                    child: VideoCard(
                    post: filtered[i],
                    isFavorited: ref.watch(favoritesProvider).valueOrNull?.contains(filtered[i].id) ?? false,
                    onTap: () => Navigator.of(context).push(
                      PageRouteBuilder(
                        pageBuilder: (_, __, ___) =>
                            DetailScreen(post: filtered[i]),
                        transitionsBuilder: (_, anim, __, child) =>
                            FadeTransition(opacity: anim, child: child),
                        transitionDuration: const Duration(milliseconds: 250),
                      ),
                    ),
                    onDislike: () {
                      ref.read(dislikeProvider.notifier)
                          .dislike(filtered[i].id, filtered[i].tags);
                      ref.read(learningProvider.notifier)
                          .onDislike(filtered[i].tags);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('覚えたよ。次から表示しないね 🌿'),
                          backgroundColor: MofuColors.mossGreen,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    onFavorite: () {
                      ref.read(favoritesProvider.notifier)
                          .toggle(filtered[i].id);
                      ref.read(learningProvider.notifier)
                          .onFavorite(filtered[i].tags);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('お気に入りに追加したよ ❤️'),
                          backgroundColor: const Color(0xFFE57373),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                  ),
                  childCount: filtered.length,
                ),
              );
            },
          ),
          // インストール案内バナー
          const SliverToBoxAdapter(child: InstallBanner()),
          const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
        ],
        ),
      ),
      ), // NotificationListener
    ),     // Scaffold
      // ── ステータスバー領域タップで最上部へ（モバイル）──────────
      if (!kIsWeb && statusBarHeight > 0)
        Positioned(
          top: 0, left: 0, right: 0,
          height: statusBarHeight,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: _scrollToTop,
          ),
        ),
      ], // Stack
    );
  }
}

class _AppBar extends ConsumerWidget {
  final bool isTired;
  final VoidCallback? onLogoTap;

  const _AppBar({required this.isTired, this.onLogoTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SliverAppBar(
      pinned: true,
      floating: true,
      snap: true,
      backgroundColor: MofuColors.systemBackground,
      surfaceTintColor: Colors.transparent,
      shadowColor: MofuColors.separator,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      titleSpacing: 20,
      toolbarHeight: 52,
      title: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onLogoTap,
        child: Row(
        children: [
          Text(
            'MOFU',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: MofuColors.label,
              letterSpacing: -0.5,
            ),
          ),
          if (isTired) ...[
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: MofuColors.accentSoft,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'おやすみ',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: MofuColors.accent,
                ),
              ),
            ),
          ],
        ],
        ), // GestureDetector(onTap: onLogoTap)
      ),
      actions: [
        // 気分ボタン
        GestureDetector(
          onTap: () => MoodSelectorSheet.show(context),
          child: Container(
            margin: const EdgeInsets.only(right: 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: MofuColors.secondarySystemBackground,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.spa_rounded,
              size: 20,
              color: MofuColors.accent,
            ),
          ),
        ),
        // 更新ボタン
        IconButton(
          onPressed: () => ref.read(feedProvider.notifier).refresh(),
          icon: const Icon(
            Icons.refresh_rounded,
            size: 22,
            color: MofuColors.accent,
          ),
          padding: const EdgeInsets.only(right: 16),
        ),
      ],
    );
  }

}

// 🌿 ヒントバナー（初回のみ表示）
class _LeafHintBanner extends ConsumerWidget {
  final WidgetRef ref;
  const _LeafHintBanner({required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hintShownAsync = ref.watch(_hintShownProvider);
    final hintVisible = ref.watch(_hintVisibleProvider);

    // 表示済み or 非表示状態ならスキップ
    final alreadyShown = hintShownAsync.valueOrNull ?? true;
    if (alreadyShown || !hintVisible) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: AnimatedOpacity(
        opacity: hintVisible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 400),
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F7F0),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: MofuColors.mossGreen.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Text('🌿', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'この画像が苦手だったら\n右下の 🌿 を押してね。次から表示しないよ。',
                  style: TextStyle(
                    fontSize: 13,
                    color: MofuColors.softBrown,
                    height: 1.6,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () async {
                  ref.read(_hintVisibleProvider.notifier).state = false;
                  final sp = await SharedPreferences.getInstance();
                  await sp.setBool('leaf_hint_shown', true);
                },
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Text('✕',
                      style: TextStyle(
                          fontSize: 14, color: MofuColors.textLight)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TiredModeBanner extends StatelessWidget {
  const _TiredModeBanner();

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: MofuColors.softLavender.withOpacity(0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: MofuColors.softLavender),
        ),
        child: const Row(
          children: [
            Text('🫂', style: TextStyle(fontSize: 22)),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'そっとしているね。\nやわらかいものだけ集めてきたよ。',
                style: TextStyle(
                  fontSize: 13,
                  color: MofuColors.softBrown,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
