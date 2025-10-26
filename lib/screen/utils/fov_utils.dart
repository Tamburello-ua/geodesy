class FOVCalibration {
  // Порог угла для фильтрации близких значений VFOV и для проверки finalPitch > 0
  // (~0.5 градуса в радианах)
  final double angleThreshold = 0.0087;

  final Map<dynamic, dynamic> _vfovEstimates = {};
  int get estimatesCount => _vfovEstimates.length;

  void addCalibrationPoint(
    double pitchRad,
    double pixelDistance,
    double screenHeight,
  ) {
    if (pitchRad.abs() < angleThreshold) return;

    if (pixelDistance == 0) return;

    for (final existingPitch in _vfovEstimates.keys) {
      if ((existingPitch - pitchRad).abs() < angleThreshold) {
        // Нашелся слишком близкий ключ, ничего не добавляем
        // print(
        // 'Точка не добавлена: найден близкий pitchRad ${existingPitch.toStringAsFixed(4)}',
        // );
        return;
      }
    }

    _vfovEstimates[pitchRad] = pixelDistance;

    print(
      'Добавлена точка: {pitch: ${pitchRad.toStringAsFixed(4)}, pxDist: $pixelDistance} (Всего: $estimatesCount)',
    );
  }

  // /// Возвращает усредненное VFOV в радианах.
  // double getFOV() {
  //   if (_vfovEstimates.isEmpty) return 0.0;
  //   return _vfovEstimates.reduce((a, b) => a + b) / _vfovEstimates.length;
  // }

  /// Вычисляет verticalShift (относительное смещение в пикселях ЭКРАНА) для линии
  /// горизонта при любом pitch, используя усредненное VFOV.
  ///
  /// Результат: Положительный shift означает смещение линии ВНИЗ от центра.
  // double verticalShift(double pitchRad, double screenHeight) {
  //   final vfov = getFOV();
  //   if (vfov == 0) return 0.0;

  //   // Формула для смещения (S) на экране: S = -(H_screen/2) * tan(pitch) / tan(VFOV/2)
  //   // (Минус необходим для компенсации знака: Pitch Down (+) -> Line Up (-) )
  //   return -(screenHeight / 2) * tan(pitchRad) / tan(vfov / 2);
  // }
}
