import 'package:flutter/material.dart';
import 'package:mbg_app/core/theme/app_colors.dart';

/// Pola toga & buku transparan sebagai ciri khas sekolah.
class EduPatternPainter extends CustomPainter {
  EduPatternPainter({
    this.color = Colors.white,
    this.opacity = 0.07,
    this.iconSize = 34,
    this.spacing = 80,
  });

  final Color color;
  final double opacity;
  final double iconSize;
  final double spacing;

  static const List<IconData> _icons = [
    Icons.school_rounded, // toga
    Icons.menu_book_rounded, // buku
  ];

  @override
  void paint(Canvas canvas, Size size) {
    var row = 0;
    for (double y = 6; y < size.height + spacing; y += spacing) {
      final shift = row.isEven ? 0.0 : spacing / 2;
      var col = 0;
      for (double x = 8 - shift; x < size.width + spacing; x += spacing) {
        final idx = (row + col) % 2;
        final angle = idx == 0 ? -0.26 : 0.26;
        _drawIcon(canvas, _icons[idx], Offset(x, y), angle);
        col++;
      }
      row++;
    }
  }

  void _drawIcon(Canvas canvas, IconData icon, Offset at, double angle) {
    final tp = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: iconSize,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          color: color.op(opacity),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    canvas.save();
    canvas.translate(at.dx + tp.width / 2, at.dy + tp.height / 2);
    canvas.rotate(angle);
    tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant EduPatternPainter old) =>
      old.opacity != opacity || old.color != color || old.spacing != spacing;
}

/// Latar gradasi biru + pola toga/buku transparan.
class EduBackground extends StatelessWidget {
  const EduBackground({
    super.key,
    required this.child,
    this.gradient = AppColors.mainGradient,
    this.patternOpacity = 0.07,
  });

  final Widget child;
  final Gradient gradient;
  final double patternOpacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(gradient: gradient),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: RepaintBoundary(
              child: CustomPaint(
                painter: EduPatternPainter(opacity: patternOpacity),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}
