import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:geodesy/models/aruco_settings.dart';
import 'package:geodesy/models/camera_calibration.dart';
import 'package:geodesy/models/marker_detection.dart';
import 'package:opencv_dart/opencv_dart.dart' as cv;

class CvService {
  bool _isInitialized = false;
  bool showDebug = false;
  ArucoDictionary _currentDictionary = ArucoDictionary.dict4x4_50;
  PerformanceSettings _performanceSettings = PerformanceSettings.balanced;

  // Объекты OpenCV
  cv.ArucoDictionary? _dictionary;
  cv.ArucoDetectorParameters? _detectorParams;
  cv.ArucoDetector? _detector;

  // Параметры для коррекции дисторсии
  cv.Mat? _cameraMatrix;
  cv.Mat? _distortionCoefficients;
  cv.Mat? _optimalCameraMatrix;
  cv.Mat? _map1;
  cv.Mat? _map2;
  int _currentWidth = 0;
  int _currentHeight = 0;

  /// Инициализирован ли сервис?
  bool get isInitialized => _isInitialized;
  ArucoDictionary get currentDictionary => _currentDictionary;
  PerformanceSettings get performanceSettings => _performanceSettings;

  Future<bool> init({
    ArucoDictionary dictionary = ArucoDictionary.dict4x4_50,
    PerformanceSettings? settings,
  }) async {
    try {
      print(
        'Начало инициализации CvService с словарем: ${dictionary.displayName}',
      );
      _currentDictionary = dictionary;
      _performanceSettings = settings ?? PerformanceSettings.balanced;
      _dictionary = cv.ArucoDictionary.predefined(
        _currentDictionary.predefinedType,
      );
      print('Словарь ArUco успешно создан: ${dictionary.displayName}');
      _detectorParams = cv.ArucoDetectorParameters.empty();
      print('Параметры детектора ArUco созданы');
      _detector = cv.ArucoDetector.create(_dictionary!, _detectorParams!);
      print('Детектор ArUco успешно создан');
      _isInitialized = true;
      print(
        'CvService успешно инициализирован с словарем: ${dictionary.displayName}',
      );
      return true;
    } catch (e) {
      print('Ошибка при инициализации CvService: $e');
      return false;
    }
  }

  /// Устанавливает параметры калибровки камеры для коррекции дисторсии
  void setCameraCalibration(CameraCalibration calibration) {
    try {
      // Освобождаем старые ресурсы
      _cameraMatrix?.release();
      _distortionCoefficients?.release();
      _optimalCameraMatrix?.release();
      _map1?.release();
      _map2?.release();

      // Создаем матрицу камеры 3x3
      _cameraMatrix = cv.Mat.fromList(
        3,
        3,
        cv.MatType.CV_64FC1,
        calibration.cameraMatrix,
      );

      // Создаем вектор коэффициентов дисторсии
      _distortionCoefficients = cv.Mat.fromList(
        1,
        5,
        cv.MatType.CV_64FC1,
        calibration.distortionCoefficients,
      );

      print('Параметры калибровки камеры установлены');
      print('Матрица камеры: ${calibration.cameraMatrix}');
      print('Коэффициенты дисторсии: ${calibration.distortionCoefficients}');
    } catch (e) {
      print('Ошибка при установке параметров калибровки: $e');
    }
  }

  /// Очищает параметры калибровки (отключает коррекцию дисторсии)
  void clearCameraCalibration() {
    _cameraMatrix?.release();
    _distortionCoefficients?.release();
    _optimalCameraMatrix?.release();
    _map1?.release();
    _map2?.release();

    _cameraMatrix = null;
    _distortionCoefficients = null;
    _optimalCameraMatrix = null;
    _map1 = null;
    _map2 = null;

    print('Коррекция дисторсии отключена');
  }

  void _computeUndistortMaps(int width, int height) {
    if (_cameraMatrix == null || _distortionCoefficients == null) return;
    if (_map1 != null &&
        _map2 != null &&
        _currentWidth == width &&
        _currentHeight == height) {
      return; // Карты уже вычислены для этого размера
    }

    try {
      _map1?.release();
      _map2?.release();

      // Вычисляем оптимальную новую матрицу камеры
      final (newCameraMatrix, roi) = cv.getOptimalNewCameraMatrix(
        _cameraMatrix!,
        _distortionCoefficients!,
        (width, height), // Размер как кортеж
        1.0, // alpha
        newImgSize: (width, height), // newImgsize
      );

      // Инициализируем карты преобразования - функция возвращает кортеж
      final (map1, map2) = cv.initUndistortRectifyMap(
        _cameraMatrix!,
        _distortionCoefficients!,
        cv.Mat.empty(), // R - матрица поворота (пустая)
        newCameraMatrix, // Новая матрица камеры
        (width, height), // Размер как кортеж
        cv.MatType.CV_32FC1.value,
      );

      _map1 = map1;
      _map2 = map2;

      newCameraMatrix.release();
      _currentWidth = width;
      _currentHeight = height;

      if (showDebug) {
        print(
          'Карты преобразования для коррекции дисторсии вычислены для размера $width x $height',
        );
      }
    } catch (e) {
      print('Ошибка при вычислении карт преобразования: $e');

      // Альтернативный подход: используем initUndistortRectifyMap без getOptimalNewCameraMatrix
      try {
        _map1?.release();
        _map2?.release();

        final (map1, map2) = cv.initUndistortRectifyMap(
          _cameraMatrix!,
          _distortionCoefficients!,
          cv.Mat.empty(), // R - матрица поворота
          _cameraMatrix!, // Используем исходную матрицу камеры
          (width, height),
          cv.MatType.CV_32FC1.value,
        );

        _map1 = map1;
        _map2 = map2;
        _currentWidth = width;
        _currentHeight = height;

        print('Карты преобразования вычислены альтернативным методом');
      } catch (e2) {
        print('Альтернативный метод также не сработал: $e2');
      }
    }
  }

  cv.Mat _undistortImage(cv.Mat image, int width, int height) {
    if (_cameraMatrix == null || _distortionCoefficients == null) {
      return image;
    }

    try {
      // Вычисляем карты преобразования если нужно
      _computeUndistortMaps(width, height);

      if (_map1 == null || _map2 == null) {
        print('Ошибка: карты преобразования не вычислены');
        return image;
      }

      // Применяем коррекцию используя предварительно вычисленные карты
      final undistortedImage = cv.Mat.empty();
      cv.remap(
        image,
        _map1!,
        _map2!,
        cv.INTER_LINEAR,
        dst: undistortedImage,
        borderMode: cv.BORDER_CONSTANT,
        borderValue: cv.Scalar(),
      );

      if (showDebug) {
        print('Коррекция дисторсии применена к изображению $width x $height');
      }

      return undistortedImage;
    } catch (e) {
      print('Ошибка при коррекции дисторсии: $e');
      return image; // Возвращаем исходное изображение в случае ошибки
    }
  }

  /// Распознаёт маркеры ArUco в изображении из байтов
  Future<List<MarkerDetection>> detectMarkersFromImageBytes(
    Uint8List imageBytes,
    int width,
    int height, {
    bool applyUndistortion = false,
  }) async {
    if (!_isInitialized || _detector == null) {
      print('Ошибка: CvService не инициализирован или детектор отсутствует');
      return [];
    }

    try {
      if (showDebug) {
        print('Начало распознавания маркеров из изображения');
        print('Размер изображения: $width x $height');
        print('Коррекция дисторсии: $applyUndistortion');
      }

      final mat = cv.Mat.zeros(height, width, cv.MatType.CV_8UC1);

      try {
        mat.data.setAll(0, imageBytes);
      } catch (e) {
        if (mat.data.length != imageBytes.length) {
          print(
            'Ошибка: Размер imageBytes (${imageBytes.length}) не совпадает с размером Mat (${mat.data.length}).',
          );
        }
        rethrow;
      }

      if (mat.isEmpty) {
        print('Ошибка: Создана пустая матрица');
        return [];
      }

      cv.Mat processingMat;
      bool shouldReleaseMat = false;

      // Применяем коррекцию дисторсии если нужно
      if (applyUndistortion &&
          _cameraMatrix != null &&
          _distortionCoefficients != null) {
        processingMat = _undistortImage(mat, width, height);
        shouldReleaseMat = true;
      } else {
        processingMat = mat;
      }

      final result = _detector!.detectMarkers(processingMat);
      final corners = result.$1;
      final ids = result.$2;
      final rejected = result.$3;
      if (showDebug) {
        print(
          'Обнаружено маркеров: ${ids.length}, отклонено: ${rejected.length}',
        );
      }

      final detections = <MarkerDetection>[];

      if (ids.isNotEmpty) {
        for (int i = 0; i < ids.length; i++) {
          final markerId = ids[i];
          final markerCorners = corners[i];

          // Конвертировать углы из OpenCV в координаты Flutter
          final cornerPoints = <Offset>[];
          for (int j = 0; j < markerCorners.length; j++) {
            final point = markerCorners[j];
            cornerPoints.add(Offset(point.x, point.y));
          }

          if (cornerPoints.length == 4) {
            detections.add(
              MarkerDetection(
                id: markerId,
                corners: cornerPoints,
                confidence: 1.0,
              ),
            );
          }
        }
      }

      processingMat.release();
      if (shouldReleaseMat) {
        mat.release();
      }

      if (showDebug) {
        print(
          'Распознавание маркеров завершено: ${detections.length} маркеров найдено',
        );
      }
      return detections;
    } catch (e) {
      print('Ошибка при распознавании маркеров: $e');
      return [];
    }
  }

  /// Распознаёт маркеры с коррекцией дисторсии (удобный метод)
  Future<List<MarkerDetection>> detectMarkersFromImageBytesWithUndistortion(
    Uint8List imageBytes,
    int width,
    int height,
    Map<String, dynamic>? calibration,
  ) async {
    if (calibration != null) {
      final cameraCalibration = CameraCalibration.fromJson(calibration);
      setCameraCalibration(cameraCalibration);
    }

    return detectMarkersFromImageBytes(
      imageBytes,
      width,
      height,
      applyUndistortion: true,
    );
  }

  Future<bool> changeDictionary(ArucoDictionary dictionary) async {
    if (!_isInitialized) {
      print('Ошибка: CvService не инициализирован');
      return false;
    }

    try {
      print('Смена словаря на: ${dictionary.displayName}');
      _currentDictionary = dictionary;

      // Освободить старые ресурсы
      _dictionary?.dispose();
      _detector?.dispose();

      // Создать новый словарь и детектор
      _dictionary = cv.ArucoDictionary.predefined(dictionary.predefinedType);
      _detector = cv.ArucoDetector.create(_dictionary!, _detectorParams!);
      print('Словарь успешно изменён на: ${dictionary.displayName}');
      return true;
    } catch (e) {
      print('Ошибка при смене словаря: $e');
      return false;
    }
  }

  /// Обновляет настройки производительности
  void updatePerformanceSettings(PerformanceSettings settings) {
    _performanceSettings = settings;
    print('Настройки производительности обновлены: ${settings.displayName}');
  }

  /// Завершает работу сервиса
  void dispose() {
    _isInitialized = false;

    _dictionary?.dispose();
    _detectorParams?.dispose();
    _detector?.dispose();

    _dictionary = null;
    _detectorParams = null;
    _detector = null;

    _cameraMatrix?.release();
    _distortionCoefficients?.release();
    _optimalCameraMatrix?.release();
    _map1?.release();
    _map2?.release();

    _dictionary = null;
    _detectorParams = null;
    _detector = null;
    _cameraMatrix = null;
    _distortionCoefficients = null;
    _optimalCameraMatrix = null;
    _map1 = null;
    _map2 = null;

    print('CvService завершён');
  }
}
