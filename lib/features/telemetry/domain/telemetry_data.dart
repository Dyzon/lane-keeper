class TelemetryPoint {
  final DateTime timestamp;
  final double speedKmh; // From GPS
  final double latitude;
  final double longitude;
  final double accelX;
  final double accelY;
  final double accelZ;
  final double gyroX;
  final double gyroY;
  final double gyroZ;

  TelemetryPoint({
    required this.timestamp,
    required this.speedKmh,
    required this.latitude,
    required this.longitude,
    required this.accelX,
    required this.accelY,
    required this.accelZ,
    required this.gyroX,
    required this.gyroY,
    required this.gyroZ,
  });
  
  // Computed magnitude of linear acceleration (excluding gravity typically handled by sensor fusion or raw)
  // For basic sensors_plus UserAccelerometer, gravity is excluded.
  double get accelMagnitude => (accelX * accelX + accelY * accelY + accelZ * accelZ);
}
