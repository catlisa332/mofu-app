import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

Future<void> sharePost({
  required BuildContext context,
  required String url,
  required String title,
}) async {
  if (kIsWeb) {
    // Web: クリップボードにコピー → スナックバーで通知
    await Clipboard.setData(ClipboardData(text: '$title\n癒しの動物フィード MOFU\n$url'));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Text('📋', style: TextStyle(fontSize: 16)),
              SizedBox(width: 8),
              Text('URLをコピーしたよ'),
            ],
          ),
          backgroundColor: const Color(0xFF7A9E7E),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  } else {
    // モバイル: share_plus でネイティブ共有シート
    await Share.share(
      '$title\n癒しの動物フィード MOFU\n$url',
      subject: 'MOFUで見つけたよ',
    );
  }
}
