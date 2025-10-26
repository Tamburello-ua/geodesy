import 'package:flutter/material.dart';
import 'package:geodesy/models/marker_detection.dart';
import 'package:geodesy/screen/utils/position_data.dart';
import 'package:geolocator/geolocator.dart';

class PositionData extends StatelessWidget {
  final List<MarkerDetection> detectedMarkers;
  final Position? userPosition;
  final Map<String, double>? motionData;
  final double? finalPitch;

  const PositionData({
    super.key,
    required this.detectedMarkers,
    this.userPosition,
    this.motionData,
    this.finalPitch,
  });

  @override
  Widget build(BuildContext context) {
    var data = getPositionData(detectedMarkers, finalPitch ?? 0.0);

    return Center(
      child: Container(
        color: Colors.black.withValues(alpha: 0.30),
        child: Column(
          children: [
            detectedMarkers.isNotEmpty
                ? Center(
                    child: Text(
                      [
                        "Pixel distance: ${data['pixel_distance']?.toStringAsFixed(3)}",
                        // "Compensate1 distance: ${data['geminy_pixel_distance']?.toStringAsFixed(3)}",
                        "Distance (cm): ${data['distance_cm']?.toStringAsFixed(3)}",
                        // "Optical Distance (cm): ${data['optical_distance_cm']?.toStringAsFixed(3)}",
                      ].join('\n'),
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  )
                : SizedBox.shrink(),
            userPosition != null
                ? Text(
                    'Latitude    ${userPosition?.latitude}\nLongitude ${userPosition?.longitude}\n',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  )
                : SizedBox.shrink(),
          ],
        ),
      ),
    );
  }
}
