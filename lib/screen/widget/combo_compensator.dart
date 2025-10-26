import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'dart:math';

Widget ComboCompensator(
  double finalPitch,
  double finalRoll,
  double finalYaw,
  // double verticalFovDegrees,
) {
  final double compensatedTilt = finalPitch;
  final double compensatedRotation = finalRoll;

  double yawInDegrees = finalYaw * 180 / pi;
  yawInDegrees = (yawInDegrees + 360) % 360; // Нормализация в [0, 360]

  return Stack(
    children: [
      Align(
        alignment: Alignment.topCenter,
        child: Column(
          children: [
            Text(
              'Roll (Крен): ${(finalRoll * 180 / pi).toStringAsFixed(1)}°',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            Text(
              'Pitch (Тангаж): ${(finalPitch * 180 / pi).toStringAsFixed(1)}°',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            Text(
              'Azimuth: ${(yawInDegrees).toStringAsFixed(1)}°',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      ),
      // CustomPaint(
      //   size: const Size(double.infinity, double.infinity),
      //   painter: _ComboPainter(
      //     compensatedTilt,
      //     compensatedRotation,
      //     verticalFovDegrees,
      //   ),
      // ),
    ],
  );
}

class _ComboPainter extends CustomPainter {
  final double pitch;
  final double rotation;
  final double verticalFovDegrees;

  _ComboPainter(this.pitch, this.rotation, this.verticalFovDegrees);

  @override
  void paint(Canvas canvas, Size size) {
    final double verticalFovRadians = verticalFovDegrees * math.pi / 180.0;

    final double shiftFactor = size.height / verticalFovRadians;
    final double verticalShift = pitch * shiftFactor;

    final Paint paint = Paint()
      ..color = Colors.cyanAccent
      ..strokeWidth = 1.0;
    final Paint paint2 = Paint()
      ..color = Colors.yellow[800]!
      ..strokeWidth = 1.0;

    final Offset center = Offset(size.width / 2, size.height / 2);

    final Offset horizonpalDx = Offset(
      size.width / 2,
      size.height / 2 + verticalShift,
    );

    final double halfWidth = size.width / 2.0;

    final double dx = cos(rotation) * halfWidth;
    final double dy = sin(rotation) * halfWidth;

    final Offset p1 = Offset(horizonpalDx.dx - dx, horizonpalDx.dy - dy);
    final Offset p2 = Offset(horizonpalDx.dx + dx, horizonpalDx.dy + dy);

    final Offset p21 = Offset(center.dx, center.dy - 20);
    final Offset p22 = Offset(center.dx, center.dy + 20);

    final Offset p23 = Offset(center.dx - 20, center.dy);
    final Offset p24 = Offset(center.dx + 20, center.dy);

    canvas.drawLine(p1, p2, paint);
    canvas.drawLine(p21, p22, paint2);
    canvas.drawLine(p23, p24, paint2);

    final Paint limitPaint = Paint()
      ..color = Colors.red
      ..strokeWidth = 1.0;

    canvas.drawLine(
      Offset(0, size.height),
      Offset(size.width, size.height),
      limitPaint,
    ); // Нижний край
    canvas.drawLine(Offset(0, 0), Offset(size.width, 0), limitPaint); // Верх
  }

  @override
  bool shouldRepaint(covariant _ComboPainter oldDelegate) {
    return oldDelegate.pitch != pitch || oldDelegate.rotation != rotation;
  }
}
