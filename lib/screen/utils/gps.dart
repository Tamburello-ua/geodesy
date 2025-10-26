import 'dart:async';

import 'package:geolocator/geolocator.dart';

typedef PositionCallback = Function(Position position);

class GPS {
  late StreamSubscription<Position> _positionStream;
  bool isAccessGranted(LocationPermission permission) {
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  Future<bool> requestPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (isAccessGranted(permission)) {
      return true;
    }
    permission = await Geolocator.requestPermission();
    return isAccessGranted(permission);
  }

  Future<void> startPositionStream(PositionCallback callback) async {
    bool permissionGranted = await requestPermission();
    if (!permissionGranted) {
      throw Exception("Permission Denied");
    }
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
      ),
    ).listen(callback);
  }

  Future<void> stopPositionStream() async {
    await _positionStream.cancel();
  }

  Future<Position> getCurrentPosition() async {
    bool permissionGranted = await requestPermission();
    if (!permissionGranted) {
      throw Exception("Permission Denied");
    }
    return await Geolocator.getCurrentPosition();
  }
}
