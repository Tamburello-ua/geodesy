import 'package:flutter/material.dart';
import 'dart:math';

// ignore: non_constant_identifier_names
Widget CombinedCompensator(double finalPitch, double finalRoll, String mode) {
  const double shiftFactor = 175;
  final double verticalShift = finalPitch * shiftFactor;
  final double compensatedRotation = finalRoll;

  return Padding(
    padding: const EdgeInsets.all(32.0),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Text(
        //   'Режим компенсации: $mode',
        //   style: TextStyle(
        //     color: Colors.yellow,
        //     fontSize: 18,
        //     fontWeight: FontWeight.bold,
        //   ),
        // ),
        Text(
          'Roll (Крен): ${(finalRoll * 180 / pi).toStringAsFixed(1)}°',
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        Text(
          'Pitch (Тангаж): ${(finalPitch * 180 / pi).toStringAsFixed(1)}°',
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        const SizedBox(height: 30),

        // Контейнер-рамка, обозначающий область смещения
        Container(
          height: 300,
          width: 200,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade800),
          ),
          child: Center(
            // Шаг 1: Применяем вертикальное смещение (Translate)
            child: Transform.translate(
              offset: Offset(0, verticalShift),
              child: Transform.rotate(
                // Шаг 2: Применяем компенсацию вращения (Rotate)
                angle: compensatedRotation,
                child: Container(
                  width: 150,
                  height: 10,
                  color: Colors.cyanAccent,
                ),
              ),
            ),
          ),
        ),
        // const SizedBox(height: 30),
        // const Text(
        //   'Тест: Наклоните (смещение). Поверните по оси (вращение должно быть скомпенсировано).',
        //   textAlign: TextAlign.center,
        //   style: TextStyle(color: Colors.white70),
        // ),
      ],
    ),
  );
}
