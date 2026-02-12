import 'package:flutter/material.dart';
import 'app_themes.dart';

class ThemedScaffold extends StatelessWidget {
  final AppThemeVariant variant;
  final AppBar? appBar;
  final Widget body;
  final Widget? floatingActionButton;

  const ThemedScaffold({super.key, this.variant = AppThemeVariant.calm, this.appBar, required this.body, this.floatingActionButton});

  @override
  Widget build(BuildContext context) {
    final bg = AppThemes.backgroundFor(variant);
    final accent = AppThemes.accentFor(variant);

    return Scaffold(
      appBar: appBar != null
          ? AppBar(
              title: appBar!.title,
              actions: appBar!.actions,
              backgroundColor: accent,
              foregroundColor: Colors.white,
            )
          : null,
      backgroundColor: bg,
      body: SafeArea(child: body),
      floatingActionButton: floatingActionButton,
    );
  }
}
