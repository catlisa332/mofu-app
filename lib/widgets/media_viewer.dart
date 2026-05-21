import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// URLがGIF/動画かどうか判定してそれぞれ適切なウィジェットを返す
class MediaViewer extends StatefulWidget {
  final String url;
  final BoxFit fit;

  const MediaViewer({super.key, required this.url, this.fit = BoxFit.cover});

  static bool isVideo(String url) {
    final lower = url.toLowerCase();
    return lower.endsWith('.mp4') ||
        lower.endsWith('.webm') ||
        lower.endsWith('.mov') ||
        lower.contains('v.redd.it');
  }

  static bool isGif(String url) => url.toLowerCase().endsWith('.gif');

  @override
  State<MediaViewer> createState() => _MediaViewerState();
}

class _MediaViewerState extends State<MediaViewer> {
  VideoPlayerController? _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    if (MediaViewer.isVideo(widget.url)) {
      _initVideo();
    }
  }

  Future<void> _initVideo() async {
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    await _controller!.initialize();
    _controller!.setLooping(true);
    _controller!.setVolume(0); // デフォルトミュート
    _controller!.play();
    if (mounted) setState(() => _initialized = true);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 動画
    if (MediaViewer.isVideo(widget.url)) {
      if (!_initialized) {
        return Container(
          color: const Color(0xFFEEE8E0),
          child: const Center(child: Text('🐾', style: TextStyle(fontSize: 36))),
        );
      }
      return GestureDetector(
        onTap: () {
          if (_controller!.value.isPlaying) {
            _controller!.pause();
          } else {
            _controller!.play();
          }
          setState(() {});
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            AspectRatio(
              aspectRatio: _controller!.value.aspectRatio,
              child: VideoPlayer(_controller!),
            ),
            if (!_controller!.value.isPlaying)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black38,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.play_arrow,
                    color: Colors.white, size: 32),
              ),
          ],
        ),
      );
    }

    // GIF・画像（CachedNetworkImageで統一）
    return CachedNetworkImage(
      imageUrl: widget.url,
      fit: widget.fit,
      placeholder: (_, __) => Container(
        color: const Color(0xFFEEE8E0),
        child: const Center(child: Text('🐾', style: TextStyle(fontSize: 36))),
      ),
      errorWidget: (_, __, ___) => Container(
        color: const Color(0xFFEEE8E0),
        child: const Center(child: Text('🐾', style: TextStyle(fontSize: 36))),
      ),
    );
  }
}
