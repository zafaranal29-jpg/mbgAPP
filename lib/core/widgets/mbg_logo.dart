import 'package:flutter/material.dart';
import 'package:mbg_app/core/theme/app_colors.dart';

/// Logo MBG: buku terbuka + toga.
class MbgLogo extends StatelessWidget {
  const MbgLogo({
    super.key,
    this.size = 96,
    this.showText = true,
    this.color = Colors.white,
  });

  final double size;
  final bool showText;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CustomPaint(painter: _LogoPainter(color)),
        ),
        if (showText) ...[
          SizedBox(height: size * 0.08),
          Text(
            'MBG',
            style: TextStyle(
              color: color,
              fontSize: size * 0.3,
              fontWeight: FontWeight.w800,
              letterSpacing: 4,
            ),
          ),
          Text(
            'Makan Bergizi Gratis',
            style: TextStyle(
              color: color.op(0.85),
              fontSize: size * 0.13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}

class _LogoPainter extends CustomPainter {
  _LogoPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 100, size.height / 100);

    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final soft = Paint()
      ..color = color.op(0.72)
      ..style = PaintingStyle.fill;

    // Buku terbuka
    final left = Path()
      ..moveTo(48, 92)
      ..lineTo(48, 58)
      ..quadraticBezierTo(30, 50, 8, 54)
      ..lineTo(8, 88)
      ..quadraticBezierTo(30, 84, 48, 92)
      ..close();
    final right = Path()
      ..moveTo(52, 92)
      ..lineTo(52, 58)
      ..quadraticBezierTo(70, 50, 92, 54)
      ..lineTo(92, 88)
      ..quadraticBezierTo(70, 84, 52, 92)
      ..close();
    canvas.drawPath(left, fill);
    canvas.drawPath(right, fill);

    // Toga: papan + topi + tali
    final board = Path()
      ..moveTo(50, 6)
      ..lineTo(88, 22)
      ..lineTo(50, 38)
      ..lineTo(12, 22)
      ..close();
    canvas.drawPath(board, fill);

    final cap = Path()
      ..moveTo(30, 32)
      ..lineTo(30, 44)
      ..quadraticBezierTo(50, 54, 70, 44)
      ..lineTo(70, 32)
      ..lineTo(50, 40)
      ..close();
    canvas.drawPath(cap, soft);

    final tassel = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(88, 22), const Offset(88, 42), tassel);
    canvas.drawCircle(const Offset(88, 45), 3.2, fill);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _LogoPainter old) => old.color != color;
}
