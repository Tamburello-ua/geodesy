import 'dart:math';
import 'dart:ui';
import 'package:geodesy/models/marker_detection.dart';
import 'package:geodesy/screen/utils/geodesy_utils.dart';

Offset rotatedPoint(Offset point, int orientation) {
  double rotatedX, rotatedY;

  switch (orientation) {
    case 90:
      rotatedX = point.dy;
      rotatedY = point.dx;
      break;
    case 270:
      rotatedX = point.dy;
      rotatedY = point.dx;
      break;

    default:
      rotatedX = point.dx;
      rotatedY = point.dy;
      break;
  }

  return Offset(rotatedX, rotatedY);
}

Map<String, double> getHandleBottom({
  required List<MarkerDetection> detectedMarkers,
  required double pitch,
  required double roll,
  required double distanceToHandleBottomMM,
  required double distanceBetweenMarkersMM,
  required int orientation,
  required Size size,
  required double verticalFovDegrees,
}) {
  if (detectedMarkers.isEmpty || detectedMarkers.length < 2) {
    return {
      'pixel_distance': 0.0,
      'distance_cm': 0.0,
      'elevation_cm': 0.0,
      'handle_point_x': 0.0,
      'handle_point_y': 0.0,
    };
  }
  Offset pointL;
  Offset pointU;

  var p1 = rotatedPoint(detectedMarkers[0].center, orientation);
  var p2 = rotatedPoint(detectedMarkers[1].center, orientation);

  if (p1.dy < p2.dy) {
    pointL = p2;
    pointU = p1;
  } else {
    pointL = p1;
    pointU = p2;
  }

  final dx = pointL.dx - pointU.dx;
  final dy = pointL.dy - pointU.dy;
  final distance = compensateDistance(sqrt(dx * dx + dy * dy), pitch);

  final vector = pointL - pointU;
  final t = distanceToHandleBottomMM / distanceBetweenMarkersMM;
  final newPointDx = pointL.dx + t * vector.dx;
  final newPointDy = pointL.dy + t * vector.dy;
  final pointFound = Offset(newPointDx, newPointDy);

  var horizontPoints = calculateHorizontLine(
    verticalFovDegrees,
    pitch,
    roll,
    Size(size.height, size.width),
  );
  var perp = findPerpendicularProjection(horizontPoints, pointFound);
  var pdy = perp.dy - pointFound.dy;

  //TODO: тут не правильно. Это другие пиксели, нужно посмотреть на расстояние между центрами маркера
  var elevation = compensateDistance(pdy.abs(), pitch);

  return {
    'pixel_distance': distance,
    'distance_cm': pixelsToCm(distance),
    'elevation_cm': pixelsToCm(elevation),
    'handle_point_x': pointFound.dx,
    'handle_point_y': pointFound.dy,
  };
}

Map<String, double> getPositionData(
  List<MarkerDetection> detectedMarkers,
  double pitch,
) {
  if (detectedMarkers.isEmpty || detectedMarkers.length < 2) {
    return {'pixel_distance': 0.0, 'distance_cm': 0.0};
  }

  final dx = detectedMarkers[1].center.dx - detectedMarkers[0].center.dx;
  final dy = detectedMarkers[1].center.dy - detectedMarkers[0].center.dy;
  final distance = compensateDistance(sqrt(dx * dx + dy * dy), pitch);
  final distance_raw = sqrt(dx * dx + dy * dy);

  return {
    'pixel_distance': distance,
    'pixel_distance_raw': distance_raw,
    'distance_cm': pixelsToCm(distance),
    // 'optical_distance_cm': distanceFromPixels_optical(distance),
  };
}

double compensateDistance(double distancePx, double pitchRadians) {
  final double scaleK = 1.368;
  final compensatedDistance = distancePx * cos(scaleK * pitchRadians);

  // print(
  //   'distancePx=$distancePx, pitchRadians=$pitchRadians,  compensatedDistance=$compensatedDistance',
  // );
  return compensatedDistance;
}

double pixelsToCm(double pixels) {
  //TODO: Подставить свои коэффициенты аппроксимации на основании калибровки
  final aFit = 16803.176887; // коэффициент масштабирования
  final bFit = -1.008588; // коэффициент сжатия

  return pow(pixels / aFit, 1 / bFit).toDouble();
}
