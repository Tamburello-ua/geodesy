import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:camera/camera.dart';

import '../cv/cv_service.dart';
import '../../models/marker_detection.dart';
import '../../models/aruco_settings.dart';

/// Контроллер для камеры и распознавания ArUco
class ArucoScannerCameraController {
  static ArucoScannerCameraController? _instance;
  static ArucoScannerCameraController get instance =>
      _instance ??= ArucoScannerCameraController._();

  ArucoScannerCameraController._();

  CameraController? _controller;
  StreamController<List<MarkerDetection>>? _detectionStreamController;
  ReceivePort? _receivePort;
  ReceivePort? _sendPortReceivePort; // Отдельный ReceivePort для SendPort
  SendPort? _isolateSendPort;
  Isolate? _isolate;
  // Timer? _throttleTimer;

  bool _isInitialized = false;
  bool _isProcessingFrame = false;
  bool _isDisposed = false;
  bool showDebug = false;

  double? _currentImageWidth;
  double? _currentImageHeight;

  final CvService _cvService = CvService();

  /// Поток для обнаруженных маркеров
  Stream<List<MarkerDetection>> get detectionStream =>
      _detectionStreamController?.stream ?? const Stream.empty();

  /// Инициализирована ли камера?
  bool get isInitialized =>
      _isInitialized && _controller?.value.isInitialized == true;

  /// Контроллер камеры (для предварительного просмотра)
  CameraController? get controller => _controller;

  // Геттеры для размеров изображения
  double? get imageWidth => _currentImageWidth;
  double? get imageHeight => _currentImageHeight;

  // Геттер для ориентации сенсора камеры
  int? get sensorOrientation => _controller?.description.sensorOrientation;

  /// Инициализирует камеру и изолят
  Future<bool> initialize({
    CameraResolution resolution = CameraResolution.veryHigh,
    ArucoDictionary dictionary = ArucoDictionary.dict4x4_50,
    PerformanceSettings? settings,
  }) async {
    if (_isDisposed) {
      print('Ошибка: Контроллер уже уничтожен');
      return false;
    }
    if (_isInitialized) {
      print('Контроллер уже инициализирован, пропуск повторной инициализации');
      return true;
    }

    try {
      // Получить доступные камеры
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        print('Ошибка: Нет доступных камер');
        return false;
      }
      print('Доступные камеры: ${cameras.map((c) => c.name).toList()}');

      // Выбрать основную камеру (обычно первую)
      final camera = cameras.first;
      print('Выбрана камера: ${camera.name}');

      // Создать контроллер камеры
      final preset = _getResolutionPreset(resolution);
      _controller = CameraController(
        camera,
        preset,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      // Инициализировать камеру
      try {
        await _controller!.initialize();
        print('Камера успешно инициализирована с разрешением: $preset');
      } catch (e) {
        print('Ошибка инициализации CameraController: $e');
        return false;
      }

      // Инициализировать сервис CV
      final cvInitialized = await _cvService.init(
        dictionary: dictionary,
        settings: settings,
      );
      if (!cvInitialized) {
        print('Ошибка: Не удалось инициализировать CvService');
        return false;
      }
      print(
        'CvService успешно инициализирован с словарем: ${dictionary.displayName}',
      );

      // Создать поток для распознавания
      try {
        if (_detectionStreamController != null) {
          print('Закрытие существующего StreamController');
          await _detectionStreamController!.close();
        }
        _detectionStreamController =
            StreamController<List<MarkerDetection>>.broadcast();
        print('StreamController для распознавания создан');
      } catch (e) {
        print('Ошибка создания StreamController: $e');
        return false;
      }

      // Запустить изолят для непрерывной обработки
      try {
        await _startIsolate();
        print('Изолят успешно запущен');
      } catch (e) {
        print('Ошибка запуска изолята: $e');
        return false;
      }

      _isInitialized = true;
      print('ArucoScannerCameraController успешно инициализирован');
      return true;
    } catch (e) {
      print('Общая ошибка при инициализации камеры: $e');
      return false;
    }
  }

  /// Конвертирует CameraResolution в ResolutionPreset
  ResolutionPreset _getResolutionPreset(CameraResolution resolution) {
    switch (resolution) {
      case CameraResolution.low:
        return ResolutionPreset.low;
      case CameraResolution.medium:
        return ResolutionPreset.medium;
      case CameraResolution.high:
        return ResolutionPreset.high;
      case CameraResolution.veryHigh:
        return ResolutionPreset.veryHigh;
    }
  }

  /// Запускает изолят для распознавания маркеров
  Future<void> _startIsolate() async {
    // Закрыть существующие ReceivePort, если они есть
    if (_receivePort != null) {
      print('Закрытие существующего ReceivePort для данных');
      _receivePort!.close();
      _receivePort = null;
    }
    if (_sendPortReceivePort != null) {
      print('Закрытие существующего ReceivePort для SendPort');
      _sendPortReceivePort!.close();
      _sendPortReceivePort = null;
    }
    // Завершить существующий изолят, если он есть
    if (_isolate != null) {
      print('Завершение существующего изолята');
      _isolate!.kill(priority: Isolate.immediate);
      _isolate = null;
    }

    try {
      // Создать ReceivePort для получения SendPort
      _sendPortReceivePort = ReceivePort();
      print('Создан ReceivePort для SendPort');

      // Запустить изолят
      _isolate = await Isolate.spawn(
        _detectionIsolate,
        _sendPortReceivePort!.sendPort,
      );
      print('Изолят успешно создан');

      // Получить SendPort изолята
      _isolateSendPort = await _sendPortReceivePort!.first;
      print('Получен SendPort изолята : ${_isolateSendPort.hashCode}');

      // Закрыть ReceivePort для SendPort после получения
      _sendPortReceivePort!.close();
      _sendPortReceivePort = null;
      print('ReceivePort для SendPort закрыт');

      // Создать отдельный ReceivePort для данных
      _receivePort = ReceivePort();
      print('Создан ReceivePort для данных: ${_receivePort.hashCode}');

      // Получать результаты из изолята через SendPort
      _receivePort!.listen(
        (data) {
          _isProcessingFrame = false;
          if (showDebug) {
            print(
              'Received data from isolate: type=${data.runtimeType}, data=$data',
            );
          }
          if (data is List<MarkerDetection> && !_isDisposed) {
            if (showDebug) print('Adding ${data.length} detections to stream');
            _detectionStreamController?.add(data);
          } else {
            print(
              'Data is not List<MarkerDetection> or controller is disposed: isDisposed=$_isDisposed',
            );
          }
        },
        onError: (error) {
          _isProcessingFrame = false;
          print(
            'Ошибка в потоке ReceivePort: $error, StackTrace: ${StackTrace.current}',
          );
        },
      );

      // Отправить SendPort от _receivePort в изолят
      _isolateSendPort!.send(_receivePort!.sendPort); // Новая строка
      print('Sent main ReceivePort SendPort to isolate');
    } catch (e) {
      print('Ошибка запуска изолята: $e');
      rethrow;
    }
  }

  /// Функция изолята для распознавания маркеров
  static void _detectionIsolate(SendPort initialSendPort) async {
    final receivePort = ReceivePort();
    initialSendPort.send(
      receivePort.sendPort,
    ); // Handshaking: отправляем SendPort изолята

    SendPort? mainResponseSendPort; // Для отправки detections в основной поток

    final cvService = CvService();
    ArucoDictionary currentDictionary = ArucoDictionary.dict4x4_50;
    PerformanceSettings currentSettings = PerformanceSettings.balanced;
    await cvService.init(
      dictionary: currentDictionary,
      settings: currentSettings,
    );

    receivePort.listen((message) async {
      // Первое сообщение — это SendPort основного потока для ответов
      if (mainResponseSendPort == null && message is SendPort) {
        mainResponseSendPort = message;
        print(
          'Isolate received main response SendPort: ${mainResponseSendPort.hashCode}',
        );
        return;
      }

      // Последующие сообщения — данные изображения
      if (message is Map<String, dynamic>) {
        final imageBytes = message['imageBytes'] as List<int>?;
        final width = message['width'] as int?;
        final height = message['height'] as int?;
        final dictionary = message['dictionary'] as ArucoDictionary?;
        final settings = message['settings'] as PerformanceSettings?;

        // print(
        //   'Isolate processing image: ${imageBytes?.length} bytes, $width x $height',
        // );

        if (imageBytes != null &&
            width != null &&
            height != null &&
            dictionary != null &&
            settings != null) {
          // Обновить словарь только если он изменился
          if (dictionary != currentDictionary) {
            await cvService.changeDictionary(dictionary);
            currentDictionary = dictionary;
            print('Смена словаря на: ${dictionary.displayName}');
          }

          // Обновить настройки только если они изменились
          if (settings != currentSettings) {
            cvService.updatePerformanceSettings(settings);
            currentSettings = settings;
            print(
              'Настройки производительности обновлены: ${settings.displayName}',
            );
          }

          // Распознать маркеры
          final detections = await cvService.detectMarkersFromImageBytes(
            Uint8List.fromList(imageBytes),
            width,
            height,
          );
          // print(
          //   'Sending detections from isolate: type=${detections.runtimeType}, count=${detections.length}',
          // );
          if (mainResponseSendPort != null) {
            mainResponseSendPort?.send(
              detections,
            ); // Отправляем в правильный SendPort
          } else {
            print('Ошибка: mainResponseSendPort не инициализирован');
          }
        }
      }
    });
  }

  /// Запускает непрерывное распознавание
  void startContinuousDetection() {
    if (!_isInitialized ||
        _controller == null ||
        _controller!.value.isStreamingImages) {
      return;
    }

    _controller!.startImageStream(_processImage);
  }

  void stopContinuousDetection() {
    if (_controller != null && _controller!.value.isStreamingImages) {
      _controller!.stopImageStream();
      _isProcessingFrame = false; // Сбрасываем блокировку
    }
  }

  void _processImage(CameraImage cameraImage) async {
    if (showDebug) {
      print('Processing image: ${cameraImage.width}x${cameraImage.height}');
    }
    if (_isolateSendPort == null || _isProcessingFrame) {
      if (showDebug) {
        print(
          'Skipping image processing: isolateSendPort=$_isolateSendPort, isProcessingFrame=$_isProcessingFrame',
        );
      }
      return;
    }

    _isProcessingFrame = true;

    // Обновляем текущие размеры изображения
    _currentImageWidth = cameraImage.width.toDouble();
    _currentImageHeight = cameraImage.height.toDouble();

    // --- ИСПРАВЛЕНИЕ: Создание чистого массива байтов без padding ---
    final imageBytesNoPadding = _getYPlaneWithoutPadding(cameraImage);
    final width = cameraImage.width;
    final height = cameraImage.height;
    if (showDebug) {
      print(
        'Sending image to isolate: ${imageBytesNoPadding.length} bytes, $width x $height',
      );
    }
    // --------------------------------------------------------------------

    // Отправить изображение, словарь и настройки в изолят
    _isolateSendPort!.send({
      'imageBytes': imageBytesNoPadding, // Отправляем очищенные байты
      'width': width,
      'height': height,
      'dictionary': _cvService.currentDictionary,
      'settings': _cvService.performanceSettings,
    });
  }

  // Новая вспомогательная функция
  Uint8List _getYPlaneWithoutPadding(CameraImage image) {
    final plane = image.planes[0];
    final bytes = plane.bytes;
    final width = image.width;
    final height = image.height;
    final rowStride = plane.bytesPerRow; // Это и есть rowStride

    // Если rowStride равен ширине, padding отсутствует.
    if (rowStride == width) {
      return bytes;
    }

    // Создаем новый массив байтов, исключая padding.
    final cleanBytes = Uint8List(width * height);
    int cleanIndex = 0;

    for (int y = 0; y < height; y++) {
      // Начало текущей строки в исходных байтах
      final start = y * rowStride;
      // Конец фактических данных (ширина) в текущей строке
      final end = start + width;

      // Копируем только фактические пиксельные данные
      for (int x = start; x < end; x++) {
        cleanBytes[cleanIndex++] = bytes[x];
      }
    }

    return cleanBytes;
  }

  /// УДАЛЕНА: Старая функция конвертации YUV -> RGB -> JPEG удалена,
  /// так как мы используем Y-плоскость напрямую.
  // Future<List<int>> _convertCameraImageToBytes(CameraImage image) async { ... }

  /// Изменяет словарь ArUco
  Future<bool> changeDictionary(ArucoDictionary dictionary) async {
    if (!_isInitialized) return false;
    return await _cvService.changeDictionary(dictionary);
  }

  /// Обновляет настройки производительности
  void updatePerformanceSettings(PerformanceSettings settings) {
    _cvService.updatePerformanceSettings(settings);
  }

  /// Получает текущие настройки
  ArucoDictionary get currentDictionary => _cvService.currentDictionary;
  PerformanceSettings get performanceSettings => _cvService.performanceSettings;

  /// Корректно завершает работу контроллера
  Future<void> dispose() async {
    _isDisposed = true;

    stopContinuousDetection();

    if (_controller != null) {
      await _controller!.dispose();
      _controller = null;
    }

    if (_isolate != null) {
      print('Завершение изолята при dispose');
      _isolate!.kill(priority: Isolate.immediate);
      _isolate = null;
    }
    if (_receivePort != null) {
      print('Закрытие ReceivePort для данных при dispose');
      _receivePort!.close();
      _receivePort = null;
    }
    if (_sendPortReceivePort != null) {
      print('Закрытие ReceivePort для SendPort при dispose');
      _sendPortReceivePort!.close();
      _sendPortReceivePort = null;
    }
    _isolateSendPort = null;

    if (_detectionStreamController != null) {
      print('Закрытие StreamController при dispose');
      await _detectionStreamController!.close();
      _detectionStreamController = null;
    }

    _cvService.dispose();
    _isInitialized = false;
  }
}
