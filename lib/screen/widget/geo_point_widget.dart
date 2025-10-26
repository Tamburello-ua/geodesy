import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:geodesy/models/marker_detection.dart';
import 'package:geodesy/screen/utils/position_data.dart';

class GeoPointWidget extends StatelessWidget {
  final double azimuth;
  final double finalPitch;
  final List<MarkerDetection> detectedMarkers;
  final double verticalFovDegrees;
  final double horizontalFovDegrees;

  const GeoPointWidget({
    super.key,

    required this.azimuth,
    required this.finalPitch,
    required this.detectedMarkers,
    required this.verticalFovDegrees,
    required this.horizontalFovDegrees,
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
          painter: PathPainter(azimuth: azimuth, distanceCm: distanceCm),
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

  // Стили красок
  final Paint gridPaint = Paint()
    ..color = Colors.white.withOpacity(0.3)
    ..strokeWidth = 1.0
    ..style = PaintingStyle.stroke;

  final Paint axisPaint = Paint()
    ..color = Colors.white.withOpacity(0.5)
    ..strokeWidth = 1.5
    ..style = PaintingStyle.stroke;

  final Paint beamPaint = Paint()
    ..color = Colors.cyanAccent
    ..strokeWidth = 2.0
    ..style = PaintingStyle.stroke;

  final Paint targetPaint = Paint()
    ..color = Colors.orangeAccent
    ..style = PaintingStyle.fill;

  final Paint originPaint = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.fill;

  PathPainter({required this.azimuth, required this.distanceCm});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Определение центра и масштаба

    // Точка старта (пользователь) - внизу по центру
    final Offset originOffset = Offset(size.width / 2, size.height * 0.9);

    // Вычисляем максимальный радиус обзора в см.
    // Округляем distanceCm до ближайших 100 см + 100 см запаса
    // (минимум 100 см)
    final double viewRadiusCm = ((distanceCm / 100.0).ceil() + 1) * 100.0;

    // Доступная высота для рисования (от origin до верха)
    final double availableHeightPx = originOffset.dy;

    // Коэффициент масштабирования: пикселей в одном сантиметре
    final double pixelsPerCm = availableHeightPx / viewRadiusCm;

    // Размер ячейки сетки в пикселях
    final double gridCellSizePx = 100.0 * pixelsPerCm;

    // 2. Отрисовка сетки
    _drawGrid(canvas, size, originOffset, gridCellSizePx, 100);

    // 3. Отрисовка луча и цели
    _drawBeam(canvas, originOffset, pixelsPerCm, azimuth, distanceCm);

    // 4. Отрисовка точки старта (пользователя)
    canvas.drawCircle(originOffset, 5.0, originPaint);
    canvas.drawCircle(originOffset, 2.0, beamPaint);
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

  /// Отрисовка луча и точки назначения
  void _drawBeam(
    Canvas canvas,
    Offset origin,
    double pixelsPerCm,
    double azimuth,
    double distanceCm,
  ) {
    if (distanceCm <= 0) return;

    // Переводим азимут (0 = Север/Вверх) в радианы для canvas
    // 0 градусов (Север) -> -PI/2 (вверх по Y)
    // 90 градусов (Восток) -> 0 (вправо по X)
    final double angleRad = (azimuth - 90.0) * (math.pi / 180.0);

    // Рассчитываем конечную точку в пикселях
    final double distancePx = distanceCm * pixelsPerCm;

    // Координаты X и Y относительно origin
    final double x = distancePx * math.cos(angleRad);
    final double y = distancePx * math.sin(angleRad);

    final Offset targetOffset = Offset(origin.dx + x, origin.dy + y);

    // Рисуем луч
    canvas.drawLine(origin, targetOffset, beamPaint);

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
