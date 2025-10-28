import 'package:flutter/material.dart';
import 'dart:math';

Widget DataInfoWidget({
  double? finalPitch,
  double? finalRoll,
  double? finalYaw,
  double? distanceCm,
  double? elevation,
  String? targetPointCoordinates,
}) {
  double yawInDegrees = finalYaw ?? 0 * 180 / pi;
  yawInDegrees = (yawInDegrees + 360) % 360; // Нормализация в [0, 360]

  return Column(
    children: [
      if (finalRoll != null)
        Text(
          'Roll (Крен): ${(finalRoll * 180 / pi).toStringAsFixed(1)}°',
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
      if (finalPitch != null)
        Text(
          'Pitch (Тангаж): ${(finalPitch * 180 / pi).toStringAsFixed(1)}°',
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
      if (finalYaw != null)
        Text(
          'Azimuth: ${(yawInDegrees).toStringAsFixed(1)}°',
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
      if (distanceCm != null)
        Text(
          'Distance: ${(distanceCm / 100).toStringAsFixed(2)} m',
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
      if (elevation != null)
        Text(
          'Elevation: ${(elevation).toStringAsFixed(2)} cm',
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
      if (targetPointCoordinates != null)
        Text(
          'Point: $targetPointCoordinates',
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
    ],
  );
}
