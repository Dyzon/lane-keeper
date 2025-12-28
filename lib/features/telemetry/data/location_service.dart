import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final locationServiceProvider = Provider((ref) => LocationService());

class LocationService {
  StreamSubscription<Position>? _positionStreamSubscription;
  final _positionController = StreamController<Position>.broadcast();

  Stream<Position> get positionStream => _positionController.stream;

  Future<bool> requestPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  void startTracking() {
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 0, // Updates even when stationary for speed filtering
    );

    _positionStreamSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings)
            .listen((Position position) {
      _positionController.add(position);
    });
    debugPrint("Location tracking started.");
  }

  void stopTracking() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
    debugPrint("Location tracking stopped.");
  }

  // Simulation method for testing without a real drive
  void simulateDrive() async {
    // Simulate a short drive: Accelerate -> Cruise -> Brake -> Stop
    debugPrint("Starting Simulated Drive...");
    
    // 1. Accelerate to 30km/h over 10s
    for (int i = 0; i <= 10; i++) {
        double speed = (i / 10) * 30.0; // km/h
        _emitMockPosition(speed);
        await Future.delayed(const Duration(seconds: 1));
    }
    
    // 2. Cruise at 30km/h for 10s
    for (int i = 0; i < 10; i++) {
         _emitMockPosition(30.0);
         await Future.delayed(const Duration(seconds: 1));
    }

    // 3. Harsh Brake to 0km/h over 2s
     for (int i = 0; i < 2; i++) {
         _emitMockPosition(10.0); // Quick drop
         await Future.delayed(const Duration(seconds: 1));
    }
     _emitMockPosition(0.0);
     debugPrint("Simulated Drive complete.");
  }

  void _emitMockPosition(double speedKmh) {
    // Speed in m/s for Position object
    double speedMs = speedKmh / 3.6;
    final mockPos = Position(
      longitude: 72.8777,
      latitude: 19.0760,
      timestamp: DateTime.now(),
      accuracy: 10,
      altitude: 0,
      heading: 0,
      speed: speedMs, // Only speed matters for now
      speedAccuracy: 1, 
      altitudeAccuracy: 1, 
      headingAccuracy: 1,
    );
     _positionController.add(mockPos);
  }
}
