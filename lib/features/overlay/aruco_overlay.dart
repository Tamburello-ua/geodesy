import 'dart:math' as dart_math;
import 'package:flutter/material.dart';
import 'package:geodesy/features/overlay/aruco_painter.dart';
import 'package:geodesy/models/marker_detection.dart';

class ArucoOverlay extends StatelessWidget {
  final List<MarkerDetection> detections;
  final Size? previewSize;
  final double? imageWidth;
  final double? imageHeight;
  final int? sensorOrientation;
  final bool showIds;
  final bool showCorners;
  final Color markerColor;
  final Color idColor;
  final double strokeWidth;

  final double? finalPitch;
  final double? finalRoll;
  final double? finalYaw;
  final double? verticalFovDegrees;
  final bool? showPointer;

  const ArucoOverlay({
    super.key,
    required this.detections,
    this.previewSize,
    this.imageWidth,
    this.imageHeight,
    this.sensorOrientation,
    this.showIds = true,
    this.showCorners = true,
    this.markerColor = Colors.green,
    this.idColor = Colors.white,
    this.strokeWidth = 1.0,

    this.finalPitch,
    this.finalRoll,
    this.finalYaw,
    this.verticalFovDegrees,
    this.showPointer = false,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: ArucoOverlayPainter(
        detections: detections,
        previewSize: previewSize,
        imageWidth: imageWidth,
        imageHeight: imageHeight,
        sensorOrientation: sensorOrientation,
        showIds: showIds,
        showCorners: showCorners,
        markerColor: markerColor,
        idColor: idColor,
        strokeWidth: strokeWidth,

        finalPitch: finalPitch,
        finalRoll: finalRoll,
        finalYaw: finalYaw,
        verticalFovDegrees: verticalFovDegrees,
        showPointer: showPointer,
      ),
      child: Container(),
    );
  }
}

double cos(double radians) => dart_math.cos(radians);
double sin(double radians) => dart_math.sin(radians);
