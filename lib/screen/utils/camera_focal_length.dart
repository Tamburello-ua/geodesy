import 'package:flutter/services.dart';

class CameraFocalLength {
  static const MethodChannel _channel = MethodChannel(
    'com.example.geodesy/camera_focal_length',
  );

  static Future<Map<String, dynamic>> getCameraFullInfo(int cameraId) async {
    final Map<dynamic, dynamic> result = await _channel.invokeMethod(
      'getCameraFullInfo',
      {'cameraId': cameraId.toString()},
    );
    return Map<String, dynamic>.from(result);
  }

  /// Get all available camera focal lengths
  /// Returns a Map where key is camera ID and value is List of focal lengths
  static Future<Map<String, List<double>>> getAllCameraFocalLengths() async {
    try {
      final Map<dynamic, dynamic> result = await _channel.invokeMethod(
        'getAllCameraFocalLengths',
      );

      // Convert the result to proper types
      Map<String, List<double>> focalLengths = {};
      result.forEach((key, value) {
        if (value is List) {
          focalLengths[key.toString()] = value.cast<double>();
        }
      });

      return focalLengths;
    } on PlatformException catch (e) {
      throw Exception('Failed to get camera focal lengths: ${e.message}');
    }
  }

  /// Get focal length for a specific camera
  /// cameraId: "0" for back camera, "1" for front camera (typically)
  static Future<List<double>> getCameraFocalLength(String cameraId) async {
    try {
      final List<dynamic> result = await _channel.invokeMethod(
        'getCameraFocalLength',
        {'cameraId': cameraId},
      );
      return result.cast<double>();
    } on PlatformException catch (e) {
      throw Exception(
        'Failed to get focal length for camera $cameraId: ${e.message}',
      );
    }
  }

  /// Get focal length for the default back camera (camera "0")
  static Future<List<double>> getBackCameraFocalLength() async {
    return getCameraFocalLength("0");
  }

  /// Get focal length for the default front camera (camera "1")
  static Future<List<double>> getFrontCameraFocalLength() async {
    return getCameraFocalLength("1");
  }

  /// Get sensor size for a specific camera (returns width and height in mm)
  static Future<Map<String, double>> getCameraSensorSize(
    String cameraId,
  ) async {
    try {
      final Map<dynamic, dynamic> result = await _channel.invokeMethod(
        'getCameraSensorSize',
        {'cameraId': cameraId},
      );
      return {
        'width': result['width']?.toDouble() ?? 0.0,
        'height': result['height']?.toDouble() ?? 0.0,
      };
    } on PlatformException catch (e) {
      throw Exception(
        'Failed to get sensor size for camera $cameraId: ${e.message}',
      );
    }
  }

  /// Get complete camera info (focal lengths + sensor size) for accurate pixel calculations
  static Future<Map<String, dynamic>> getCameraInfo(String cameraId) async {
    try {
      final focalLengths = await getCameraFocalLength(cameraId);
      final sensorSize = await getCameraSensorSize(cameraId);
      return {'focalLengths': focalLengths, 'sensorSize': sensorSize};
    } catch (e) {
      throw Exception('Failed to get camera info for camera $cameraId: $e');
    }
  }
}
