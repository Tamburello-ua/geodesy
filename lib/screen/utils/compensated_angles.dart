import 'dart:math';
import 'package:motion_core/motion_core.dart';

Map<String, dynamic> getCompensatedAngles(MotionData? motionData) {
  final attitude = motionData!.attitude; // Кватернион ориентации
  final gravity = motionData.gravity.normalized();

  // Извлечение компонентов кватерниона
  final double w = attitude.w;
  final double x = attitude.x;
  final double y = attitude.y;
  final double z = attitude.z;

  // Преобразование Quaternion в углы Эйлера (в радианах, порядок ZYX)
  double yaw = atan2(
    2 * (w * z + x * y),
    1 - 2 * (y * y + z * z),
  ); // Рыскание (Z)
  double pitch = atan2(
    2 * (w * x + y * z),
    1 - 2 * (x * x + y * y),
  ); // Тангаж (Y)
  double roll = asin(2 * (w * y - z * x)); // Крен (X)

  // Пороговые углы в радианах (40° и 50°)
  const double maxAngle = 40 * pi / 180; // 40 градусов
  const double minAngle = 50 * pi / 180; // 50 градусов

  // Углы между гравитацией и осями (в радианах)
  final double angleWithY = acos(gravity.y.abs()); // Угол с осью Y
  final double angleWithX = acos(gravity.x.abs()); // Угол с осью X
  final double angleWithZ = acos(gravity.z.abs()); // Угол с осью Z

  double finalPitch;
  double finalRoll;
  double finalYaw;
  String mode;

  // Yaw компенсируется инверсией для всех положений
  finalYaw = -yaw; // Инвертируем yaw для компенсации поворота телефона

  if (angleWithY <= maxAngle) {
    // Вертикальный режим (Y-axis вертикально)
    if (gravity.y > 0) {
      // Разъём вниз (3)
      finalPitch = pitch - pi / 2; // Адаптируем под вашу логику
      finalRoll = -roll;
      mode = 'Вертикальный (вниз)';
    } else {
      // Разъём вверх (4)
      finalPitch = -(pitch - pi / 2);
      finalRoll = roll;
      mode = 'Вертикальный (вверх)';
    }
  } else if (angleWithX <= maxAngle) {
    // Альбомный режим (X-axis вертикально)
    if (gravity.x > 0) {
      // Регулятор вверх (5)
      double rawPitch = roll; // Используем roll как базу (наклон вокруг X)
      finalPitch = rawPitch; // Изначальное значение
      // Нормализация с учётом вертикали
      finalPitch = atan2(sin(rawPitch), cos(rawPitch)); // Перевод в [-pi, pi]
      if (finalPitch > pi / 2) {
        finalPitch -= pi; // Ограничиваем [-pi/2, pi/2]
      } else if (finalPitch < -pi / 2) {
        finalPitch += pi;
      }
      finalRoll = pitch; // Вращение вокруг Y
      mode = 'Альбомный (вверх)';
    } else {
      // Регулятор вниз (6)
      double rawPitch = roll;
      finalPitch = rawPitch;
      finalPitch = atan2(sin(rawPitch), cos(rawPitch)); // Перевод в [-pi, pi]
      if (finalPitch > pi / 2) {
        finalPitch -= pi;
      } else if (finalPitch < -pi / 2) {
        finalPitch += pi;
      }
      finalPitch = -finalPitch; // Инверсия для противоположного направления
      finalRoll = -pitch; // Инверсия
      mode = 'Альбомный (вниз)';
    }
  } else if (angleWithZ <= maxAngle) {
    // Плоский режим (Z-axis вертикально)
    if (gravity.z > 0) {
      // Экран вниз (2)
      finalPitch = pitch - pi / 2;
      finalRoll = -roll;
      mode = 'Плоский (вниз)';
    } else {
      // Экран вверх (1)
      finalPitch = -(pitch - pi / 2);
      finalRoll = roll;
      mode = 'Плоский (вверх)';
    }
  } else if (angleWithY <= minAngle ||
      angleWithX <= minAngle ||
      angleWithZ <= minAngle) {
    // Промежуточный режим только между 40° и 50°
    finalPitch = pitch - pi / 2;
    finalRoll = -roll;
    finalYaw = -yaw;
    mode = 'Промежуточный';
  } else {
    // Резервный режим
    finalPitch = pitch - pi / 2;
    finalRoll = -roll;
    finalYaw = -yaw;
    mode = 'Плоский (резерв)';
  }

  return {
    'pitch': finalPitch,
    'roll': finalRoll,
    'yaw': finalYaw,
    'mode': mode,
  };
}
