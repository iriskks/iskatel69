import 'package:flutter/material.dart';

class AnimatedCategoryButton extends StatefulWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const AnimatedCategoryButton({super.key, required this.icon, required this.title, required this.onTap});

  @override
  State<AnimatedCategoryButton> createState() => _AnimatedCategoryButtonState();
}

class _AnimatedCategoryButtonState extends State<AnimatedCategoryButton> {
  double _scale = 1.0;

  void _onTapDown(TapDownDetails _) => setState(() => _scale = 0.92);
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
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(widget.icon, color: Colors.blue),
            const SizedBox(height: 4),
            Text(widget.title, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
