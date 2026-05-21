import 'dart:js_interop';
import 'package:web/web.dart' as web;

const _vapidPublicKey =
    'BJMyplzdiS9A4cgRAiVKUL2EX5wxe_R2nVT9Z_3ePrqijNOT8hLgwWMTICUSZoZGF-shtl-RDBZr4xDHLx6Ynic';

class PushNotificationService {
  static bool get isSupported =>
      web.window.has('Notification') && web.window.has('serviceWorker');

  static Future<bool> requestPermission() async {
    if (!isSupported) return false;
    try {
      final permission =
          await web.window.Notification.requestPermission().toDart;
      return permission == 'granted';
    } catch (_) {
      return false;
    }
  }

  static Future<void> registerServiceWorker() async {
    if (!isSupported) return;
    try {
      await web.window.navigator.serviceWorker
          .register('/mofu-app/mofu-sw.js')
          .toDart;
    } catch (_) {}
  }

  static String get permissionStatus {
    if (!isSupported) return 'unsupported';
    return web.window.Notification.permission;
  }

  static bool get isGranted => permissionStatus == 'granted';
}
