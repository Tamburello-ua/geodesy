import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;

class HorizonPainterV2 extends CustomPainter {
  final Quaternion quaternion;
  final double fovY;
  final Size imageSize;

  HorizonPainterV2({
    required this.quaternion,
    required this.fovY,
    required this.imageSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.redAccent
      ..strokeWidth = 2;

    // Вращаем систему на 180° вокруг X, чтобы перейти от "экрана" к "камере"
    final rotationFix = Quaternion.axisAngle(Vector3(1, 0, 0), math.pi);
    final corrected = quaternion * rotationFix;

    // Направления камеры
    final upWorld = Vector3(0, 1, 0);
    final forward = corrected.rotate(Vector3(0, 0, -1));
    final upCamera = corrected.rotate(upWorld);

    // Параметры проекции
    final focal = (size.height / 2) / math.tan(fovY / 2);

    // Угол наклона линии (roll)
    final horizonTilt = math.atan2(upCamera.x, upCamera.y);

    // Вертикальное смещение (pitch)
    final pitch = math.asin(forward.y);
    final horizonOffset = focal * math.tan(pitch);

    // Центр линии горизонта
    final centerY = size.height / 2 + horizonOffset;
    final dx = size.width / 2;

    // Точки линии
    final p1 = Offset(0, centerY - math.tan(horizonTilt) * dx);
    final p2 = Offset(size.width, centerY + math.tan(horizonTilt) * dx);

    canvas.drawLine(p1, p2, paint);
  }

  @override
  bool shouldRepaint(HorizonPainterV2 oldDelegate) =>
      quaternion != oldDelegate.quaternion;
}
