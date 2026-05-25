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

class DetailScreen extends ConsumerStatefulWidget {
  final VideoPost post;
  const DetailScreen({super.key, required this.post});

  @override
  ConsumerState<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends ConsumerState<DetailScreen> {
  double _dragOffset = 0;

  VideoPost get post => widget.post;

  void _onDragUpdate(DragUpdateDetails d) {
    if (d.delta.dy > 0) setState(() => _dragOffset += d.delta.dy);
  }

  void _onDragEnd(DragEndDetails d) {
    final vel = d.primaryVelocity ?? 0;
    if (vel > 400 || _dragOffset > 160) {
      Navigator.of(context).pop();
    } else {
      setState(() => _dragOffset = 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFav = ref.watch(favoritesProvider).valueOrNull?.contains(post.id) ?? false;
    final isYoutube = post.youtubeVideoId != null;

    if (isYoutube) {
      return _buildYoutubeLayout(context, ref, isFav);
    }

    // 通常画像: 下スワイプで閉じる
    return GestureDetector(
      onVerticalDragUpdate: _onDragUpdate,
      onVerticalDragEnd: _onDragEnd,
      onVerticalDragCancel: () => setState(() => _dragOffset = 0),
      child: Transform.translate(
        offset: Offset(0, _dragOffset.clamp(0, 200)),
        child: Scaffold(
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
              child: const Icon(Icons.share_rounded, color: Colors.white, size: 18),
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
                    child: Icon(Icons.pets, size: 48, color: Color(0x33FFFFFF)),
                  ),
                  errorWidget: (_, __, ___) => const Center(
                    child: Icon(Icons.pets, size: 48, color: Color(0x33FFFFFF)),
                  ),
                ),
              ),
            ),
          ),
          _buildBottomPanel(context, ref, isFav, isYoutube: false),
        ],
      ),
        ),
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
      decoration: BoxDecoration(
        color: isYoutube
            ? const Color(0xFF1C1C1E)          // iOS dark
            : MofuColors.cardBackground,
        borderRadius: isYoutube
            ? BorderRadius.zero
            : const BorderRadius.vertical(bottom: Radius.circular(0)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 動物ラベル + タグ
          Row(
            children: [
              Text(
                _animalLabel(post.animalType),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isYoutube
                      ? Colors.white54
                      : MofuColors.secondaryLabel,
                ),
              ),
              if (post.isAsmr) ...[
                const SizedBox(width: 8),
                _pill('ASMR', isYoutube),
              ],
              const Spacer(),
              CalmScoreBadge(score: post.calmScore),
            ],
          ),
          const SizedBox(height: 10),

          // タグ
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: post.tags.map((t) => _tagChip('#$t', isYoutube)).toList(),
          ),
          const SizedBox(height: 18),

          // アクションボタン行
          Row(
            children: [
              // 閉じる（YouTube のみ）
              if (isYoutube) ...[
                _IconAction(
                  icon: Icons.close_rounded,
                  label: '閉じる',
                  dark: true,
                  onTap: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: 10),
              ],

              // ❤️ お気に入り
              _IconAction(
                icon: isFav ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                label: isFav ? '保存済み' : '保存',
                dark: isYoutube,
                active: isFav,
                onTap: () => ref.read(favoritesProvider.notifier).toggle(post.id),
              ),
              const SizedBox(width: 10),

              // 🌿 苦手
              _IconAction(
                icon: Icons.not_interested_rounded,
                label: '苦手',
                dark: isYoutube,
                onTap: () {
                  ref.read(dislikeProvider.notifier).dislike(post.id, post.tags);
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('次から表示しないね'),
                      backgroundColor: MofuColors.label,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
              const Spacer(),

              // 元投稿へ
              GestureDetector(
                onTap: () => launchUrl(
                  Uri.parse(post.sourceUrl),
                  mode: LaunchMode.externalApplication,
                ),
                child: Row(
                  children: [
                    Text(
                      isYoutube ? 'YouTubeで見る' : '元の投稿',
                      style: TextStyle(
                        fontSize: 13,
                        color: isYoutube
                            ? Colors.white38
                            : MofuColors.secondaryLabel,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 11,
                      color: isYoutube
                          ? Colors.white38
                          : MofuColors.tertiaryLabel,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pill(String text, bool dark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: dark ? Colors.white12 : MofuColors.accentSoft,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: dark ? Colors.white54 : MofuColors.accent,
        ),
      ),
    );
  }

  Widget _tagChip(String text, bool dark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: dark ? Colors.white10 : MofuColors.secondarySystemBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: dark ? Colors.white54 : MofuColors.secondaryLabel,
        ),
      ),
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

class _IconAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool dark;
  final bool active;

  const _IconAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.dark = false,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    final fg = dark
        ? (active ? MofuColors.accent : Colors.white70)
        : (active ? MofuColors.accent : MofuColors.secondaryLabel);
    final bg = dark ? Colors.white10 : MofuColors.secondarySystemBackground;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: fg),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
