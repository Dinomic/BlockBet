import 'package:flutter/material.dart';

/// "Linked blocks" mark: an outlined and a filled rounded square, overlapping.
/// Drawn on a 32x32 grid (see design/DESIGN.md).
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 32, this.color});
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _MarkPainter(color ?? Theme.of(context).colorScheme.primary),
    );
  }
}

class _MarkPainter extends CustomPainter {
  _MarkPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 32;
    final outline = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.4 * s;
    final fill = Paint()..color = color;

    // Stroke is centered on the path, matching the SVG rect (x=3,y=3,w=17,h=17,rx=5).
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(3 * s, 3 * s, 17 * s, 17 * s), Radius.circular(5 * s)),
      outline,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(12 * s, 12 * s, 17 * s, 17 * s), Radius.circular(5 * s)),
      fill,
    );
  }

  @override
  bool shouldRepaint(_MarkPainter old) => old.color != color;
}

class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const BrandMark(),
        const SizedBox(width: 10),
        Text('BlockBet', style: Theme.of(context).textTheme.titleLarge),
      ],
    );
  }
}
