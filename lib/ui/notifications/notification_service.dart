import 'package:flutter/material.dart';
import 'notification_banner.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  void show(BuildContext context, {required String title, String? subtitle, Duration duration = const Duration(seconds: 3)}) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(builder: (_) {
      return NotificationBanner(
        title: title,
        subtitle: subtitle,
        duration: duration,
        onDismiss: () {
          entry.remove();
        },
      );
    });

    overlay.insert(entry);
  }
}
