import 'dart:math';
import 'dart:ui';

import 'package:geodesy/models/marker_detection.dart';

void calculateDestinationPoint(
  final double verticalFovDegrees,
  final List<MarkerDetection> detectedMarkers,
  final Map<String, dynamic> compensatedAngles,

  final Size? previewSize,
  final double? imageWidth,
  final double? imageHeight,
  final int? sensorOrientation,
) {}

List<Offset> findPerpendicularProjection(
  List<Offset> segmentAB,
  Offset pointP,
) {
  if (segmentAB.length < 2) {
    throw ArgumentError('segmentAB должен содержать две точки (A и B).');
  }

  final pointA = segmentAB[0];
  final pointB = segmentAB[1];

  // 1. Определяем векторы
  // V = B - A (Вектор вдоль отрезка AB)
  final double dx = pointB.dx - pointA.dx;
  final double dy = pointB.dy - pointA.dy;

  // W = P - A (Вектор от A до P)
  final double wx = pointP.dx - pointA.dx;
  final double wy = pointP.dy - pointA.dy;

  // 2. Вычисляем скалярное произведение
  // W * V
  final double dotWV = wx * dx + wy * dy;

  // V * V (квадрат длины V)
  final double dotVV = dx * dx + dy * dy;

  // Обработка случая, когда A и B совпадают
  if (dotVV == 0.0) {
    // Если отрезок AB имеет нулевую длину, проекция Q совпадает с A (и B)
    return [pointP, pointA];
  }

  // 3. Вычисляем коэффициент t (скалярная проекция)
  // t определяет, какую часть пути от A к B занимает проекция Q.
  double t = dotWV / dotVV;

  // 4. Ограничиваем t (Clamping) для проецирования на ОТРЕЗОК AB
  // Если t < 0, Q совпадает с A. Если t > 1, Q совпадает с B.
  t = t.clamp(0.0, 1.0);

  // 5. Вычисляем точку Q (проекцию P на отрезок AB)
  // Q = A + t * V
  final double pointQx = pointA.dx + t * dx;
  final double pointQy = pointA.dy + t * dy;

  final pointQ = Offset(pointQx, pointQy);

  // 6. Возвращаем [pointP, pointQ]
  return [pointP, pointQ];
}

List<Offset> calculateHorizontLine(
  double verticalFovDegrees,
  double finalPitch,
  double finalRoll,
  Size size,
) {
  final double verticalFovRadians = verticalFovDegrees * pi / 180.0;

  final double shiftFactor = size.height / verticalFovRadians;
  final double verticalShift = finalPitch * shiftFactor;

  final Offset horizonpalDx = Offset(
    size.width / 2,
    size.height / 2 + verticalShift,
  );
  final double halfWidth = size.width / 2.0;

  final double dx = cos(finalRoll) * halfWidth;
  final double dy = sin(finalRoll) * halfWidth;

  final Offset p1 = Offset(horizonpalDx.dx - dx, horizonpalDx.dy - dy);
  final Offset p2 = Offset(horizonpalDx.dx + dx, horizonpalDx.dy + dy);

  return [p1, p2];
}

List<Offset> findPointOffsetFromLower(
  List<Offset> midPoints,
  double distanceInMM, {
  double totalDistanceInMM = 100.0,
}) {
  if (midPoints.length < 2) {
    throw ArgumentError(
      'List<Offset> midPoints повинен містити принаймні дві точки.',
    );
  }

  final p1 = midPoints[0];
  final p2 = midPoints[1];

  // 1. Визначення нижньої (lower) та верхньої (upper) точки.
  // Нижня точка має БІЛЬШЕ значення dy.
  final Offset lowerPoint;
  final Offset upperPoint; // Змінено назву на upperPoint для чіткості

  if (p1.dy > p2.dy) {
    lowerPoint = p1;
    upperPoint = p2;
  } else {
    // p2 нижче, або точки на одному рівні
    lowerPoint = p2;
    upperPoint = p1;
  }

  // 2. Базовий вектор (напрямок)
  // Вектор від нижньої точки до верхньої: V = P_upper - P_lower
  final vector = upperPoint - lowerPoint;

  // 3. Коефіцієнт зміщення (частка шляху).
  // Наприклад: 30 мм / 100 мм = 0.3
  final t = distanceInMM / totalDistanceInMM;

  // 4. Обчислення нової точки (на продовженні лінії):
  // Для продовження лінії у протилежному напрямку використовуємо від'ємний коефіцієнт t.
  // P_found = P_lower + (-t) * vector
  final newPointDx = lowerPoint.dx - t * vector.dx;
  final newPointDy = lowerPoint.dy - t * vector.dy;

  final foundPoint = Offset(newPointDx, newPointDy);

  // 5. Повернення списку [нижня точка, знайдена точка]
  return [lowerPoint, foundPoint];
}
