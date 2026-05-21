import 'dart:async';
import 'dart:js_interop';
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

class OfflineBanner extends StatefulWidget {
  final Widget child;
  const OfflineBanner({super.key, required this.child});

  @override
  State<OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends State<OfflineBanner> {
  bool _isOffline = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _check();
    // 5秒ごとにオフライン状態を確認
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _check());
  }

  void _check() {
    final offline = !web.window.navigator.onLine;
    if (offline != _isOffline && mounted) {
      setState(() => _isOffline = offline);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: _isOffline ? 36 : 0,
          color: const Color(0xFF5D4037),
          child: _isOffline
              ? const Center(
                  child: Text(
                    '📡 オフラインです。画像が表示されない場合があります',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                )
              : null,
        ),
        Expanded(child: widget.child),
      ],
    );
  }
}
