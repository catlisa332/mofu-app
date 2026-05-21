import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/feed_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/calm_score_badge.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favIds = ref.watch(favoritesProvider).valueOrNull ?? {};
    final feedAsync = ref.watch(feedProvider);

    final favPosts = feedAsync.valueOrNull
            ?.where((p) => favIds.contains(p.id))
            .toList() ??
        [];

    return Scaffold(
      backgroundColor: MofuColors.cream,
      appBar: AppBar(
        backgroundColor: MofuColors.cream,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Row(
          children: [
            Text('❤️', style: TextStyle(fontSize: 20)),
            SizedBox(width: 8),
            Text('お気に入り',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w300,
                  letterSpacing: 2,
                  color: MofuColors.textDark,
                )),
          ],
        ),
      ),
      body: favPosts.isEmpty
          ? _buildEmpty()
          : GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 0.85,
              ),
              itemCount: favPosts.length,
              itemBuilder: (_, i) {
                final post = favPosts[i];
                return GestureDetector(
                  onLongPress: () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                        title: const Text('お気に入りから外す？',
                            style: TextStyle(fontSize: 17)),
                        content: const Text('この画像をお気に入りから削除します。'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('やっぱりやめる',
                                style:
                                    TextStyle(color: MofuColors.textLight)),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('外す',
                                style:
                                    TextStyle(color: Color(0xFFE07B5A))),
                          ),
                        ],
                      ),
                    );
                    if (ok == true) {
                      ref.read(favoritesProvider.notifier).toggle(post.id);
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: MofuColors.warmTan.withOpacity(0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CachedNetworkImage(
                            imageUrl: post.thumbnailUrl,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                              color: MofuColors.softPeach,
                              child: const Center(
                                child: Text('🐾',
                                    style: TextStyle(fontSize: 32)),
                              ),
                            ),
                            errorWidget: (_, __, ___) => Container(
                              color: MofuColors.softPeach,
                              child: const Center(
                                child: Text('🐾',
                                    style: TextStyle(fontSize: 32)),
                              ),
                            ),
                          ),
                          // 下グラデーション
                          Positioned(
                            bottom: 0, left: 0, right: 0,
                            child: Container(
                              height: 56,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    Colors.black.withOpacity(0.4),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // タグ
                          Positioned(
                            bottom: 8, left: 8,
                            child: Text(
                              post.tags.take(1).map((t) => '#$t').join(),
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500),
                            ),
                          ),
                          // Calm Score
                          Positioned(
                            top: 8, left: 8,
                            child: CalmScoreBadge(score: post.calmScore),
                          ),
                          // ❤️
                          const Positioned(
                            top: 8, right: 8,
                            child: Text('❤️',
                                style: TextStyle(fontSize: 14)),
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

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('❤️', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 16),
          const Text('まだお気に入りがないよ',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w300,
                  color: MofuColors.textDark)),
          const SizedBox(height: 8),
          Text('右にスワイプすると保存できるよ',
              style: TextStyle(fontSize: 13, color: MofuColors.textLight)),
          const SizedBox(height: 24),
          Text('長押しすると外せます',
              style: TextStyle(fontSize: 11, color: MofuColors.textLight)),
        ],
      ),
    );
  }
}
