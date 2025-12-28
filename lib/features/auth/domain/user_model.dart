import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String? email;
  final String? displayName;
  final String? photoUrl;
  final String? city;
  final DateTime createdAt;
  final Map<String, dynamic> weeklyStats;

  UserModel({
    required this.uid,
    this.email,
    this.displayName,
    this.photoUrl,
    this.city,
    required this.createdAt,
    this.weeklyStats = const {},
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      email: map['email'],
      displayName: map['displayName'],
      photoUrl: map['photoUrl'],
      city: map['city'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      weeklyStats: map['weeklyStats'] ?? {},
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'city': city,
      'createdAt': Timestamp.fromDate(createdAt),
      'weeklyStats': weeklyStats,
    };
  }

  UserModel copyWith({
    String? city,
    Map<String, dynamic>? weeklyStats,
  }) {
    return UserModel(
      uid: uid,
      email: email,
      displayName: displayName,
      photoUrl: photoUrl,
      city: city ?? this.city,
      createdAt: createdAt,
      weeklyStats: weeklyStats ?? this.weeklyStats,
    );
  }
}
