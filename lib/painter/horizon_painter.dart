import 'package:flutter/material.dart';

class HorizonPainter extends CustomPainter {
  final double azimuth, pitch, roll, azimuth0;
  HorizonPainter(this.azimuth, this.pitch, this.roll, this.azimuth0);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    final paintH = Paint()
      ..color = Colors.red
      ..strokeWidth = 2;

    // Линия горизонта: угол roll, смещение pitch
    final dx = size.width;
    final dy = pitch * 50; // масштаб смещения по вертикали
    final angle = -roll;

    final p1 = Offset(center.dx - dx, center.dy + dy) +
        Offset.fromDirection(angle, dx);
    final p2 = Offset(center.dx + dx, center.dy + dy) +
        Offset.fromDirection(angle, -dx);

    canvas.drawLine(p1, p2, paintH);

    // Вертикальная линия по азимуту
    final paintV = Paint()
      ..color = Colors.green
      ..strokeWidth = 2;

    final delta =
        (azimuth - azimuth0) * (size.width / 90); // 90° = ширина экрана
    final x = center.dx - delta;

    canvas.drawLine(Offset(x, 0), Offset(x, size.height), paintV);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
