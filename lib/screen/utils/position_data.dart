import 'dart:math';
import 'dart:ui';
import 'package:geodesy/models/marker_detection.dart';

Map<String, double> getHandleBottom({
  required List<MarkerDetection> detectedMarkers,
  required double pitch,
  required double distanceToHandleBottomMM,
  double distanceBetweenMarkersMM = 100.0,
}) {
  if (detectedMarkers.isEmpty || detectedMarkers.length < 2) {
    return {'pixel_distance': 0.0, 'distance_cm': 0.0};
  }
  Offset lowerPoint;
  Offset upperPoint;

  if (detectedMarkers[0].center.dy > detectedMarkers[1].center.dy) {
    lowerPoint = detectedMarkers[1].center;
    upperPoint = detectedMarkers[0].center;
  } else {
    lowerPoint = detectedMarkers[0].center;
    upperPoint = detectedMarkers[1].center;
  }

  final dx = upperPoint.dx - lowerPoint.dx;
  final dy = upperPoint.dy - lowerPoint.dy;

  final distance = compensateDistance(sqrt(dx * dx + dy * dy), pitch);

  final vector = upperPoint - lowerPoint;
  final t = distanceToHandleBottomMM / distanceBetweenMarkersMM;
  final newPointDx = lowerPoint.dx - t * vector.dx;
  final newPointDy = lowerPoint.dy - t * vector.dy;

  final foundPoint = Offset(newPointDx, newPointDy);

  return {
    'pixel_distance': distance,
    'distance_cm': pixelsToCm(distance),
    'handle_point_x': foundPoint.dx,
    'handle_point_y': foundPoint.dy,
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
  return {
    'pixel_distance': distance,
    // 'geminy_pixel_distance': compensateDistance(distance, pitch),
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
