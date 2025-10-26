import 'dart:math';
import 'package:geodesy/models/marker_detection.dart';

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
