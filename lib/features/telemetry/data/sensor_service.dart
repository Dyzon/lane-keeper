import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final sensorServiceProvider = Provider((ref) => SensorService());

class SensorData {
  final UserAccelerometerEvent? accel;
  final GyroscopeEvent? gyro;

  SensorData({this.accel, this.gyro});
}

class SensorService {
  StreamSubscription<UserAccelerometerEvent>? _accelSubscription;
  StreamSubscription<GyroscopeEvent>? _gyroSubscription;

  // Standard streams from sensors_plus
  Stream<UserAccelerometerEvent> get accelStream => userAccelerometerEventStream();
  Stream<GyroscopeEvent> get gyroStream => gyroscopeEventStream();

  // Keep track of latest values for sync point creation
  UserAccelerometerEvent? _lastAccel;
  GyroscopeEvent? _lastGyro;

  UserAccelerometerEvent? get lastAccel => _lastAccel;
  GyroscopeEvent? get lastGyro => _lastGyro;

  void startTracking() {
    _accelSubscription = accelStream.listen((event) {
      _lastAccel = event;
    });

    _gyroSubscription = gyroStream.listen((event) {
      _lastGyro = event;
    });
    
    debugPrint("Sensor tracking started.");
  }

  void stopTracking() {
    _accelSubscription?.cancel();
    _gyroSubscription?.cancel();
    _accelSubscription = null;
    _gyroSubscription = null;
    _lastAccel = null;
    _lastGyro = null;
    debugPrint("Sensor tracking stopped.");
  }
}
