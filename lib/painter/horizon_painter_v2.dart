// import 'dart:math' as math;
// import 'package:flutter/material.dart';
// import 'package:vector_math/vector_math_64.dart' hide Colors;

// class HorizonPainterV2 extends CustomPainter {
//   final Quaternion quaternion;
//   final double fovY;
//   final Size imageSize;

//   HorizonPainterV2({
//     required this.quaternion,
//     required this.fovY,
//     required this.imageSize,
//   });

//   @override
//   void paint(Canvas canvas, Size size) {
//     final paint = Paint()
//       ..color = Colors.redAccent
//       ..strokeWidth = 2;

//     // Поворот на 180° вокруг X — переходим из экранной системы в "камерную"
//     final rotationFix = Quaternion.axisAngle(Vector3(1, 0, 0), math.pi);
//     final corrected = quaternion * rotationFix;

//     // Вектор "вверх" мира
//     final upWorld = Vector3(0, 1, 0);
//     // После поворота телефона — куда "вверх" указывает камера
//     final upCamera = corrected.rotate(upWorld);

//     // Из этого вектора получаем угол крена (roll)
//     final horizonTilt = math.atan2(upCamera.x, upCamera.y);

//     // Центр экрана
//     final centerY = size.height / 2;
//     final dx = size.width / 2;

//     // Вычисляем точки линии, просто вращая вокруг центра
//     final dy = math.tan(horizonTilt) * dx;

//     final p1 = Offset(0, centerY - dy);
//     final p2 = Offset(size.width, centerY + dy);

//     canvas.drawLine(p1, p2, paint);
//   }

//   @override
//   bool shouldRepaint(HorizonPainterV2 oldDelegate) =>
//       quaternion != oldDelegate.quaternion;
// }
