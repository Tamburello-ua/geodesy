import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:geodesy/screen/utils/fov_utils.dart';
import 'package:geodesy/screen/utils/position_data.dart';
import 'package:geodesy/screen/widget/combo_compensator.dart';
import 'package:geodesy/screen/widget/compass.dart';
import 'package:geodesy/screen/widget/geo_point_widget.dart';
import 'package:geodesy/screen/widget/gps_path_widget.dart';
import 'package:geodesy/screen/widget/position_data.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geodesy/features/camera/camera_controller.dart';
import 'package:geodesy/features/overlay/aruco_overlay.dart';
import 'package:geodesy/models/aruco_settings.dart';
import 'package:geodesy/models/marker_detection.dart';

import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'package:motion_core/motion_core.dart';
import 'package:flutter_compass/flutter_compass.dart';

import 'package:geodesy/screen/utils/gps.dart';
import 'package:geodesy/screen/utils/kalman_filter.dart';
import 'package:geodesy/screen/utils/compensated_angles.dart';

class ComboScreen extends StatefulWidget {
  const ComboScreen({super.key});

  @override
  State<ComboScreen> createState() => _ComboScreenState();
}

class _ComboScreenState extends State<ComboScreen> with WidgetsBindingObserver {
  final ArucoScannerCameraController _cameraController =
      ArucoScannerCameraController.instance;

  List<MarkerDetection> _detectedMarkers = [];
  String? _errorMessage;
  bool _isInitializing = true;
  bool _isAvailable = false;
  bool init = true;

  // Настройки
  final ArucoDictionary _currentDictionary = ArucoDictionary.dict4x4_50;
  final PerformanceSettings _performanceSettings = PerformanceSettings.quality;

  MotionData? _motionData;
  StreamSubscription? _motionSubscription;

  double finalPitch = 0;
  double finalRoll = 0;
  double finalYaw = 0;
  double magneticYaw = 0;
  String mode = '';

  final GPS _gps = GPS();
  Position? _userPosition;
  // ignore: unused_field
  Exception? _exception;

  List<Position> positions = [];
  List<Position> filteredPositions = [];
  final processor = KalmanFilter();

  final showGpsPath = false;
  final showBottomText = true;
  final showDebug = false;
  final showOpticPath = true;

  bool needCalibration = false;

  final double VERTICAL_FOV = 63.1;
  final double HORIZONTAL_FOV = 49.7;

  Size previewSize = Size.zero;
  Map<String, dynamic> compensated = {};
  final FOVCalibration fovCalibration = FOVCalibration();

  late StreamSubscription<CompassEvent> _compassSubscription;
  Map<String, double> _targetPoint = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _initializeAll();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController.dispose();
    _motionSubscription?.cancel();
    _compassSubscription.cancel();

    super.dispose();
  }

  Future<void> _checkAvailabilityAndStart() async {
    bool available = await MotionCore.isAvailable();
    if (!mounted) return;
    setState(() => _isAvailable = available);
    if (_isAvailable) _startMotionListening();
  }

  void _handlePositionStream(Position position) {
    if (positions.length > 50) {
      positions.removeAt(0);
    }

    positions.add(position);

    processor.process(position, true);

    final originalLat = position.latitude.toStringAsFixed(5);
    final filteredLat = processor.lastFilteredPosition!.latitude
        .toStringAsFixed(5);

    final originalLon = position.longitude.toStringAsFixed(5);
    final filteredLon = processor.lastFilteredPosition!.longitude
        .toStringAsFixed(5);
    final filteredAcc = processor.lastFilteredPosition!.accuracy
        .toStringAsFixed(2);

    print(
      '* $originalLat $originalLon | $filteredLat $filteredLon ($filteredAcc м)',
    );

    filteredPositions = processor.filteredPositions;

    setState(() {
      _userPosition = position;
      print(position.toString());
    });

    if (init) {
      init = false;
    }
  }

  Future<void> _initializeAll() async {
    bool granted = await _requestAllPermissions();
    if (!granted) {
      setState(() => _isInitializing = false);
      return;
    }

    _startCompassListening();
    await _checkAvailabilityAndStart();
    await _initializeCamera();
    await _initializeLocation();
  }

  Future<bool> _requestAllPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.camera,
      Permission.location,
      Permission.locationWhenInUse,
    ].request();

    bool allGranted = statuses.values.every((status) => status.isGranted);

    if (!allGranted) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Не все разрешения получены. Пожалуйста, предоставьте их в настройках.',
          ),
        ),
      );
    }

    return allGranted;
  }

  Future<void> _startCompassListening() async {
    _compassSubscription = FlutterCompass.events!.listen((event) {
      magneticYaw = event.heading ?? 0.0;
    });
  }

  Future<void> _startMotionListening() async {
    _motionSubscription = MotionCore.motionStream.listen((data) {
      if (mounted) {
        setState(() {
          _motionData = data;

          compensated = getCompensatedAngles(_motionData);
          finalPitch = compensated['pitch']!;
          finalRoll = compensated['roll']!;
          finalYaw = compensated['yaw']!;
          mode = compensated['mode']!;
        });
      }
    });
  }

  Future<void> _initializeLocation() async {
    if (await Permission.locationWhenInUse.serviceStatus.isEnabled) {
      _gps.startPositionStream(_handlePositionStream).catchError((e) {
        setState(() {
          _exception = e;
        });
      });
    }
  }

  /// Инициализирует камеру и начинает распознавание
  Future<void> _initializeCamera() async {
    setState(() {
      _isInitializing = true;
      _errorMessage = null;
    });

    try {
      if (!await Permission.camera.isGranted) {
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

              if (_detectedMarkers.isNotEmpty && needCalibration) {
                _handleCalibration(_detectedMarkers);
              }

              _targetPoint = getHandleBottom(
                detectedMarkers: _detectedMarkers,
                pitch: finalPitch,
                distanceToHandleBottomMM: 80.0,
                distanceBetweenMarkersMM: 100.0,
                orientation: _cameraController.sensorOrientation ?? 0,
              );
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
      setState(() {
        _errorMessage = 'Ошибка инициализации камеры: $e';
        _isInitializing = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка инициализации камеры: $e')),
        );
      }
    }
  }

  void _handleCalibration(List<MarkerDetection> markers) {
    var posData = getPositionData(markers, finalPitch);

    if (finalPitch.abs() > 0.0001) {
      // fovCalibration.addPoint(finalPitch, relativeShift);

      fovCalibration.addCalibrationPoint(
        finalPitch,
        posData['pixel_distance']!,
        previewSize.height,
      );
      // print('Добавлена точка калибровки: pitch=$finalPitch, Y=$relativeShift');
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

    previewSize = _cameraController.controller!.value.previewSize!;
    final aspectRatio = previewSize.height / previewSize.width;

    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.black,

        body: Stack(
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: AspectRatio(
                aspectRatio: aspectRatio,
                child: Stack(
                  children: [
                    Positioned.fill(child: _buildCameraPreview()),
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.75),
                      ),
                    ),

                    if (_cameraController.isInitialized)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: ArucoOverlay(
                            detections: _detectedMarkers,
                            previewSize:
                                _cameraController.controller?.value.previewSize,
                            imageWidth: _cameraController.imageWidth,
                            imageHeight: _cameraController.imageHeight,
                            sensorOrientation:
                                _cameraController.sensorOrientation,
                            showIds: true,
                            showCorners: true,
                            markerColor: Colors.green,
                            finalPitch: finalPitch,
                            finalRoll: finalRoll,
                            finalYaw: finalYaw,
                            verticalFovDegrees: VERTICAL_FOV,
                            showPointer: true,
                            targetPoint: Offset(
                              _targetPoint['handle_point_y'] ?? 0.0,
                              _targetPoint['handle_point_x'] ?? 0.0,
                            ),
                          ),
                        ),
                      ),

                    Positioned.fill(
                      child: ComboCompensator(finalPitch, finalRoll, finalYaw),
                    ),

                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: SizedBox(
                        height: 100,

                        child: CompassOverlayWidget(
                          currentAzimuth: finalYaw,
                          magneticAzimuth: magneticYaw,
                          horizontalFOV: VERTICAL_FOV,
                        ),
                      ),
                    ),
                  ],
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

            if (showOpticPath)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Center(
                  child: GeoPointWidget(
                    azimuth: finalYaw,
                    finalPitch: finalPitch,
                    detectedMarkers: _detectedMarkers,
                    verticalFovDegrees: VERTICAL_FOV,
                    horizontalFovDegrees: HORIZONTAL_FOV,
                    targetPointX: _targetPoint['handle_point_x'] ?? 0.0,
                    originalFrameWidth: previewSize.height,
                  ),
                ),
              ),

            if (showGpsPath)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Center(
                  child: GPSPathWidget(
                    positions: positions,
                    filteredPositions: filteredPositions,
                  ),
                ),
              ),
            if (showBottomText)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: PositionData(
                  detectedMarkers: _detectedMarkers,
                  userPosition: _userPosition,
                  finalPitch: finalPitch,
                  showGpsCoordinates: false,
                ),
              ),
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
