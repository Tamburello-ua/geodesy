import 'dart:math';

import 'package:flutter/material.dart';

/// Виджет, который рисует шкалу компаса поверх другого виджета.
///
/// Требует [currentAzimuth] (текущий азимут в градусах) и
/// [horizontalFOV] (горизонтальный угол обзора камеры в градусах).
class CompassOverlayWidget extends StatelessWidget {
  final double currentAzimuth;
  final double magneticAzimuth;
  final double horizontalFOV;

  const CompassOverlayWidget({
    super.key,
    required this.currentAzimuth,
    required this.magneticAzimuth,
    required this.horizontalFOV,
  });

  @override
  Widget build(BuildContext context) {
    double yawInDegrees = currentAzimuth * 180 / pi;

    return CustomPaint(
      painter: _CompassPainter(
        azimuth: (yawInDegrees + 360) % 360,
        magneticAzimuth: (magneticAzimuth + 360) % 360,
        horizontalFOV: horizontalFOV,
      ),
    );
  }
}

class _CompassPainter extends CustomPainter {
  final double azimuth;
  final double horizontalFOV;
  final double magneticAzimuth;

  // Стили отрисовки
  final Paint _linePaint = Paint()
    ..color = Colors.white.withValues(alpha: 0.8)
    ..strokeWidth = 2.0
    ..style = PaintingStyle.stroke;

  final Paint _mediumLinePaint = Paint()
    ..color = Colors.white.withValues(alpha: 0.6)
    ..strokeWidth = 1.5
    ..style = PaintingStyle.stroke;

  final Paint _smallLinePaint = Paint()
    ..color = Colors.white.withValues(alpha: 0.4)
    ..strokeWidth = 1.0
    ..style = PaintingStyle.stroke;

  final Paint _centerMarkerPaint = Paint()
    ..color = Colors.red
    ..style = PaintingStyle.fill;

  _CompassPainter({
    required this.azimuth,
    required this.horizontalFOV,
    required this.magneticAzimuth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double width = size.width;
    // final double height = size.height;
    final double centerY = 40.0; // Отступ сверху для шкалы
    final double centerX = width / 2;

    // --- 1. Рисуем шкалу ---
    final double degreesPerPixel = horizontalFOV / width;
    final double startAzimuth = azimuth - (horizontalFOV / 2);
    final double endAzimuth = azimuth + (horizontalFOV / 2);

    // Определяем, какие градусы рисовать
    final int firstTick = startAzimuth.floor();
    final int lastTick = endAzimuth.ceil();

    for (int i = firstTick; i <= lastTick; i++) {
      // Нормализуем градус (0-359)
      final int deg = (i % 360 + 360) % 360;

      // Вычисляем X-позицию для этой отметки
      final double xPos = centerX + (i - azimuth) / degreesPerPixel;

      // Пропускаем, если ушло за экран (хотя цикл и так ограничен)
      if (xPos < 0 || xPos > width) continue;

      double tickHeight;
      Paint paint;
      String? label;

      if (deg % 90 == 0) {
        // N, E, S, W
        tickHeight = 30.0;
        paint = _linePaint;
        label = _getCardinalLabel(deg);
      } else if (deg % 10 == 0) {
        // Каждые 10 градусов
        tickHeight = 20.0;
        paint = _mediumLinePaint;
        label = deg.toString();
      } else if (deg % 5 == 0) {
        // Каждые 5 градусов
        tickHeight = 15.0;
        paint = _smallLinePaint;
        label = null;
      } else {
        // Каждый градус
        tickHeight = 8.0;
        paint = _smallLinePaint;
        label = null;
      }

      // Рисуем штрих
      canvas.drawLine(
        Offset(xPos, centerY - tickHeight / 2),
        Offset(xPos, centerY + tickHeight / 2),
        paint,
      );

      // Рисуем подпись (N, E, S, W или градусы)
      if (label != null) {
        _drawText(
          canvas,
          label,
          Offset(xPos, centerY + tickHeight / 2 + 5),
          color: paint.color,
        );
      }
    }

    // --- 2. Рисуем центральный маркер ---
    final path = Path();
    path.moveTo(centerX - 7, centerY - 25);
    path.lineTo(centerX + 7, centerY - 25);
    path.lineTo(centerX, centerY - 15);
    path.close();
    canvas.drawPath(path, _centerMarkerPaint);

    // --- 3. Рисуем точное значение азимута под маркером ---
    _drawText(
      canvas,
      azimuth.toStringAsFixed(1),
      Offset(centerX, centerY - 45), // Чуть выше маркера
      color: Colors.red,
      fontSize: 16.0,
      bold: true,
    );

    _drawText(
      canvas,
      magneticAzimuth.toStringAsFixed(1),
      Offset(centerX, centerY - 70), // Чуть выше маркера
      color: Colors.deepOrangeAccent,
      fontSize: 16.0,
      bold: true,
    );
  }

  // Вспомогательная функция для получения N, E, S, W
  String _getCardinalLabel(int deg) {
    switch (deg) {
      case 0:
        return 'N';
      case 90:
        return 'E';
      case 180:
        return 'S';
      case 270:
        return 'W';
      default:
        return deg.toString();
    }
  }

  // Вспомогательная функция для отрисовки текста
  void _drawText(
    Canvas canvas,
    String text,
    Offset offset, {
    Color color = Colors.white,
    double fontSize = 14.0,
    bool bold = false,
  }) {
    final textStyle = TextStyle(
      color: color,
      fontSize: fontSize,
      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
    );
    final textSpan = TextSpan(text: text, style: textStyle);
    final textPainter = TextPainter(
      text: textSpan,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    // Центрируем текст по горизонтали
    final textOffset = Offset(offset.dx - textPainter.width / 2, offset.dy);
    textPainter.paint(canvas, textOffset);
  }

  @override
  bool shouldRepaint(covariant _CompassPainter oldDelegate) {
    // Перерисовывать, если изменился азимут или FOV
    return oldDelegate.azimuth != azimuth ||
        oldDelegate.horizontalFOV != horizontalFOV;
  }
}
