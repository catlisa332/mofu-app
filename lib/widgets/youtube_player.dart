import 'dart:ui_web' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:web/web.dart' as web;

// 登録済みviewTypeを管理
final _registered = <String>{};

class YouTubePlayer extends StatefulWidget {
  final String videoId;
  const YouTubePlayer({super.key, required this.videoId});

  @override
  State<YouTubePlayer> createState() => _YouTubePlayerState();
}

class _YouTubePlayerState extends State<YouTubePlayer> {
  @override
  void initState() {
    super.initState();
    if (kIsWeb) _register();
  }

  void _register() {
    final viewType = 'yt-${widget.videoId}';
    if (_registered.contains(viewType)) return;
    _registered.add(viewType);

    ui.platformViewRegistry.registerViewFactory(viewType, (int viewId) {
      final iframe =
          web.document.createElement('iframe') as web.HTMLIFrameElement;
      iframe.src = 'https://www.youtube.com/embed/${widget.videoId}'
          '?autoplay=1'
          '&mute=1'
          '&loop=1'
          '&playlist=${widget.videoId}'
          '&controls=1'
          '&rel=0'
          '&playsinline=1'
          '&modestbranding=1';
      iframe.style.border = 'none';
      iframe.style.width = '100%';
      iframe.style.height = '100%';
      iframe.setAttribute('allow',
          'autoplay; fullscreen; picture-in-picture; clipboard-write');
      iframe.setAttribute('allowfullscreen', '');
      return iframe;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) {
      // モバイル：YouTubeアプリで開くボタン
      return Container(
        color: Colors.black,
        child: Center(
          child: ElevatedButton.icon(
            onPressed: () => launchUrl(
              Uri.parse('https://youtu.be/${widget.videoId}'),
              mode: LaunchMode.externalApplication,
            ),
            icon: const Icon(Icons.play_circle_outline),
            label: const Text('YouTubeで見る'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF0000),
              foregroundColor: Colors.white,
            ),
          ),
        ),
      );
    }

    return HtmlElementView(viewType: 'yt-${widget.videoId}');
  }
}
