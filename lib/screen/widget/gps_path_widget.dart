import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class GPSPathWidget extends StatelessWidget {
  final List<Position> positions;
  final List<Position> filteredPositions;

  const GPSPathWidget({
    super.key,
    required this.positions,
    required this.filteredPositions,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white.withValues(alpha: 0.20),
      // child: SizedBox(
      //   width: 300,
      //   height: 300,
      child: AspectRatio(
        aspectRatio: 1.0,

        child: CustomPaint(
          painter: PathPainter(
            rawPoints: positions,
            filteredPoints: filteredPositions,
          ),
          child: Container(),
        ),
        // ),
      ),
    );
  }
}

class PathPainter extends CustomPainter {
  final List<Position> rawPoints;
  final List<Position> filteredPoints;

  PathPainter({required this.rawPoints, required this.filteredPoints});

  @override
  void paint(Canvas canvas, Size size) {
    if (rawPoints.isEmpty) return;

    // Объединяем все точки для корректного масштабирования
    final allPoints = [...rawPoints, ...filteredPoints];

    if (allPoints.isEmpty) return;

    // 1. Динамическое вычисление границ (по всем точкам)
    double minLat = allPoints.map((p) => p.latitude).reduce(math.min);
    double maxLat = allPoints.map((p) => p.latitude).reduce(math.max);
    double minLon = allPoints.map((p) => p.longitude).reduce(math.min);
    double maxLon = allPoints.map((p) => p.longitude).reduce(math.max);

    // Защита от деления на ноль и обеспечение небольшого поля
    const double padding = 0.000005;
    if (minLat == maxLat) {
      minLat -= padding;
      maxLat += padding;
    }
    if (minLon == maxLon) {
      minLon -= padding;
      maxLon += padding;
    }

    // Вспомогательная функция для преобразования геокоординат в координаты холста
    Offset getOffset(Position point) {
      // Умножаем на 0.9, чтобы добавить небольшой отступ от краев
      double x = _normalize(
        point.longitude,
        minLon,
        maxLon,
        size.width * 0.05,
        size.width * 0.95,
      );
      // Инвертируем Y, чтобы север был сверху (size.height -> 0)
      double y = _normalize(
        point.latitude,
        minLat,
        maxLat,
        size.height * 0.95,
        size.height * 0.05,
      );
      return Offset(x, y);
    }

    // --- 2. Отрисовка Сырого Пути (RAW Path - Синий) ---
    _drawPath(
      canvas,
      rawPoints,
      getOffset,
      Colors.blue.withValues(alpha: 0.5),
      2.0,
      Colors.red,
    );

    // --- 3. Отрисовка Отфильтрованного Пути (FILTERED Path - Зеленый) ---
    _drawPath(
      canvas,
      filteredPoints,
      getOffset,
      Colors.green,
      4.0,
      Colors.orangeAccent,
    );
  }

  void _drawPath(
    Canvas canvas,
    List<Position> points,
    Offset Function(Position) getOffset,
    Color lineColor,
    double lineWidth,
    Color pointColor,
  ) {
    if (points.isEmpty) return;

    // Отрисовка линии
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = lineWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    for (int i = 0; i < points.length; i++) {
      final offset = getOffset(points[i]);
      if (i == 0) {
        path.moveTo(offset.dx, offset.dy);
      } else {
        path.lineTo(offset.dx, offset.dy);
      }
    }
    canvas.drawPath(path, linePaint);

    // Отрисовка точек
    final pointPaint = Paint()
      ..color = pointColor
      ..style = PaintingStyle.fill;

    // Рисуем точку только для последней (самой сглаженной) позиции
    if (points.isNotEmpty) {
      final lastOffset = getOffset(points.last);
      canvas.drawCircle(lastOffset, 6.0, pointPaint);
    }

    // Рисуем маленькие круги для всех точек (только для сырых данных)
    if (lineColor == Colors.blue.withValues(alpha: 0.5)) {
      for (var point in points) {
        final offset = getOffset(point);
        canvas.drawCircle(offset, 2.0, pointPaint);
      }
    }
  }

  /// Нормализует значение из одного диапазона в другой.
  double _normalize(
    double value,
    double min,
    double max,
    double newMin,
    double newMax,
  ) {
    // Защита от деления на ноль уже обеспечена в paint
    return newMin + (value - min) * (newMax - newMin) / (max - min);
  }

  @override
  bool shouldRepaint(covariant PathPainter oldDelegate) {
    return rawPoints != oldDelegate.rawPoints ||
        filteredPoints != oldDelegate.filteredPoints;
  }
}
