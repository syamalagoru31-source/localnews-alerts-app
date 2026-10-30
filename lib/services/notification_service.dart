import 'dart:js_interop';

import 'package:web/web.dart' as web;

class NotificationService {
  static Future<void> requestPermission() async {
    final permission = await web.Notification.requestPermission().toDart;

    if (permission == 'granted'.toJS) {
      await showNotification(
        title: 'Local News',
        body: 'Notifications are enabled successfully!',
      );
    }
  }

  static Future<void> showNotification({
    required String title,
    required String body,
  }) async {
    if (web.Notification.permission != 'granted') {
      return;
    }

    web.Notification(title, web.NotificationOptions(body: body));
  }
}
