import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lane_keeper/core/constants/app_constants.dart';
import 'package:lane_keeper/features/telemetry/data/location_service.dart';
import 'package:lane_keeper/features/telemetry/data/sensor_service.dart';
import 'package:lane_keeper/features/telemetry/domain/telemetry_data.dart';
import 'package:lane_keeper/features/scoring/data/scoring_repository.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';

// Provider for the UI to listen to
final telemetryManagerProvider = StateNotifierProvider<TelemetryManager, TelemetryState>((ref) {
  return TelemetryManager(
    ref.watch(locationServiceProvider),
    ref.watch(sensorServiceProvider),
    ref,
  );
});

enum TripStatus { idle, driving, processing }

class TelemetryState {
  final TripStatus status;
  final double currentSpeedKmh;
  final String? currentTripId;
  final int validSampleCount;

  TelemetryState({
    required this.status,
    required this.currentSpeedKmh,
    this.currentTripId,
    this.validSampleCount = 0,
  });

  factory TelemetryState.initial() => TelemetryState(
        status: TripStatus.idle,
        currentSpeedKmh: 0.0,
      );

  TelemetryState copyWith({
    TripStatus? status,
    double? currentSpeedKmh,
    String? currentTripId,
    int? validSampleCount,
  }) {
    return TelemetryState(
      status: status ?? this.status,
      currentSpeedKmh: currentSpeedKmh ?? this.currentSpeedKmh,
      currentTripId: currentTripId ?? this.currentTripId,
      validSampleCount: validSampleCount ?? this.validSampleCount,
    );
  }
}

class TelemetryManager extends StateNotifier<TelemetryState> {
  final LocationService _locationService;
  final SensorService _sensorService;
  final Ref _ref;

  StreamSubscription<Position>? _positionSub;
  
  // Trip Detection Logic State
  int _consecutiveSpeedOverThreshold = 0;
  int _consecutiveSpeedUnknown = 0; // For stop detection
  DateTime? _tripStartTime;
  
  // Data Buffer for current trip
  final List<TelemetryPoint> _tripPoints = [];

  TelemetryManager(this._locationService, this._sensorService, this._ref)
      : super(TelemetryState.initial());

  Future<void> initialize() async {
    final hasPermission = await _locationService.requestPermission();
    if (!hasPermission) {
      debugPrint("Location permission denied.");
      return;
    }
    
    // Always listen to location for start detection
    _startMonitoring();
  }

  void _startMonitoring() {
    _locationService.startTracking();
    _sensorService.startTracking();

    _positionSub = _locationService.positionStream.listen(_handleLocationUpdate);
  }

  void _handleLocationUpdate(Position position) {
    // Convert m/s to km/h
    final speedKmh = position.speed * 3.6;
    
    // Update basic UI state
    state = state.copyWith(currentSpeedKmh: speedKmh);

    if (state.status == TripStatus.idle) {
      _checkStartConditions(speedKmh);
    } else if (state.status == TripStatus.driving) {
      _collectData(position, speedKmh);
      _checkStopConditions(speedKmh);
    }
  }

  void _checkStartConditions(double speedKmh) {
    if (speedKmh > AppConstants.minTripSpeedKmh) {
       _consecutiveSpeedOverThreshold++;
       
       if (_consecutiveSpeedOverThreshold >= 3) {
         _startTrip();
       }
    } else {
      _consecutiveSpeedOverThreshold = 0;
    }
  }
  
  void _startTrip() {
    debugPrint("Trip Started!");
    final tripId = const Uuid().v4();
    _tripStartTime = DateTime.now();
    _tripPoints.clear();
    
    state = state.copyWith(
      status: TripStatus.driving,
      currentTripId: tripId,
      validSampleCount: 0,
    );
  }

  void _checkStopConditions(double speedKmh) {
    if (speedKmh < AppConstants.stopTripSpeedKmh) {
       _consecutiveSpeedUnknown++;
       if (_consecutiveSpeedUnknown >= 10) {
         _stopTrip();
       }
    } else {
      _consecutiveSpeedUnknown = 0;
    }
  }
  
  void _collectData(Position pos, double speedKmh) {
    // Fuse with latest sensor data
    final lastAccel = _sensorService.lastAccel;
    final lastGyro = _sensorService.lastGyro;
    
    final point = TelemetryPoint(
      timestamp: DateTime.now(),
      speedKmh: speedKmh,
      latitude: pos.latitude,
      longitude: pos.longitude,
      accelX: lastAccel?.x ?? 0,
      accelY: lastAccel?.y ?? 0,
      accelZ: lastAccel?.z ?? 0,
      gyroX: lastGyro?.x ?? 0,
      gyroY: lastGyro?.y ?? 0,
      gyroZ: lastGyro?.z ?? 0,
    );
    
    _tripPoints.add(point);
    
    state = state.copyWith(validSampleCount: _tripPoints.length);
  }

  Future<void> _stopTrip() async {
    debugPrint("Trip Stopped. Processing...");
    state = state.copyWith(status: TripStatus.processing);
    
    try {
      if (_tripPoints.isNotEmpty) {
        await _ref.read(scoringRepositoryProvider).processAndSaveTrip(
          tripId: state.currentTripId!,
          startTime: _tripStartTime!,
          endTime: DateTime.now(),
          points: List.from(_tripPoints),
        );
      }
    } catch (e) {
      debugPrint("Error processing trip: $e");
    }

    state = state.copyWith(
      status: TripStatus.idle,
      currentTripId: null,
      validSampleCount: 0,
    );
     _tripPoints.clear();
     _consecutiveSpeedOverThreshold = 0;
     _consecutiveSpeedUnknown = 0;
  }
  
  // Manual trigger for testing
  void forceStartTrip() {
    if (state.status == TripStatus.idle) _startTrip();
  }
  
  void forceStopTrip() {
    if (state.status == TripStatus.driving) _stopTrip();
  }
  
  @override
  void dispose() {
    _positionSub?.cancel();
    _locationService.stopTracking();
    _sensorService.stopTracking();
    super.dispose();
  }
}
