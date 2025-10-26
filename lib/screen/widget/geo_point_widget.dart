import 'dart:math' as math;
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geodesy/models/marker_detection.dart';
import 'package:geodesy/screen/utils/position_data.dart';

class GeoPointWidget extends StatelessWidget {
  final double azimuth;
  final double finalPitch;
  final List<MarkerDetection> detectedMarkers;
  final double verticalFovDegrees;
  final double horizontalFovDegrees;
  final double targetPointY;
  final double originalFrameWidth;

  const GeoPointWidget({
    super.key,

    required this.azimuth,
    required this.finalPitch,
    required this.detectedMarkers,
    required this.verticalFovDegrees,
    required this.horizontalFovDegrees,
    required this.targetPointY,
    required this.originalFrameWidth,
  });

  @override
  Widget build(BuildContext context) {
    var data = getPositionData(detectedMarkers, finalPitch);
    var distanceCm = data['distance_cm'] ?? 0.0;

    return Container(
      color: Colors.white.withValues(alpha: 0.20),

      child: AspectRatio(
        aspectRatio: 1.0,

        child: CustomPaint(
          painter: PathPainter(
            azimuth: azimuth,
            distanceCm: distanceCm,
            horizontalFovDegrees: horizontalFovDegrees,
            targetPointY: targetPointY,
            originalFrameWidth: originalFrameWidth,
          ),
          child: Container(),
        ),
        // ),
      ),
    );
  }
}

class PathPainter extends CustomPainter {
  final double azimuth;
  final double distanceCm;
  final double horizontalFovDegrees;

  final double targetPointY;
  final double originalFrameWidth;

  double offsetXInoriginalFrame = 0.0;

  // Стили красок
  final Paint gridPaint = Paint()
    ..color = Colors.white.withValues(alpha: 0.3)
    ..strokeWidth = 1.0
    ..style = PaintingStyle.stroke;

  final Paint axisPaint = Paint()
    ..color = Colors.white.withValues(alpha: 0.5)
    ..strokeWidth = 1.5
    ..style = PaintingStyle.stroke;

  final Paint beamPaint = Paint()
    ..color = Colors.cyanAccent.withValues(alpha: 0.5)
    ..strokeWidth = 2.0
    ..style = PaintingStyle.stroke;

  final Paint targetPaint = Paint()
    ..color = Colors.orangeAccent
    ..style = PaintingStyle.fill;

  final Paint originPaint = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.fill;

  PathPainter({
    required this.azimuth,
    required this.distanceCm,
    required this.horizontalFovDegrees,
    required this.targetPointY,
    required this.originalFrameWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Offset originOffset = Offset(size.width / 2, size.height * 0.9);
    final double viewRadiusCm = ((distanceCm / 100.0).ceil() + 1) * 100.0;
    final double availableHeightPx = originOffset.dy;
    final double pixelsPerCm = availableHeightPx / viewRadiusCm;
    final double gridCellSizePx = 100.0 * pixelsPerCm;

    _drawGrid(canvas, size, originOffset, gridCellSizePx, 100);
    _drawFOVCone(canvas, originOffset, pixelsPerCm, azimuth, distanceCm);

    offsetXInoriginalFrame = calculateOffsetFromCenter(
      originalFrameWidth,
      targetPointY,
    );

    _drawTargetPoint(
      canvas,
      originOffset,
      pixelsPerCm,
      azimuth,
      distanceCm,
      offsetXInoriginalFrame,
    );

    canvas.drawCircle(originOffset, 5.0, originPaint);
    canvas.drawCircle(originOffset, 2.0, beamPaint);
  }

  double calculateOffsetFromCenter(double totalWidth, double position) {
    double center = totalWidth / 2;
    double offset = position - center;
    double percentage = (offset / center) * 100;
    return percentage;
  }

  void _drawFOVCone(
    Canvas canvas,
    Offset origin,
    double pixelsPerCm,
    double azimuth,
    double distanceCm,
  ) {
    if (distanceCm <= 0) return;

    final double angleRad = (azimuth - 90.0) * (math.pi / 180.0);

    final double distancePx = distanceCm * pixelsPerCm * 1.5;

    // Половина угла FOV в радианах
    final double halfFovRad = (horizontalFovDegrees / 2) * (math.pi / 180.0);

    // Левые и правые лучи конуса
    final double leftAngle = angleRad - halfFovRad;
    final double rightAngle = angleRad + halfFovRad;

    final Offset leftOffset = Offset(
      origin.dx + distancePx * math.cos(leftAngle),
      origin.dy + distancePx * math.sin(leftAngle),
    );

    final Offset rightOffset = Offset(
      origin.dx + distancePx * math.cos(rightAngle),
      origin.dy + distancePx * math.sin(rightAngle),
    );

    // Рисуем линии конуса
    canvas.drawLine(origin, leftOffset, beamPaint);
    canvas.drawLine(origin, rightOffset, beamPaint);

    // Можно замкнуть треугольник, если хочешь прозрачный конус:
    final Path conePath = Path()
      ..moveTo(origin.dx, origin.dy)
      ..lineTo(leftOffset.dx, leftOffset.dy)
      ..lineTo(rightOffset.dx, rightOffset.dy)
      ..close();

    final Paint conePaint = Paint()
      ..color = Colors.yellow.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    canvas.drawPath(conePath, conePaint);
  }

  /// Отрисовка масштабируемой сетки
  void _drawGrid(
    Canvas canvas,
    Size size,
    Offset origin,
    double gridCellSizePx,
    double labelStepCm,
  ) {
    // Рисуем главные оси (X и Y)
    // Ось Y (вверх)
    canvas.drawLine(
      Offset(origin.dx, origin.dy),
      Offset(origin.dx, 0),
      axisPaint,
    );
    // Ось X (горизонталь)
    canvas.drawLine(
      Offset(0, origin.dy),
      Offset(size.width, origin.dy),
      axisPaint,
    );

    final textStyle = TextStyle(
      color: Colors.white.withOpacity(0.6),
      fontSize: 10,
    );

    // Горизонтальные линии сетки (вверх)
    int i = 1;
    double y;
    while ((y = origin.dy - i * gridCellSizePx) > 0) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
      // Метка на оси Y
      _drawText(
        canvas,
        '${(i * labelStepCm).toInt()}',
        Offset(origin.dx + 5, y), // С небольшим отступом от оси
        textStyle,
      );
      i++;
    }

    // Вертикальные линии сетки (вправо)
    i = 1;
    double xRight;
    while ((xRight = origin.dx + i * gridCellSizePx) < size.width) {
      canvas.drawLine(
        Offset(xRight, 0),
        Offset(xRight, size.height),
        gridPaint,
      );
      // Метка на оси X
      _drawText(
        canvas,
        '${(i * labelStepCm).toInt()}',
        Offset(xRight + 5, origin.dy + 5), // С небольшим отступом от оси
        textStyle,
      );
      i++;
    }

    // Вертикальные линии сетки (влево)
    i = 1;
    double xLeft;
    while ((xLeft = origin.dx - i * gridCellSizePx) > 0) {
      canvas.drawLine(Offset(xLeft, 0), Offset(xLeft, size.height), gridPaint);
      i++;
    }
  }

  double calculateDistanceFromBisectorIntersection(
    double bisectorLength,
    double knownAngle,
    double offsetPercent,
  ) {
    double halfAngleRad = (knownAngle / 2) * pi / 180;
    double halfSide = bisectorLength * tan(halfAngleRad);
    double fullSide = halfSide * 2;

    double distanceFromCenter = (fullSide / 2) * (offsetPercent / 100);

    return distanceFromCenter; //.abs();
  }

  /// Отрисовка  точки назначения
  void _drawTargetPoint(
    Canvas canvas,
    Offset origin,
    double pixelsPerCm,
    double azimuth,
    double distanceCm,
    double offsetXInoriginalFrame,
  ) {
    if (distanceCm <= 0) return;

    final double angleRad = (azimuth - 90.0) * (math.pi / 180.0);

    // Рассчитываем конечную точку в пикселях
    final double distancePx = distanceCm * pixelsPerCm;

    // Координаты X и Y относительно origin
    final double x = distancePx * math.cos(angleRad);
    final double y = distancePx * math.sin(angleRad);

    final Offset targetOffset = Offset(
      origin.dx +
          x -
          calculateDistanceFromBisectorIntersection(
            distancePx,
            horizontalFovDegrees,
            offsetXInoriginalFrame,
          ),
      origin.dy + y,
    );

    // Рисуем маркер цели
    canvas.drawCircle(targetOffset, 6.0, targetPaint);
  }

  /// Вспомогательная функция для отрисовки текста
  void _drawText(Canvas canvas, String text, Offset offset, TextStyle style) {
    final textSpan = TextSpan(text: text, style: style);
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(minWidth: 0, maxWidth: 100);
    textPainter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant PathPainter oldDelegate) {
    return azimuth != oldDelegate.azimuth ||
        distanceCm != oldDelegate.distanceCm;
  }
}
