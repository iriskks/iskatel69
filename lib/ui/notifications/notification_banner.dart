import 'dart:async';

import 'package:flutter/material.dart';

class NotificationBanner extends StatefulWidget {
  final String title;
  final String? subtitle;
  final Duration duration;
  final VoidCallback onDismiss;

  const NotificationBanner({super.key, required this.title, this.subtitle, required this.duration, required this.onDismiss});

  @override
  State<NotificationBanner> createState() => _NotificationBannerState();
}

class _NotificationBannerState extends State<NotificationBanner> with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _anim.forward();
    _timer = Timer(widget.duration, _close);
  }

  void _close() async {
    await _anim.reverse();
    widget.onDismiss();
  }

  @override
  void dispose() {
    _timer.cancel();
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero).animate(CurvedAnimation(parent: _anim, curve: Curves.easeOut)),
          child: Material(
            elevation: 6,
            borderRadius: BorderRadius.circular(8),
            color: Colors.white,
            child: Container(
              width: media.size.width * 0.92,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.place, color: Colors.blue),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(widget.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                        if (widget.subtitle != null) ...[
                          const SizedBox(height: 4),
                          Text(widget.subtitle!, style: const TextStyle(fontSize: 12, color: Colors.black87)),
                        ]
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _close,
                    icon: const Icon(Icons.close, size: 20),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
