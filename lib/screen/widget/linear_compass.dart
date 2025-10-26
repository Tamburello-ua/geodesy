import 'package:flutter/material.dart';
import 'dart:math';

// ignore: non_constant_identifier_names
Widget LinearCompass(double rawYaw) {
  double yawInDegrees = rawYaw * 180 / pi;
  yawInDegrees = (yawInDegrees + 360) % 360; // Нормализация в [0, 360]

  return Column(
    children: [
      Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 10),
        child: Text(
          'Yaw (Рыскание/Азимут): ${yawInDegrees.toStringAsFixed(1)}°',
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
      ),
      Container(
        height: 60,
        width: 320.0,
        decoration: BoxDecoration(
          color: Colors.grey.shade900,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white38),
        ),
        child: Center(
          child: Text(
            '${yawInDegrees.toStringAsFixed(1)}°',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      const SizedBox(height: 10),
      const Text(
        'Компас: Поворачивайте телефон горизонтально.',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white70),
      ),
    ],
  );
}
