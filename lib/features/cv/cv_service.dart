import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:geodesy/features/cv/camera_intrinsics.dart';
import 'package:opencv_dart/opencv_dart.dart' as cv;
import '../../models/marker_detection.dart';
import '../../models/aruco_settings.dart';

class CvService {
  bool _isInitialized = false;
  bool showDebug = false;
  ArucoDictionary _currentDictionary = ArucoDictionary.dict4x4_50;
  PerformanceSettings _performanceSettings = PerformanceSettings.balanced;

  // Объекты OpenCV
  cv.ArucoDictionary? _dictionary;
  cv.ArucoDetectorParameters? _detectorParams;
  cv.ArucoDetector? _detector;

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

  /// Распознаёт маркеры ArUco в изображении из байтов
  Future<List<MarkerDetection>> detectMarkersFromImageBytes(
    Uint8List imageBytes,
    int width,
    int height, {
    required double markerSizeMM,
    required CameraIntrinsics intrinsics,
  }) async {
    if (!_isInitialized || _detector == null) {
      print('Ошибка: CvService не инициализирован или детектор отсутствует');
      return [];
    }

    try {
      if (showDebug) print('Начало распознавания маркеров из изображения');

      final mat = cv.Mat.zeros(height, width, cv.MatType.CV_8UC1);

      if (mat.isEmpty) {
        print('Ошибка: Создана пустая матрица');
        mat.dispose();
        return [];
      }

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

      final grayMat = mat;

      final result = _detector!.detectMarkers(grayMat);
      final corners = result.$1;
      final ids = result.$2;
      final rejected = result.$3;
      if (showDebug) {
        print(
          'Обнаружено маркеров: ${ids.length}, отклонено: ${rejected.length}',
        );
      }

      final detections = <MarkerDetection>[];

      final cameraMatrix = cv.Mat.zeros(3, 3, cv.MatType.CV_64FC1);

      cameraMatrix.set(0, 0, intrinsics.fx);
      cameraMatrix.set(0, 1, 0);
      cameraMatrix.set(0, 2, intrinsics.cx);

      cameraMatrix.set(1, 0, 0);
      cameraMatrix.set(1, 1, intrinsics.fy);
      cameraMatrix.set(1, 2, intrinsics.cy);

      cameraMatrix.set(2, 0, 0);
      cameraMatrix.set(2, 1, 0);
      cameraMatrix.set(2, 2, 1);

      final distCoeffs = cv.Mat.zeros(4, 1, cv.MatType.CV_64FC1);
      if (showDebug) {
        print(
          'fx=${intrinsics.fx}, fy=${intrinsics.fy}, cx=${intrinsics.cx}, cy=${intrinsics.cy}',
        );
        print('width=$width, height=$height');
      }

      for (int i = 0; i < ids.length; i++) {
        final id = ids[i];
        final cornerList = corners[i];

        final corners2d = cornerList.map((p) => Offset(p.x, p.y)).toList();

        // 3D модель маркера
        final objPoints = <cv.Point3f>[
          cv.Point3f(-markerSizeMM / 2, markerSizeMM / 2, 0),
          cv.Point3f(markerSizeMM / 2, markerSizeMM / 2, 0),
          cv.Point3f(markerSizeMM / 2, -markerSizeMM / 2, 0),
          cv.Point3f(-markerSizeMM / 2, -markerSizeMM / 2, 0),
        ];

        final objData = objPoints.expand((p) => [p.x, p.y, p.z]).toList();

        final objectPoints = cv.Mat.fromList(
          4,
          1,
          cv.MatType.CV_32FC3,
          objData,
        );

        // 2D углы
        final imgData = cornerList.expand((p) => [p.x, p.y]).toList();

        final imagePoints = cv.Mat.fromList(4, 1, cv.MatType.CV_32FC2, imgData);

        final (success, rvec, tvec) = cv.solvePnP(
          objectPoints,
          imagePoints,
          cameraMatrix,
          distCoeffs,
        );

        objectPoints.dispose();
        imagePoints.dispose();

        if (success) {
          detections.add(
            MarkerDetection(
              id: id,
              corners: corners2d,
              rvec: [
                rvec.at<double>(0, 0),
                rvec.at<double>(1, 0),
                rvec.at<double>(2, 0),
              ],
              tvec: [
                tvec.at<double>(0, 0),
                tvec.at<double>(1, 0),
                tvec.at<double>(2, 0),
              ],
              confidence: 1.0,
            ),
          );

          // Обязательно освободить!
          rvec.dispose();
          tvec.dispose();
        }
      }

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

      mat.dispose();
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

    print('CvService завершён');
  }
}
