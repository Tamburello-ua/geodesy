// import 'package:flutter/material.dart';

// import 'dart:math';

// class HorizonPainter extends CustomPainter {
//   final double horizonAngle; // угол горизонта
//   final double azimuthDiff; // разница азимута

//   HorizonPainter({required this.horizonAngle, required this.azimuthDiff});

//   @override
//   void paint(Canvas canvas, Size size) {
//     final paintH = Paint()
//       ..color = Colors.red
//       ..strokeWidth = 3;

//     final paintA = Paint()
//       ..color = Colors.blue
//       ..strokeWidth = 2;

//     final center = Offset(size.width / 2, size.height / 2);

//     // Горизонтальная линия по углу
//     final dx = size.width;
//     final dy = dx * tan(horizonAngle); // корректный наклон
//     canvas.drawLine(
//       Offset(center.dx - dx / 2, center.dy - dy / 2),
//       Offset(center.dx + dx / 2, center.dy + dy / 2),
//       paintH,
//     );

//     // Вертикальная линия по азимуту
//     final shift =
//         (azimuthDiff / 180) * (size.width / 2); // масштабируем по экрану

//     canvas.drawLine(
//       Offset(center.dx + shift, 0),
//       Offset(center.dx + shift, size.height),
//       paintA,
//     );
//   }

//   @override
//   bool shouldRepaint(covariant HorizonPainter oldDelegate) =>
//       oldDelegate.horizonAngle != horizonAngle ||
//       oldDelegate.azimuthDiff != azimuthDiff;
// }
