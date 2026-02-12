import 'package:flutter/material.dart';

class AnimatedMarker extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const AnimatedMarker({super.key, required this.child, required this.onTap});

  @override
  State<AnimatedMarker> createState() => _AnimatedMarkerState();
}

class _AnimatedMarkerState extends State<AnimatedMarker> with SingleTickerProviderStateMixin {
  double _scale = 1.0;

  void _onTapDown(TapDownDetails _) => setState(() => _scale = 1.12);
  void _onTapUp(TapUpDetails _) {
    setState(() => _scale = 1.0);
    widget.onTap();
  }

  void _onTapCancel() => setState(() => _scale = 1.0);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutBack,
        child: widget.child,
      ),
    );
  }
}
