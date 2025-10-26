import 'package:flutter/material.dart';
import 'package:geodesy/screen/utils/compensated_angles.dart';
import 'package:geodesy/screen/utils/gps.dart';
import 'package:geodesy/screen/utils/kalman_filter.dart';
import 'package:geodesy/screen/widget/combined_compensator.dart';
import 'package:geodesy/screen/widget/gps_path_widget.dart';
import 'package:geodesy/screen/widget/linear_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'package:motion_core/motion_core.dart';

class MotionDemoScreen extends StatefulWidget {
  const MotionDemoScreen({super.key});
  @override
  State<MotionDemoScreen> createState() => _MotionDemoScreenState();
}

class _MotionDemoScreenState extends State<MotionDemoScreen> {
  MotionData? _motionData;
  StreamSubscription? _motionSubscription;
  bool _isAvailable = false;

  double finalPitch = 0;
  double finalRoll = 0;
  double finalYaw = 0;
  String mode = '';

  final GPS _gps = GPS();
  late LocationPermission permission;
  Position? _userPosition;
  // ignore: unused_field
  Exception? _exception;
  bool init = true;
  List<Position> positions = [];
  List<Position> filteredPositions = [];
  final processor = KalmanFilter();

  @override
  void initState() {
    super.initState();
    _checkAvailabilityAndStart();

    _gps.startPositionStream(_handlePositionStream).catchError((e) {
      setState(() {
        _exception = e;
      });
    });
  }

  Future<void> _checkAvailabilityAndStart() async {
    bool available = await MotionCore.isAvailable();
    if (!mounted) return;
    setState(() => _isAvailable = available);
    if (_isAvailable) _startListening();
  }

  void _startListening() {
    _motionSubscription = MotionCore.motionStream.listen((data) {
      if (mounted) {
        setState(() {
          _motionData = data;

          final compensated = getCompensatedAngles(_motionData);
          finalPitch = compensated['pitch']!;
          finalRoll = compensated['roll']!;
          finalYaw = compensated['yaw']!;
          mode = compensated['mode']!;
        });
      }
    });
  }

  void _handlePositionStream(Position position) {
    if (positions.length > 50) {
      positions.removeAt(0);
    }

    positions.add(position);

    // for (final pos in positions) {
    // isStationary = true, так как телефон лежит неподвижно.
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
    // }

    filteredPositions = processor.filteredPositions;

    setState(() {
      _userPosition = position;
      print(position.toString());
    });

    if (init) {
      init = false;
    }
  }

  @override
  void dispose() {
    _motionSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: !_isAvailable
          ? const Center(
              child: Text(
                'Датчики движения недоступны',
                style: TextStyle(color: Colors.white),
              ),
            )
          : _motionData == null
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: Stack(
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // GeolocatorWidget(),
                      LinearCompass(finalYaw),
                      Expanded(
                        child: CombinedCompensator(finalPitch, finalRoll, mode),
                      ),

                      Text(
                        'Latitude    ${_userPosition?.latitude}\nLongitude ${_userPosition?.longitude}\n'
                        'Satellites: ${_getSatellitesCount(_userPosition)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
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
                ],
              ),
            ),
    );
  }

  String _getSatellitesCount(Position? position) {
    if (position == null) return 'N/A';
    // if (position is AndroidPosition) {
    //   return (position as AndroidPosition).satellitesUsed?.toString() ?? 'N/A';
    // }
    return 'N/A (Not available on this platform)';
  }
}
