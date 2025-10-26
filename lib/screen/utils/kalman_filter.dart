import 'dart:math' as math;
import 'package:geolocator/geolocator.dart';

/// Класс, реализующий упрощенный Фильтр Калмана для сглаживания
/// последовательности GPS-координат (Position).
class KalmanFilter {
  // Список для хранения отфильтрованных (сглаженных) координат
  final List<Position> _filteredPositions = [];

  // Внутреннее состояние Фильтра Калмана
  late double _timeStampMilliseconds;
  late double _lat;
  late double _lng;
  late double _variance; // Дисперсия (погрешность^2)

  // Константы фильтра
  final double _minAccuracy = 1.0;
  final double _processNoiseStaticQ =
      0.1; // Шум процесса для статического режима

  KalmanFilter() {
    _variance = -1; // Сигнал о неинициализированном состоянии
  }

  /// Возвращает список всех отфильтрованных GPS-координат.
  List<Position> get filteredPositions => _filteredPositions;

  /// Возвращает последнюю отфильтрованную (сглаженную) координату.
  Position? get lastFilteredPosition =>
      _filteredPositions.isNotEmpty ? _filteredPositions.last : null;

  /// Основной метод для обработки новой GPS-координаты.
  ///
  /// [newPosition]: Объект Position, полученный от geolocator.
  /// [isStationary]: Флаг, указывающий, что устройство неподвижно (speedMs = 0).
  void process(Position newPosition, bool isStationary) {
    // Извлечение данных из Position
    double latMeasurement = newPosition.latitude;
    double lngMeasurement = newPosition.longitude;
    // Используем accuracy из Position, но ограничиваем минимумом
    double accuracy = newPosition.accuracy;
    double timeStampMilliseconds = newPosition.timestamp.millisecondsSinceEpoch
        .toDouble();
    double speedMs = isStationary
        ? 0.0
        : newPosition.speed; // Устанавливаем 0.0, если неподвижен

    // 1. Предварительная обработка
    if (accuracy < _minAccuracy) accuracy = _minAccuracy;

    // Инициализация, если фильтр не был запущен
    if (_variance < 0) {
      _timeStampMilliseconds = timeStampMilliseconds;
      _lat = latMeasurement;
      _lng = lngMeasurement;
      _variance = accuracy * accuracy;
      // Добавляем первую точку (без фильтрации)
      _addFilteredPosition(newPosition);
      return;
    }

    // 2. Шаг прогнозирования (Prediction Step)

    double duration = timeStampMilliseconds - _timeStampMilliseconds;
    if (duration > 0) {
      if (speedMs == 0) {
        // Неподвижный режим: добавляем Process Noise Q
        _variance += _processNoiseStaticQ;
      } else {
        // Режим движения: увеличиваем неопределенность пропорционально движению
        _variance += duration * speedMs * speedMs / 1000;
      }
      _timeStampMilliseconds = timeStampMilliseconds;
    }

    // 3. Шаг обновления (Update Step)

    // Коэффициент усиления Калмана K
    double K = _variance / (_variance + accuracy * accuracy);

    // Корректируем положение (сглаживание)
    _lat += K * (latMeasurement - _lat);
    _lng += K * (lngMeasurement - _lng);

    // Обновляем дисперсию (P)
    _variance = (1 - K) * _variance;

    // 4. Добавление результата в список
    _addFilteredPosition(newPosition);
  }

  /// Создает новый объект Position с отфильтрованными данными
  /// и добавляет его в список.
  void _addFilteredPosition(Position original) {
    final filtered = Position(
      latitude: _lat,
      longitude: _lng,
      timestamp: original.timestamp,
      // Используем отфильтрованную точность
      accuracy: estimatedAccuracy,
      altitude: original.altitude,
      speed: original.speed,
      speedAccuracy: original.speedAccuracy,
      heading: original.heading,
      altitudeAccuracy: original.altitudeAccuracy,
      isMocked: original.isMocked,
      headingAccuracy: original.headingAccuracy,
    );

    if (_filteredPositions.length > 50) {
      _filteredPositions.removeAt(0);
    }
    _filteredPositions.add(filtered);
  }

  /// Возвращает оцененную точность (стандартное отклонение),
  /// которая является квадратным корнем из дисперсии.
  double get estimatedAccuracy => math.sqrt(_variance);
}

// ====================================================================

// ПРИМЕР ИСПОЛЬЗОВАНИЯ В FLUTTER/DART

/*
Важно: Для запуска этого кода требуется import 'package:geolocator/geolocator.dart';
и подключенный пакет geolocator.
*/

// void runKalmanExample() {
//   final processor = KalmanFilter();

//   print('--- Начало обработки GPS-измерений Фильтром Калмана ---');
//   print('Original | Filtered (Accuracy)');

//   // Запуск обработки
//   for (final pos in positions) {
//     // isStationary = true, так как телефон лежит неподвижно.
//     processor.process(pos, true);

//     final originalLat = pos.latitude.toStringAsFixed(5);
//     final filteredLat = processor.lastFilteredPosition!.latitude
//         .toStringAsFixed(5);
//     final filteredAcc = processor.lastFilteredPosition!.accuracy
//         .toStringAsFixed(2);

//     print('$originalLat | $filteredLat ($filteredAcc м)');
//   }

//   print('--- Фильтрация завершена ---');

//   // Результат - отфильтрованный список в требуемом формате:
//   List<Position> filteredList = processor.filteredPositions;

//   print('Общее количество отфильтрованных точек: ${filteredList.length}');
//   print('Последняя сглаженная координата:');
//   print('Lat: ${filteredList.last.latitude.toStringAsFixed(6)}');
//   print('Lng: ${filteredList.last.longitude.toStringAsFixed(6)}');
// }
