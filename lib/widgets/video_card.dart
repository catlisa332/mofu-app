import 'package:flutter/material.dart';
import '../models/video_post.dart';
import '../theme/app_theme.dart';
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
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: AspectRatio(
            aspectRatio: 4 / 3,
            child: MediaViewer(url: post.thumbnailUrl, fit: BoxFit.cover),
          ),
        ),
      ),
    );
  }
}
