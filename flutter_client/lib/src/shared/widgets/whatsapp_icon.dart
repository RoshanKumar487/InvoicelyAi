import 'package:flutter/material.dart';

/// Crisp vector WhatsApp brand icon matching the official brand asset.
class WhatsAppIcon extends StatelessWidget {
  const WhatsAppIcon({
    this.size = 20,
    this.color = const Color(0xFF25D366),
    super.key,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _WhatsAppPainter(color: color),
    );
  }
}

class _WhatsAppPainter extends CustomPainter {
  const _WhatsAppPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 24.0;
    canvas.save();
    canvas.scale(scale, scale);

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    // Vector path matching ic_whatsapp.xml
    final path = Path();
    path.moveTo(12.04, 2);
    path.cubicTo(6.58, 2, 2.13, 6.45, 2.13, 11.91);
    path.cubicTo(2.13, 13.66, 2.59, 15.36, 3.45, 16.86);
    path.lineTo(2.05, 22);
    path.lineTo(7.3, 20.62);
    path.cubicTo(8.75, 21.41, 10.38, 21.83, 12.04, 21.83);
    path.cubicTo(17.5, 21.83, 21.95, 17.38, 21.95, 11.92);
    path.cubicTo(21.95, 9.27, 20.92, 6.78, 19.05, 4.91);
    path.cubicTo(17.18, 3.03, 14.69, 2, 12.04, 2);
    path.close();

    // Inner path
    path.moveTo(12.05, 3.67);
    path.cubicTo(14.25, 3.67, 16.31, 4.53, 17.87, 6.09);
    path.cubicTo(19.42, 7.65, 20.28, 9.72, 20.28, 11.92);
    path.cubicTo(20.28, 16.46, 16.58, 20.15, 12.04, 20.15);
    path.cubicTo(10.56, 20.15, 9.11, 19.76, 7.85, 19);
    path.lineTo(7.55, 18.83);
    path.lineTo(4.43, 19.65);
    path.lineTo(5.26, 16.61);
    path.lineTo(5.06, 16.29);
    path.cubicTo(4.24, 14.99, 3.8, 13.47, 3.8, 11.91);
    path.cubicTo(3.81, 7.37, 7.5, 3.67, 12.05, 3.67);
    path.close();

    // Phone handset
    path.moveTo(9.53, 7.4);
    path.cubicTo(9.36, 7.4, 9.08, 7.46, 8.84, 7.72);
    path.cubicTo(8.6, 7.98, 7.92, 8.62, 7.92, 9.92);
    path.cubicTo(7.92, 11.23, 8.87, 12.48, 9.0, 12.65);
    path.cubicTo(9.14, 12.83, 10.87, 15.49, 13.52, 16.63);
    path.cubicTo(14.15, 16.9, 14.64, 17.06, 15.02, 17.18);
    path.cubicTo(15.66, 17.38, 16.24, 17.35, 16.7, 17.29);
    path.cubicTo(17.21, 17.21, 18.28, 16.64, 18.5, 16.01);
    path.cubicTo(18.72, 15.38, 18.72, 14.85, 18.66, 14.73);
    path.cubicTo(18.6, 14.61, 18.43, 14.54, 18.17, 14.41);
    path.cubicTo(17.91, 14.28, 16.65, 13.66, 16.41, 13.58);
    path.cubicTo(16.18, 13.49, 16.01, 13.45, 15.84, 13.71);
    path.cubicTo(15.67, 13.97, 15.19, 14.54, 15.05, 14.71);
    path.cubicTo(14.9, 14.88, 14.76, 14.9, 14.5, 14.77);
    path.cubicTo(14.25, 14.64, 13.43, 14.38, 12.45, 13.51);
    path.cubicTo(11.69, 12.83, 11.18, 12, 11.03, 11.74);
    path.cubicTo(10.88, 11.48, 11.01, 11.34, 11.14, 11.21);
    path.cubicTo(11.26, 11.09, 11.4, 10.91, 11.53, 10.76);
    path.cubicTo(11.66, 10.61, 11.7, 10.5, 11.79, 10.33);
    path.cubicTo(11.87, 10.15, 11.83, 10, 11.77, 9.87);
    path.cubicTo(11.7, 9.74, 11.19, 8.48, 10.97, 7.97);
    path.cubicTo(10.76, 7.46, 10.55, 7.54, 10.39, 7.53);
    path.cubicTo(10.24, 7.52, 10.07, 7.4, 9.53, 7.4);
    path.close();

    path.fillType = PathFillType.evenOdd;
    canvas.drawPath(path, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _WhatsAppPainter oldDelegate) =>
      oldDelegate.color != color;
}
