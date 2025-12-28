import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:lane_keeper/features/auth/domain/user_model.dart';
import 'package:flutter/foundation.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    FirebaseAuth.instance,
    GoogleSignIn(),
    FirebaseFirestore.instance,
  );
});

final authStateChangesProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

final currentUserProvider = StreamProvider<UserModel?>((ref) async* {
  final authUser = await ref.watch(authStateChangesProvider.future);
  if (authUser == null) {
    yield null;
  } else {
    yield* ref.read(authRepositoryProvider).getUserStream(authUser.uid);
  }
});

class AuthRepository {
  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;
  final FirebaseFirestore _firestore;

  AuthRepository(this._auth, this._googleSignIn, this._firestore);

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // Canceled by user

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      await _checkAndCreateUser(userCredential.user);
      return userCredential;
    } catch (e) {
      debugPrint("Google Sign In Error: $e");
      rethrow;
    }
  }

  Future<void> _checkAndCreateUser(User? user) async {
    if (user == null) return;
    
    final userRef = _firestore.collection('users').doc(user.uid);
    final docSnapshot = await userRef.get();

    if (!docSnapshot.exists) {
      final newUser = UserModel(
        uid: user.uid,
        email: user.email,
        displayName: user.displayName,
        photoUrl: user.photoURL,
        createdAt: DateTime.now(),
      );
      await userRef.set(newUser.toMap());
    }
  }

  Future<void> updateUserCity(String uid, String city) async {
    await _firestore.collection('users').doc(uid).update({'city': city});
  }

  Stream<UserModel> getUserStream(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((doc) {
      if (!doc.exists) {
         throw Exception("User not found");
      }
      return UserModel.fromMap(doc.data()!, doc.id);
    });
  }
  
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
