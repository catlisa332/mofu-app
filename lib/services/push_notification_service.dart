import 'dart:js_interop';
import 'package:web/web.dart' as web;

@JS('Notification.permission')
external JSString? get _notificationPermission;

@JS('Notification.requestPermission')
external JSPromise<JSString> _requestPermission();

@JS('typeof Notification')
external JSString get _notificationType;

class PushNotificationService {
  static bool get isSupported {
    try {
      return _notificationType.toDart != 'undefined';
    } catch (_) {
      return false;
    }
  }

  static String get permissionStatus {
    try {
      return _notificationPermission?.toDart ?? 'default';
    } catch (_) {
      return 'default';
    }
  }

  static bool get isGranted => permissionStatus == 'granted';

  static Future<bool> requestPermission() async {
    if (!isSupported) return false;
    try {
      final result = await _requestPermission().toDart;
      return result.toDart == 'granted';
    } catch (_) {
      return false;
    }
  }

  static Future<void> registerServiceWorker() async {
    try {
      await web.window.navigator.serviceWorker
          .register('/mofu-app/mofu-sw.js'.toJS)
          .toDart;
    } catch (_) {}
  }
}
