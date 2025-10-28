import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geodesy/models/marker_detection.dart';
import 'package:geodesy/screen/utils/geodesy_utils.dart';

/// Кастомный painter для отображения ArUco-маркеров над предпросмотром камеры
class ArucoOverlayPainter extends CustomPainter {
  final List<MarkerDetection> detections;
  final Size?
  previewSize; // Размер предпросмотра камеры (для справки, но используем size)
  final double? imageWidth; // Ширина исходного изображения (W_I)
  final double? imageHeight; // Высота исходного изображения (H_I)
  final int? sensorOrientation; // Ориентация сенсора
  final Color markerColor;
  final Color idColor;
  final double strokeWidth;

  final double? finalPitch;
  final double? finalRoll;
  final double? finalYaw;
  final double? verticalFovDegrees;

  final bool? showPointer;
  final bool showIds;
  final bool showCorners;

  List<Offset> midPoints = [];

  final Offset targetPoint;

  ArucoOverlayPainter({
    required this.detections,
    this.previewSize,
    this.imageWidth,
    this.imageHeight,
    this.sensorOrientation,
    this.showIds = true,
    this.showCorners = true,
    this.markerColor = Colors.green,
    this.idColor = Colors.white,
    this.strokeWidth = 2.0,
    this.finalPitch,
    this.finalRoll,
    this.finalYaw,
    this.verticalFovDegrees,
    this.showPointer = false,
    required this.targetPoint,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (imageWidth == null || imageHeight == null) return;

    for (final detection in detections) {
      _drawMarker(canvas, size, detection);
    }

    if (detections.length > 1) {
      for (final detection in detections) {
        midPoints.add(_scalePoint(detection.center, size));
      }
      _drawCenterLine(canvas, size, midPoints);
    }

    if (verticalFovDegrees != null &&
        finalPitch != null &&
        finalRoll != null &&
        finalYaw != null) {
      _dravHorizont(canvas, size);
    }

    if (showPointer != null && showPointer!) {
      _drawPointer(canvas, size);
    }

    _drawPerpendicular(canvas, size);
    _drawTargetPoint(canvas, size, _scalePoint(targetPoint, size));
  }

  void _drawTargetPoint(Canvas canvas, Size size, Offset tPoint) {
    final Paint paint = Paint()
      ..color = const Color.fromARGB(255, 191, 255, 0)
      ..style = PaintingStyle.fill;

    final Paint black = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    canvas.drawCircle(tPoint, 4.0, paint);
    canvas.drawCircle(tPoint, 2.0, black);
  }

  void _drawPerpendicular(Canvas canvas, Size size) {
    var horizontPoints = calculateHorizontLine(
      verticalFovDegrees!,
      finalPitch!,
      finalRoll!,
      size,
    );
    var handlePoints = findPointOffsetFromLower(midPoints, 80);

    var perp = findPerpendicularProjection(horizontPoints, handlePoints[1]);

    final paint = Paint()
      ..color = const Color.fromARGB(255, 191, 255, 0)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path();

    path.moveTo(perp[0].dx, perp[0].dy);
    for (int i = 1; i < perp.length; i++) {
      path.lineTo(perp[i].dx, perp[i].dy);
    }
    path.close();

    canvas.drawPath(path, paint);
  }

  void _drawPointer(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);

    final Offset p21 = Offset(center.dx, center.dy - 20);
    final Offset p22 = Offset(center.dx, center.dy + 20);

    final Offset p23 = Offset(center.dx - 20, center.dy);
    final Offset p24 = Offset(center.dx + 20, center.dy);

    final Paint paint2 = Paint()
      ..color = Colors.yellow[800]!
      ..strokeWidth = 1.0;

    canvas.drawLine(p21, p22, paint2);
    canvas.drawLine(p23, p24, paint2);
  }

  void _dravHorizont(Canvas canvas, Size size) {
    var horizontpoints = calculateHorizontLine(
      verticalFovDegrees!,
      finalPitch!,
      finalRoll!,
      size,
    );
    // final double verticalFovRadians = verticalFovDegrees! * pi / 180.0;

    // final double shiftFactor = size.height / verticalFovRadians;
    // final double verticalShift = finalPitch! * shiftFactor;

    final Paint paint = Paint()
      ..color = Colors.cyanAccent
      ..strokeWidth = 1.0;

    // final Offset horizonpalDx = Offset(
    //   size.width / 2,
    //   size.height / 2 + verticalShift,
    // );
    // final double halfWidth = size.width / 2.0;

    // final double dx = cos(finalRoll!) * halfWidth;
    // final double dy = sin(finalRoll!) * halfWidth;

    // final Offset p1 = Offset(horizonpalDx.dx - dx, horizonpalDx.dy - dy);
    // final Offset p2 = Offset(horizonpalDx.dx + dx, horizonpalDx.dy + dy);

    canvas.drawLine(horizontpoints[0], horizontpoints[1], paint);
  }

  void _drawMarker(Canvas canvas, Size size, MarkerDetection detection) {
    if (detection.corners.length < 4) return;

    if (showCorners) {
      _drawMarkerBounds(canvas, size, detection);
    }

    if (showIds) {
      _drawMarkerId(canvas, size, detection);
    }
  }

  void _drawCenterLine(Canvas canvas, Size size, List<Offset> midPoints) {
    final paint = Paint()
      ..color = Colors.red
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path();

    path.moveTo(midPoints[0].dx, midPoints[0].dy);
    for (int i = 1; i < midPoints.length; i++) {
      path.lineTo(midPoints[i].dx, midPoints[i].dy);
    }
    path.close();

    canvas.drawPath(path, paint);

    // _drawHandleLine(canvas, size, midPoints);
  }

  void _drawMarkerBounds(Canvas canvas, Size size, MarkerDetection detection) {
    final paint = Paint()
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    // Устанавливаем цвет в зависимости от confidence (как было)
    paint.color = detection.confidence == 1.0
        ? Colors.green
        : detection.confidence == 0.0
        ? Colors.red
        : Colors.yellow;

    final path = Path();
    final corners = _scaleCorners(detection.corners, size);

    // Рисуем полигон по углам маркера
    path.moveTo(corners[0].dx, corners[0].dy);
    for (int i = 1; i < corners.length; i++) {
      path.lineTo(corners[i].dx, corners[i].dy);
    }
    path.close();

    canvas.drawPath(path, paint);

    // Отмечаем углы маленькими кругами
    final cornerPaint = Paint()
      ..color = paint.color
      ..style = PaintingStyle.fill;

    for (final corner in corners) {
      canvas.drawCircle(corner, 1.5, cornerPaint);
    }
  }

  void _drawMarkerId(Canvas canvas, Size size, MarkerDetection detection) {
    if (detection.id == -1) return;

    final center = _scalePoint(detection.minPoint, size);

    const textStyle = TextStyle(
      color: Colors.white,
      fontSize: 16,
      fontWeight: FontWeight.bold,
    );

    final textSpan = TextSpan(text: 'ID: ${detection.id}', style: textStyle);

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();

    // Текст
    textPainter.paint(
      canvas,
      Offset(
        center.dx + 10, // - textPainter.width / 2,
        center.dy + textPainter.height / 2,
      ),
    );
  }

  /// Масштабирует координаты в зависимости от размера предпросмотра и ориентации
  List<Offset> _scaleCorners(List<Offset> corners, Size size) {
    final originalWidth = imageWidth!;
    final originalHeight = imageHeight!;
    final orientation = sensorOrientation ?? 0;

    // 1. Определяем эффективные размеры кадра после поворота сенсора.
    // Если ориентация 90/270, ширина и высота для расчета масштаба меняются местами.
    final effectiveSourceWidth = (orientation == 90 || orientation == 270)
        ? originalHeight
        : originalWidth;
    final effectiveSourceHeight = (orientation == 90 || orientation == 270)
        ? originalWidth
        : originalHeight;

    // 2. Вычисляем масштабные коэффициенты относительно эффективных размеров.
    final scaleRatioW = size.width / effectiveSourceWidth;
    final scaleRatioH = size.height / effectiveSourceHeight;

    // 3. Коэффициент масштабирования (BoxFit.cover) - берем больший, чтобы заполнить холст
    final scaleFactor = max(scaleRatioW, scaleRatioH);

    // 4. Смещения из-за обрезки (центровка)
    final scaledImageW = effectiveSourceWidth * scaleFactor;
    final scaledImageH = effectiveSourceHeight * scaleFactor;
    final offsetX = (size.width - scaledImageW) / 2.0;
    final offsetY = (size.height - scaledImageH) / 2.0;

    return corners.map((corner) {
      double rotatedX, rotatedY;

      // 5. Поворот координат (относительно исходного изображения W_I x H_I)
      switch (orientation) {
        case 90:
          // Поворот на 90° CW: (x, y) -> (y, W_I - x)
          rotatedX = corner.dy;
          rotatedY = originalWidth - corner.dx;
          break;
        case 270:
          // Поворот на 270° CCW: (x, y) -> (H_I - y, x)
          rotatedX = originalHeight - corner.dy;
          rotatedY = corner.dx;
          break;
        case 180:
          // Поворот на 180°: (x, y) -> (W_I - x, H_I - y)
          rotatedX = originalWidth - corner.dx;
          rotatedY = originalHeight - corner.dy;
          break;
        default: // 0° — без поворота
          rotatedX = corner.dx;
          rotatedY = corner.dy;
          break;
      }

      // 5.5. ИСПРАВЛЕНИЕ: Добавление финального флипа на 180 градусов
      // относительно эффективных размеров кадра, чтобы соответствовать CameraPreview
      final finalRotatedX = effectiveSourceWidth - rotatedX;
      final finalRotatedY = effectiveSourceHeight - rotatedY;

      // 6. Масштабирование и смещение
      final normalizedX = finalRotatedX * scaleFactor + offsetX;
      final normalizedY = finalRotatedY * scaleFactor + offsetY;

      return Offset(normalizedX, normalizedY);
    }).toList();
  }

  /// Масштабирует точку в зависимости от размера предпросмотра и ориентации
  Offset _scalePoint(Offset point, Size size) {
    final originalWidth = imageWidth!;
    final originalHeight = imageHeight!;
    final orientation = sensorOrientation ?? 0;

    // 1. Определяем эффективные размеры кадра после поворота сенсора.
    final effectiveSourceWidth = (orientation == 90 || orientation == 270)
        ? originalHeight
        : originalWidth;
    final effectiveSourceHeight = (orientation == 90 || orientation == 270)
        ? originalWidth
        : originalHeight;

    // 2. Вычисляем масштабные коэффициенты относительно эффективных размеров.
    final scaleRatioW = size.width / effectiveSourceWidth;
    final scaleRatioH = size.height / effectiveSourceHeight;

    // 3. Коэффициент масштабирования (BoxFit.cover)
    final scaleFactor = max(scaleRatioW, scaleRatioH);

    // 4. Смещения из-за обрезки
    final scaledImageW = effectiveSourceWidth * scaleFactor;
    final scaledImageH = effectiveSourceHeight * scaleFactor;
    final offsetX = (size.width - scaledImageW) / 2.0;
    final offsetY = (size.height - scaledImageH) / 2.0;

    double rotatedX, rotatedY;

    // 5. Поворот координат (относительно исходного изображения W_I x H_I)
    switch (orientation) {
      case 90:
        rotatedX = point.dy;
        rotatedY = originalWidth - point.dx;
        break;
      case 270:
        rotatedX = originalHeight - point.dy;
        rotatedY = point.dx;
        break;
      case 180:
        rotatedX = originalWidth - point.dx;
        rotatedY = originalHeight - point.dy;
        break;
      default:
        rotatedX = point.dx;
        rotatedY = point.dy;
        break;
    }

    // 5.5. ИСПРАВЛЕНИЕ: Добавление финального флипа на 180 градусов
    final finalRotatedX = effectiveSourceWidth - rotatedX;
    final finalRotatedY = effectiveSourceHeight - rotatedY;

    // 6. Масштабирование и смещение
    final scaledX = finalRotatedX * scaleFactor + offsetX;
    final scaledY = finalRotatedY * scaleFactor + offsetY;

    return Offset(scaledX, scaledY);
  }

  @override
  bool shouldRepaint(ArucoOverlayPainter oldDelegate) {
    // Упрощаем проверку shouldRepaint, чтобы избежать лишних перерисовок
    return detections != oldDelegate.detections ||
        imageWidth != oldDelegate.imageWidth ||
        imageHeight != oldDelegate.imageHeight ||
        sensorOrientation != oldDelegate.sensorOrientation ||
        showIds != oldDelegate.showIds ||
        showCorners != oldDelegate.showCorners ||
        markerColor != oldDelegate.markerColor ||
        strokeWidth != oldDelegate.strokeWidth;
  }
}
