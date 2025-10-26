import 'package:opencv_dart/opencv_dart.dart' as cv;

/// Доступные типы словарей ArUco
enum ArucoDictionary {
  dict4x4_50(cv.PredefinedDictionaryType.DICT_4X4_50, 'DICT_4X4_50'),
  dict4x4_100(cv.PredefinedDictionaryType.DICT_4X4_100, 'DICT_4X4_100'),
  dict4x4_250(cv.PredefinedDictionaryType.DICT_4X4_250, 'DICT_4X4_250'),
  dict5x5_50(cv.PredefinedDictionaryType.DICT_5X5_50, 'DICT_5X5_50'),
  dict5x5_100(cv.PredefinedDictionaryType.DICT_5X5_100, 'DICT_5X5_100'),
  dict5x5_250(cv.PredefinedDictionaryType.DICT_5X5_250, 'DICT_5X5_250'),
  dict6x6_50(cv.PredefinedDictionaryType.DICT_6X6_50, 'DICT_6X6_50'),
  dict6x6_100(cv.PredefinedDictionaryType.DICT_6X6_100, 'DICT_6X6_100'),
  dict6x6_250(cv.PredefinedDictionaryType.DICT_6X6_250, 'DICT_6X6_250'),
  dict7x7_50(cv.PredefinedDictionaryType.DICT_7X7_50, 'DICT_7X7_50'),
  dict7x7_100(cv.PredefinedDictionaryType.DICT_7X7_100, 'DICT_7X7_100'),
  dict7x7_250(cv.PredefinedDictionaryType.DICT_7X7_250, 'DICT_7X7_250'),
  dictAruco(
    cv.PredefinedDictionaryType.DICT_ARUCO_ORIGINAL,
    'DICT_ARUCO_ORIGINAL',
  );

  const ArucoDictionary(this.predefinedType, this.name);

  final cv.PredefinedDictionaryType predefinedType;
  final String name;

  /// Для отображения в интерфейсе
  String get displayName {
    switch (this) {
      case ArucoDictionary.dict4x4_50:
        return '4x4 (50 маркеров)';
      case ArucoDictionary.dict4x4_100:
        return '4x4 (100 маркеров)';
      case ArucoDictionary.dict4x4_250:
        return '4x4 (250 маркеров)';
      case ArucoDictionary.dict5x5_50:
        return '5x5 (50 маркеров)';
      case ArucoDictionary.dict5x5_100:
        return '5x5 (100 маркеров)';
      case ArucoDictionary.dict5x5_250:
        return '5x5 (250 маркеров)';
      case ArucoDictionary.dict6x6_50:
        return '6x6 (50 маркеров)';
      case ArucoDictionary.dict6x6_100:
        return '6x6 (100 маркеров)';
      case ArucoDictionary.dict6x6_250:
        return '6x6 (250 маркеров)';
      case ArucoDictionary.dict7x7_50:
        return '7x7 (50 маркеров)';
      case ArucoDictionary.dict7x7_100:
        return '7x7 (100 маркеров)';
      case ArucoDictionary.dict7x7_250:
        return '7x7 (250 маркеров)';
      case ArucoDictionary.dictAruco:
        return 'ArUco оригинальный';
    }
  }

  /// Стандартный словарь для новых пользователей
  static const ArucoDictionary defaultDictionary = ArucoDictionary.dict4x4_50;
}

/// Настройки разрешения камеры
enum CameraResolution {
  low('Низкое (480p)'),
  medium('Среднее (720p)'),
  high('Высокое (1080p)'),
  veryHigh('Очень высокое (4K)');

  const CameraResolution(this.displayName);

  final String displayName;

  static const CameraResolution defaultResolution = CameraResolution.veryHigh;
}

/// Настройки производительности для обработки изображений
class PerformanceSettings {
  final double downscaleFactor; // 0.1 - 1.0
  final int maxFps; // 1 - 60
  final bool useAsyncProcessing;
  final bool enablePoseEstimation;

  const PerformanceSettings({
    this.downscaleFactor = 0.5,
    this.maxFps = 30,
    this.useAsyncProcessing = true,
    this.enablePoseEstimation = false,
  });

  PerformanceSettings copyWith({
    double? downscaleFactor,
    int? maxFps,
    bool? useAsyncProcessing,
    bool? enablePoseEstimation,
  }) {
    return PerformanceSettings(
      downscaleFactor: downscaleFactor ?? this.downscaleFactor,
      maxFps: maxFps ?? this.maxFps,
      useAsyncProcessing: useAsyncProcessing ?? this.useAsyncProcessing,
      enablePoseEstimation: enablePoseEstimation ?? this.enablePoseEstimation,
    );
  }

  /// Профиль производительности: быстрый
  static const PerformanceSettings fast = PerformanceSettings(
    downscaleFactor: 0.5,
    maxFps: 30,
    useAsyncProcessing: true,
    enablePoseEstimation: false,
  );

  /// Профиль производительности: сбалансированный
  static const PerformanceSettings balanced = PerformanceSettings(
    downscaleFactor: 0.75,
    maxFps: 25,
    useAsyncProcessing: true,
    enablePoseEstimation: true,
  );

  /// Профиль производительности: качество
  static const PerformanceSettings quality = PerformanceSettings(
    downscaleFactor: 1.0,
    maxFps: 20,
    useAsyncProcessing: true,
    enablePoseEstimation: true,
  );

  String get displayName {
    if (this == fast) return 'Быстрая';
    if (this == balanced) return 'Сбалансированная';
    if (this == quality) return 'Качественная';
    return 'Пользовательская';
  }
}
