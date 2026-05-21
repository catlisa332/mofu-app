import 'dart:js_interop';
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

Future<void> sharePost({
  required BuildContext context,
  required String url,
  required String title,
}) async {
  try {
    final data = web.ShareData(
      title: 'MOFUで見つけたよ 🐾',
      text: '$title\n癒しの動物フィード MOFU',
      url: url,
    );

    if (web.window.navigator.canShare(data)) {
      await web.window.navigator.share(data).toDart;
      return;
    }
  } catch (_) {}

  // フォールバック: クリップボードにコピー
  try {
    await web.window.navigator.clipboard.writeText(url).toDart;
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('URLをコピーしたよ 📋'),
          backgroundColor: const Color(0xFF7A9E7E),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  } catch (_) {}
}
