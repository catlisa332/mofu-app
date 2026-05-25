import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/video_post.dart';
import '../providers/favorites_provider.dart';
import '../providers/feed_provider.dart';
import '../screens/detail/detail_screen.dart';
import '../theme/app_theme.dart';
import '../widgets/calm_score_badge.dart';

// 今日の日付シードで毎日同じ投稿を選ぶ
final dailyPickProvider = Provider<AsyncValue<VideoPost?>>((ref) {
  final feedAsync = ref.watch(feedProvider);
  return feedAsync.whenData((posts) {
    if (posts.isEmpty) return null;
    final today = DateTime.now();
    final seed = today.year * 10000 + today.month * 100 + today.day;
    // Calm Score高めの投稿からピック
    final calm = posts.where((p) => p.calmScore >= 0.80).toList();
    if (calm.isEmpty) return posts[seed % posts.length];
    return calm[seed % calm.length];
  });
});

class DailyPickCard extends ConsumerWidget {
  const DailyPickCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pickAsync = ref.watch(dailyPickProvider);

    return pickAsync.when(
      loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
      error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
      data: (post) {
        if (post == null) return const SliverToBoxAdapter(child: SizedBox.shrink());
        final isFav = ref.watch(favoritesProvider).valueOrNull?.contains(post.id) ?? false;

        return SliverToBoxAdapter(
          child: GestureDetector(
            onTap: () => Navigator.of(context).push(
              PageRouteBuilder(
                pageBuilder: (_, __, ___) => DetailScreen(post: post),
                transitionsBuilder: (_, anim, __, child) =>
                    FadeTransition(opacity: anim, child: child),
                transitionDuration: const Duration(milliseconds: 250),
              ),
            ),
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: MofuColors.warmTan.withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  children: [
                    // 画像
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child: CachedNetworkImage(
                        imageUrl: post.thumbnailUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                            color: MofuColors.softPeach,
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.all(18),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFECE6DF),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.pets, size: 32, color: MofuColors.accent),
                              ),
                            )),
                        errorWidget: (_, __, ___) => Container(
                            color: MofuColors.softPeach,
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.all(18),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFECE6DF),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.pets, size: 32, color: MofuColors.accent),
                              ),
                            )),
                      ),
                    ),
                    // グラデーション
                    Positioned.fill(
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Color(0xCC000000),
                            ],
                            stops: [0.4, 1.0],
                          ),
                        ),
                      ),
                    ),
                    // 「今日のモフ」バッジ（左上）
                    Positioned(
                      top: 12, left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: MofuColors.warmTan,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.pets, size: 12, color: Colors.white),
                            SizedBox(width: 4),
                            Text('今日のモフ',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                )),
                          ],
                        ),
                      ),
                    ),
                    // ❤️ ボタン（右上）
                    Positioned(
                      top: 8, right: 8,
                      child: GestureDetector(
                        onTap: () => ref
                            .read(favoritesProvider.notifier)
                            .toggle(post.id),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black38,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            isFav ? '❤️' : '♡',
                            style: const TextStyle(fontSize: 18),
                          ),
                        ),
                      ),
                    ),
                    // 下部テキスト
                    Positioned(
                      bottom: 12, left: 14, right: 14,
                      child: Row(
                        children: [
                          CalmScoreBadge(score: post.calmScore),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              post.tags.take(3).map((t) => '#$t').join('  '),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
