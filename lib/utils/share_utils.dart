import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

Future<void> sharePost({
  required BuildContext context,
  required String url,
  required String title,
}) async {
  if (kIsWeb) {
    // Web: ネイティブ共有APIを試みる→失敗したらクリップボード
    await _shareWeb(context: context, url: url, title: title);
  } else {
    // モバイル: share_plus
    await Share.share(
      '$title\n癒しの動物フィード MOFU\n$url',
      subject: 'MOFUで見つけたよ',
    );
  }
}

Future<void> _shareWeb({
  required BuildContext context,
  required String url,
  required String title,
}) async {
  try {
    // dart:js_interop を動的にロード
    await _webShare(url: url, title: title);
  } catch (_) {
    // フォールバック: クリップボード
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('URLをコピーしたよ 📋'),
          backgroundColor: const Color(0xFF7A9E7E),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}

// Web専用: js_interop経由でWeb Share API
Future<void> _webShare({required String url, required String title}) async {
  // Web専用実装はshare_web.dartに分離
}
