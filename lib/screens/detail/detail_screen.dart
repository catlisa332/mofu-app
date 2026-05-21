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
    final isYoutube = post.youtubeVideoId != null;

    // YouTube の場合は AppBar なし（iframe が Flutter canvas を覆うため）
    // ✕ ボタンは iframe の下のパネルに配置
    if (isYoutube) {
      return _buildYoutubeLayout(context, ref, isFav);
    }

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 56,
        leading: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Colors.black54,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.close, color: Colors.white, size: 22),
          ),
        ),
        actions: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => sharePost(
              context: context,
              url: post.sourceUrl,
              title: post.tags.take(2).join(' '),
            ),
            child: Container(
              margin: const EdgeInsets.all(8),
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Text('📤', style: TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Hero(
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
          _buildBottomPanel(context, ref, isFav, isYoutube: false),
        ],
      ),
    );
  }

  // YouTube 専用レイアウト（AppBar なし・✕ボタンを下に配置）
  Widget _buildYoutubeLayout(BuildContext context, WidgetRef ref, bool isFav) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // YouTube iframe（上部いっぱい）
            Expanded(
              child: YouTubePlayer(videoId: post.youtubeVideoId!),
            ),
            // 下部パネル（✕ボタンをここに配置）
            _buildBottomPanel(context, ref, isFav, isYoutube: true),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomPanel(
    BuildContext context,
    WidgetRef ref,
    bool isFav, {
    required bool isYoutube,
  }) {
    return Container(
      color: const Color(0xFF1A1410),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
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
                style: const TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // タグ
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: post.tags.map((t) => _tagChip('#$t')).toList(),
          ),
          const SizedBox(height: 16),

          // アクションボタン行
          Row(
            children: [
              // YouTube のときは ✕ 閉じるボタンを左端に大きく表示
              if (isYoutube) ...[
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white12,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.close, color: Colors.white70, size: 18),
                        SizedBox(width: 4),
                        Text('閉じる',
                            style: TextStyle(
                                color: Colors.white70, fontSize: 13)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],

              // ❤️ お気に入り
              _ActionButton(
                emoji: isFav ? '❤️' : '♡',
                label: isFav ? '保存済み' : 'お気に入り',
                onTap: () =>
                    ref.read(favoritesProvider.notifier).toggle(post.id),
              ),
              const SizedBox(width: 8),

              // 🌿 苦手
              _ActionButton(
                emoji: '🌿',
                label: '苦手',
                onTap: () {
                  ref
                      .read(dislikeProvider.notifier)
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

              // 元投稿 / YouTubeで見る
              TextButton(
                onPressed: () => launchUrl(
                  Uri.parse(post.sourceUrl),
                  mode: LaunchMode.externalApplication,
                ),
                child: Text(
                  isYoutube ? 'YouTube →' : '元投稿 →',
                  style: const TextStyle(
                      color: Colors.white38, fontSize: 12),
                ),
              ),
            ],
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
