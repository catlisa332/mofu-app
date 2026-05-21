import 'package:flutter/foundation.dart';

// Web専用機能のスタブ（モバイルでは全てfalse）
class PushNotificationService {
  static bool get isSupported => kIsWeb;
  static bool get isGranted => false;

  static Future<bool> requestPermission() async => false;
  static Future<void> registerServiceWorker() async {}
}
