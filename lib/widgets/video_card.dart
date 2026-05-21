import 'package:flutter/material.dart';
import '../models/video_post.dart';
import '../theme/app_theme.dart';
import '../utils/share_utils.dart';
import 'calm_score_badge.dart';
import 'media_viewer.dart';

class VideoCard extends StatelessWidget {
  final VideoPost post;
  final bool isFavorited;
  final VoidCallback? onTap;
  final VoidCallback? onDislike;
  final VoidCallback? onFavorite;

  const VideoCard({
    super.key,
    required this.post,
    this.isFavorited = false,
    this.onTap,
    this.onDislike,
    this.onFavorite,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: MofuColors.warmTan.withOpacity(0.10),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildThumbnail(),
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail() {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: Stack(
        children: [
          AspectRatio(
            aspectRatio: 4 / 3,
            child: MediaViewer(url: post.thumbnailUrl, fit: BoxFit.cover),
          ),
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: Container(
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Calm Score（左上）
          Positioned(
            top: 12, left: 12,
            child: CalmScoreBadge(score: post.calmScore),
          ),
          // ASMRバッジ（右上）
          // YouTube再生ボタン（中央）
          if (post.youtubeVideoId != null)
            Positioned.fill(
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.play_arrow,
                      color: Colors.white, size: 36),
                ),
              ),
            ),
          if (post.youtubeVideoId != null)
            Positioned(
              top: 12, right: 12,
              child: _badge('▶ YouTube', const Color(0xFFFF0000)),
            )
          else if (post.isGif)
            Positioned(
              top: 12, right: 12,
              child: _badge('GIF', const Color(0xFF9C6FD6)),
            )
          else if (post.isAsmr)
            Positioned(
              top: 12, right: 12,
              child: _badge('🎵 ASMR', MofuColors.mossGreen),
            ),
          // ❤️ お気に入り（画像右下）
          if (onFavorite != null)
            Positioned(
              bottom: 10, right: 12,
              child: GestureDetector(
                onTap: onFavorite,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.85),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (child, anim) =>
                        ScaleTransition(scale: anim, child: child),
                    child: Text(
                      isFavorited ? '❤️' : '♡',
                      key: ValueKey(isFavorited),
                      style: TextStyle(
                        fontSize: 18,
                        color: isFavorited ? null : MofuColors.textLight,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 12, 12),
      child: Row(
        children: [
          // 🌿 苦手（左端）
          if (onDislike != null)
            GestureDetector(
              onTap: onDislike,
              child: const Padding(
                padding: EdgeInsets.only(right: 6),
                child: Text('🌿', style: TextStyle(fontSize: 18)),
              ),
            ),
          // タグ
          Expanded(
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              children: post.tags.take(3).map((t) => _tag('#$t')).toList(),
            ),
          ),
          // 📤 シェア（右端）
          GestureDetector(
            onTap: () => sharePost(
              context: context,
              url: post.sourceUrl,
              title: post.tags.take(2).map((t) => '#$t').join(' '),
            ),
            child: const Padding(
              padding: EdgeInsets.only(left: 6),
              child: Text('📤', style: TextStyle(fontSize: 18)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: MofuColors.softPeach,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text,
          style: const TextStyle(
              fontSize: 11,
              color: MofuColors.softBrown,
              fontWeight: FontWeight.w500)),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.85),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(text,
          style: const TextStyle(
              fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600)),
    );
  }
}
