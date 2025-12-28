import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lane_keeper/features/scoring/domain/scoring_calculator.dart';
import 'package:lane_keeper/features/telemetry/domain/telemetry_data.dart';

final scoringRepositoryProvider = Provider((ref) => ScoringRepository());

class ScoringRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> processAndSaveTrip({
    required String tripId,
    required DateTime startTime,
    required DateTime endTime,
    required List<TelemetryPoint> points,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      debugPrint("Cannot save trip: No user logged in.");
      return;
    }

    // 1. Calculate Scores
    final scoreResult = ScoringCalculator.calculate(points);
    
    debugPrint("Trip Score Calculated: ${scoreResult.finalScore}");

    // 2. Create Trip Document
    final tripData = {
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'metrics': scoreResult.toMap(),
      'finalScore': scoreResult.finalScore,
      'createdAt': FieldValue.serverTimestamp(),
    };
    
    // 3. Save to subcollection
    final userRef = _firestore.collection('users').doc(user.uid);
    await userRef.collection('trips').doc(tripId).set(tripData);

    // 4. Update Weekly Aggregates
    await _updateWeeklyStats(user.uid, scoreResult);
  }

  Future<void> _updateWeeklyStats(String uid, TripScoreResult newTrip) async {
    final userRef = _firestore.collection('users').doc(uid);
    
    return _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(userRef);
      if (!snapshot.exists) return;
      
      final data = snapshot.data()!;
      Map<String, dynamic> stats = Map<String, dynamic>.from(data['weeklyStats'] ?? {});
      
      double currentTotalDist = (stats['totalDistance'] ?? 0.0).toDouble();
      int tripCount = (stats['tripCount'] ?? 0);
      
      currentTotalDist += newTrip.distanceKm;
      
      double currentAvgScore = (stats['weeklyScore'] ?? 0.0).toDouble();
      double newAvgScore = ((currentAvgScore * tripCount) + newTrip.finalScore) / (tripCount + 1);
      
      stats['weeklyScore'] = newAvgScore;
      stats['totalDistance'] = currentTotalDist;
      stats['tripCount'] = tripCount + 1;
      stats['lastUpdated'] = FieldValue.serverTimestamp();
      
      transaction.update(userRef, {'weeklyStats': stats});
    });
  }
}
