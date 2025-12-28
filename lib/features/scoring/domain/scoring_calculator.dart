import 'dart:math' as math;
import 'package:lane_keeper/core/constants/app_constants.dart';
import 'package:lane_keeper/features/telemetry/domain/telemetry_data.dart';

class TripScoreResult {
  final double distanceKm;
  final double avgSpeedKmh;
  final double maxSpeedKmh;
  final int harshBrakes;
  final int harshAccels;
  final double speedVariance;
  final double lateralInstability; // 0-100 index (lower is better, but here we output raw variance maybe?)
  final double patienceIndex; // 0-1 fraction
  
  final double speedScore;
  final double brakingScore;
  final double accelScore;
  final double stabilityScore;
  final double patienceScore;
  
  final double finalScore;

  TripScoreResult({
    required this.distanceKm,
    required this.avgSpeedKmh,
    required this.maxSpeedKmh,
    required this.harshBrakes,
    required this.harshAccels,
    required this.speedVariance,
    required this.lateralInstability,
    required this.patienceIndex,
    required this.speedScore,
    required this.brakingScore,
    required this.accelScore,
    required this.stabilityScore,
    required this.patienceScore,
    required this.finalScore,
  });

  Map<String, dynamic> toMap() {
    return {
      'distanceKm': distanceKm,
      'avgSpeedKmh': avgSpeedKmh,
      'maxSpeedKmh': maxSpeedKmh,
      'harshBrakes': harshBrakes,
      'harshAccels': harshAccels,
      'speedVariance': speedVariance,
      'lateralInstability': lateralInstability,
      'patienceIndex': patienceIndex,
      'speedScore': speedScore,
      'brakingScore': brakingScore,
      'accelScore': accelScore,
      'stabilityScore': stabilityScore,
      'patienceScore': patienceScore,
      'finalScore': finalScore,
    };
  }
}

class ScoringCalculator {
  static TripScoreResult calculate(List<TelemetryPoint> points) {
    if (points.isEmpty) {
      return TripScoreResult(
        distanceKm: 0, avgSpeedKmh: 0, maxSpeedKmh: 0, harshBrakes: 0, harshAccels: 0,
        speedVariance: 0, lateralInstability: 0, patienceIndex: 0,
        speedScore: 100, brakingScore: 100, accelScore: 100, stabilityScore: 100, patienceScore: 100,
        finalScore: 100,
      );
    }

    // 1. Basic Metrics
    double totalSpeed = 0;
    double maxSpeed = 0;
    double totalDistanceKm = 0; // Estimation
    
    // We can assume points are roughly ordered by time.
    // Calculate distance by summing intervals between points (speed * time)
    // or using Lat/Long distance if accurate. For MPV, let's use speed * time integration 
    // as it's often smoother for "Trip distance" than noisy GPS jumps, 
    // but lat/long is better for "Map distance". Let's use basic Lat/Long sum.
    
    // Actually, simple sum of speed*duration is safer if GPS location jumps.
    // But let's stick to lat/long haversine for "real" distance if available, 
    // or just assume 1 sec between points if we don't have accurate delta.
    // TelemetryPoint has timestamp.
    
    // Let's iterate.
    
    List<double> speeds = [];
    List<double> latAccels = [];
    List<double> longAccels = []; // We need to derive this from GPS speed delta OR use raw accel Y/Z
    
    // Using GPS Speed Delta is more robust for "Vehicle Acceleration" than Phone accelerometer 
    // because phone orientation is unknown without calibration.
    // Let's use GPS Speed differentiation for Accel/Brake.
    
    int harshBrakes = 0;
    int harshAccels = 0;
    int below15Count = 0;
    int totalSamples = points.length;

    for (int i = 0; i < points.length; i++) {
        final p = points[i];
        speeds.add(p.speedKmh);
        totalSpeed += p.speedKmh;
        if (p.speedKmh > maxSpeed) maxSpeed = p.speedKmh;
        
        if (p.speedKmh < 15.0) below15Count++;
        
        if (i > 0) {
            final prev = points[i-1];
            final dt = p.timestamp.difference(prev.timestamp).inMilliseconds / 1000.0;
            
            if (dt > 0) {
                 // Distance (Avg speed * time)
                 double segDistKm = ((p.speedKmh + prev.speedKmh) / 2) * (dt / 3600.0);
                 totalDistanceKm += segDistKm;
                 
                 // Acceleration (m/s^2)
                 // deltaV (km/h) -> /3.6 -> m/s
                 double dv = (p.speedKmh - prev.speedKmh) / 3.6;
                 double accelMs2 = dv / dt;
                 
                 if (accelMs2 > AppConstants.harshAccelThreshold) harshAccels++;
                 if (accelMs2 < AppConstants.harshBrakeThreshold) harshBrakes++;
                 
                 longAccels.add(accelMs2);
            }
        }
        
        // Lateral Instability: Use Gyro Z (Yaw rate) or X/Y depending on phone mount?
        // Since we don't know mount: Magnitude of gyro variation is a good proxy for "swerving".
        // Or simply Gyro magnitude.
        double gyroMag = math.sqrt(p.gyroX*p.gyroX + p.gyroY*p.gyroY + p.gyroZ*p.gyroZ);
        latAccels.add(gyroMag); // Using gyro mag as proxy for lateral usage
    }

    double avgSpeed = totalSpeed / totalSamples;
    
    // Variance
    double sumSquaredDiffSpeed = 0;
    for (var s in speeds) {
      sumSquaredDiffSpeed += math.pow(s - avgSpeed, 2);
    }
    double speedVariance = sumSquaredDiffSpeed / totalSamples;
    
    double sumSquaredDiffGyro = 0;
    // Avg gyro should be near 0 for straight driving, but phone might be rotating.
    // Let's use Variance of Gyro Magnitude.
    double avgGyro = latAccels.reduce((a, b) => a + b) / latAccels.length;
    for (var g in latAccels) {
        sumSquaredDiffGyro += math.pow(g - avgGyro, 2);
    }
    double lateralInstability = sumSquaredDiffGyro / totalSamples;

    double patienceIndex = (below15Count / totalSamples); // Raw fraction

    // --- SCORING (0-100) ---
    
    // 1. Speed Discipline
    // Penalty for high variance (erratic speed)
    // Threshold: variance > 20 is bad?
    double speedPenalty = (speedVariance / 2.0).clamp(0, 40); 
    if (maxSpeed > 100) speedPenalty += 20; // Hard cap penalty
    double speedScore = (100 - speedPenalty).clamp(40, 100);

    // 2. Braking
    // > 1 harsh brake per km is bad.
    double brakesPerKm = totalDistanceKm > 0 ? (harshBrakes / totalDistanceKm) : 0;
    double brakingPenalty = (brakesPerKm * 15).clamp(0, 60);
    double brakingScore = (100 - brakingPenalty).clamp(40, 100);

    // 3. Accel
    double accelsPerKm = totalDistanceKm > 0 ? (harshAccels / totalDistanceKm) : 0;
    double accelPenalty = (accelsPerKm * 15).clamp(0, 60);
    double accelScore = (100 - accelPenalty).clamp(40, 100);

    // 4. Stability
    // heavy gyro variance -> phone moving or car swerving
    double stabilityPenalty = (lateralInstability * 100).clamp(0, 50);
    double stabilityScore = (100 - stabilityPenalty).clamp(40, 100);

    // 5. Patience
    // Reward for spending time at low speed without harsh accels? 
    // Simply map index to score. 100% patience = 100 score? 
    // Actually, patience score usually penalizes "rushing" in traffic. 
    // Let's just give high score if patienceIndex is reasonable or if NO harsh events.
    double patienceScore = 100;
    if (harshAccels > 0 && patienceIndex > 0.5) {
         // Impatient in traffic
         patienceScore = 60;
    }
    
    // Final Weighted Score
    double finalScore = (
        speedScore * AppConstants.weightSpeed +
        brakingScore * AppConstants.weightBraking +
        accelScore * AppConstants.weightAccel +
        stabilityScore * AppConstants.weightStability +
        patienceScore * AppConstants.weightPatience
    );

    return TripScoreResult(
      distanceKm: double.parse(totalDistanceKm.toStringAsFixed(2)),
      avgSpeedKmh: double.parse(avgSpeed.toStringAsFixed(1)),
      maxSpeedKmh: double.parse(maxSpeed.toStringAsFixed(1)),
      harshBrakes: harshBrakes,
      harshAccels: harshAccels,
      speedVariance: double.parse(speedVariance.toStringAsFixed(2)),
      lateralInstability: double.parse(lateralInstability.toStringAsFixed(4)),
      patienceIndex: double.parse(patienceIndex.toStringAsFixed(2)),
      speedScore: speedScore.roundToDouble(),
      brakingScore: brakingScore.roundToDouble(),
      accelScore: accelScore.roundToDouble(),
      stabilityScore: stabilityScore.roundToDouble(),
      patienceScore: patienceScore.roundToDouble(),
      finalScore: finalScore.roundToDouble(),
    );
  }
}
