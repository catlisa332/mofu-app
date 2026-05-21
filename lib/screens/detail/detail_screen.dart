import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/video_post.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/dislike_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/share_utils.dart';
import '../../widgets/calm_score_badge.dart';
import '../../widgets/youtube_player.dart';

class DetailScreen extends ConsumerWidget {
  final VideoPost post;

  const DetailScreen({super.key, required this.post});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFav = ref.watch(favoritesProvider).valueOrNull?.contains(post.id) ?? false;

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.black38,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.close, color: Colors.white, size: 20),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          // シェア
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.black38,
                shape: BoxShape.circle,
              ),
              child: const Text('📤', style: TextStyle(fontSize: 16)),
            ),
            onPressed: () => sharePost(
              context: context,
              url: post.sourceUrl,
              title: post.tags.take(2).join(' '),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // 動画 or 画像（ヒーロー）
          Expanded(
            child: post.youtubeVideoId != null
                ? YouTubePlayer(videoId: post.youtubeVideoId!)
                : Hero(
                    tag: 'post_${post.id}',
                    child: InteractiveViewer(
                      child: CachedNetworkImage(
                        imageUrl: post.thumbnailUrl,
                        fit: BoxFit.contain,
                        placeholder: (_, __) => const Center(
                          child: Text('🐾', style: TextStyle(fontSize: 56)),
                        ),
                        errorWidget: (_, __, ___) => const Center(
                          child: Text('🐾', style: TextStyle(fontSize: 56)),
                        ),
                      ),
                    ),
                  ),
          ),

          // 下部パネル
          Container(
            color: const Color(0xFF1A1410),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Calm Score + タグ行
                Row(
                  children: [
                    CalmScoreBadge(score: post.calmScore),
                    if (post.isAsmr) ...[
                      const SizedBox(width: 8),
                      _darkBadge('🎵 ASMR'),
                    ],
                    const Spacer(),
                    Text(
                      _animalLabel(post.animalType),
                      style: const TextStyle(
                          color: Colors.white38, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // タグ
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: post.tags
                      .map((t) => _tagChip('#$t'))
                      .toList(),
                ),
                const SizedBox(height: 20),

                // アクションボタン行
                Row(
                  children: [
                    // ❤️ お気に入り
                    _ActionButton(
                      emoji: isFav ? '❤️' : '♡',
                      label: isFav ? '保存済み' : 'お気に入り',
                      onTap: () {
                        ref.read(favoritesProvider.notifier).toggle(post.id);
                      },
                    ),
                    const SizedBox(width: 12),

                    // 🌿 苦手
                    _ActionButton(
                      emoji: '🌿',
                      label: '苦手',
                      onTap: () {
                        ref.read(dislikeProvider.notifier)
                            .dislike(post.id, post.tags);
                        Navigator.of(context).pop();
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
                    ),
                    const Spacer(),

                    // 元投稿を開く
                    TextButton(
                      onPressed: () => launchUrl(
                        Uri.parse(post.sourceUrl),
                        mode: LaunchMode.externalApplication,
                      ),
                      child: Text(
                        post.youtubeVideoId != null ? 'YouTubeで見る →' : '元投稿 →',
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _darkBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: MofuColors.mossGreen.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: MofuColors.mossGreen.withOpacity(0.5)),
      ),
      child: Text(text,
          style: const TextStyle(color: Colors.white70, fontSize: 11)),
    );
  }

  Widget _tagChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(text,
          style: const TextStyle(color: Colors.white54, fontSize: 12)),
    );
  }

  String _animalLabel(AnimalType type) {
    return switch (type) {
      AnimalType.cat => '🐱 猫',
      AnimalType.dog => '🐶 犬',
      AnimalType.smallAnimal => '🐹 小動物',
      AnimalType.bird => '🐦 鳥',
      AnimalType.otter => '🦦 カワウソ',
      AnimalType.capybara => '🦫 カピバラ',
      AnimalType.reptile => '🦎 爬虫類',
      AnimalType.seaCreature => '🐠 海の生き物',
      AnimalType.mixedSpecies => '🐾 異種',
      AnimalType.babyAnimal => '🍼 赤ちゃん',
    };
  }
}

class _ActionButton extends StatelessWidget {
  final String emoji;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.emoji,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(
                    color: Colors.white70, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
