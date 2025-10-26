import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:geodesy/screen/widget/position_data.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geodesy/features/camera/camera_controller.dart';
import 'package:geodesy/features/overlay/aruco_overlay.dart';
import 'package:geodesy/models/aruco_settings.dart';
import 'package:geodesy/models/marker_detection.dart';

/// Страница для сканирования ArUco-маркеров
class ArucoScannerPage extends StatefulWidget {
  const ArucoScannerPage({super.key});

  @override
  State<ArucoScannerPage> createState() => _ArucoScannerPageState();
}

class _ArucoScannerPageState extends State<ArucoScannerPage>
    with WidgetsBindingObserver {
  final ArucoScannerCameraController _cameraController =
      ArucoScannerCameraController.instance;

  List<MarkerDetection> _detectedMarkers = [];
  String? _errorMessage;
  bool _isInitializing = true;
  bool showDebug = false;

  // Настройки
  final ArucoDictionary _currentDictionary = ArucoDictionary.dict4x4_50;
  final PerformanceSettings _performanceSettings = PerformanceSettings.quality;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController.dispose();
    super.dispose();
  }

  /// Инициализирует камеру и начинает распознавание
  Future<void> _initializeCamera() async {
    setState(() {
      _isInitializing = true;
      _errorMessage = null;
    });

    try {
      // Проверка разрешения на доступ к камере
      final cameraPermission = await Permission.camera.request();
      if (!cameraPermission.isGranted) {
        setState(() {
          _errorMessage = 'Нет разрешения на доступ к камере';
          _isInitializing = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Нет разрешения на доступ к камере')),
          );
        }
        return;
      }
      print('Разрешение на камеру получено');

      final success = await _cameraController.initialize(
        resolution: CameraResolution.veryHigh,
        dictionary: _currentDictionary,
        settings: _performanceSettings,
      );

      if (!success) {
        setState(() {
          _errorMessage = 'Не удалось инициализировать камеру';
          _isInitializing = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Не удалось инициализировать камеру')),
          );
        }
        return;
      }

      // Запустить непрерывное распознавание сразу после инициализации
      _cameraController.startContinuousDetection();

      // Слушать поток распознавания для непрерывных обновлений
      _cameraController.detectionStream.listen(
        (detections) {
          if (mounted) {
            setState(() {
              _detectedMarkers = List<MarkerDetection>.from(
                detections,
              ); // Создаём новый список
            });
            if (showDebug) {
              print(
                'Received detections: ${detections.length}, '
                'previewSize: ${_cameraController.controller?.value.previewSize}, '
                'imageSize: ${_cameraController.imageWidth}x${_cameraController.imageHeight}, '
                'sensorOrientation: ${_cameraController.sensorOrientation}',
              );
            }
          }
        },
        onError: (error) {
          if (mounted) {
            setState(() {
              _errorMessage = 'Ошибка при распознавании маркеров: $error';
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Ошибка при распознавании маркеров: $error'),
              ),
            );
          }
        },
      );

      setState(() {
        _isInitializing = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Ошибка инициализации камеры: $e';
        _isInitializing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка инициализации камеры: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_cameraController.isInitialized ||
        _cameraController.controller?.value.previewSize == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final previewSize = _cameraController.controller!.value.previewSize!;
    final aspectRatio = previewSize.height / previewSize.width;

    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.black,

        body: ListView(
          children: [
            AspectRatio(
              aspectRatio: aspectRatio,
              child: Stack(
                children: [
                  Positioned.fill(child: _buildCameraPreview()),

                  if (_cameraController.isInitialized)
                    Positioned.fill(
                      child: IgnorePointer(
                        // Игнорировать события касания на оверлее
                        child: ArucoOverlay(
                          detections: _detectedMarkers,
                          previewSize:
                              _cameraController.controller?.value.previewSize,
                          imageWidth:
                              _cameraController.imageWidth, // Новый параметр
                          imageHeight:
                              _cameraController.imageHeight, // Новый параметр
                          sensorOrientation: _cameraController
                              .sensorOrientation, // Новый параметр
                          showIds: true,
                          showCorners: true,
                          markerColor: Colors.green,
                        ),
                      ),
                    ),

                  if (_errorMessage != null)
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        color: Colors.red.withValues(alpha: 0.8),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: Colors.purpleAccent,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),

                  if (_isInitializing)
                    const Center(child: CircularProgressIndicator()),
                ],
              ),
            ),
            PositionData(detectedMarkers: _detectedMarkers),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraPreview() {
    if (!_cameraController.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    return CameraPreview(_cameraController.controller!);
  }
}
