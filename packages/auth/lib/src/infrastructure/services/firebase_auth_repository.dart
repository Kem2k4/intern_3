import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../../domain/entities/user.dart' as domain_user;
import '../../domain/repositories/auth_repository.dart';

/// Firebase implementation of AuthRepository
class FirebaseAuthRepository implements AuthRepository {
  final firebase_auth.FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  FirebaseAuthRepository({firebase_auth.FirebaseAuth? firebaseAuth, FirebaseFirestore? firestore})
    : _firebaseAuth = firebaseAuth ?? firebase_auth.FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<Either<AuthFailure, domain_user.User>> registerUser({
    required String email,
    required String password,
    required String userName,
    required String fullName,
    required String address,
    required String avatar,
    required String birthday,
  }) async {
    try {
      // Create user with Firebase Auth
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        return const Left(UnknownFailure('User creation failed'));
      }

      // Create user data for Firestore
      final user = domain_user.User(
        id: firebaseUser.uid,
        userName: userName,
        fullName: fullName,
        password: password, // Note: Storing password in Firestore is not recommended
        address: address,
        avatar: avatar,
        birthday: birthday,
      );

      // Store user data in Firestore
      await _firestore.collection('users').doc(firebaseUser.uid).set(user.toJson());

      return Right(user);
    } on firebase_auth.FirebaseAuthException catch (e) {
      return Left(_mapFirebaseAuthExceptionToFailure(e));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<AuthFailure, domain_user.User>> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        return const Left(UnknownFailure('Sign in failed'));
      }

      // Get user data from Firestore
      final userDoc = await _firestore.collection('users').doc(firebaseUser.uid).get();
      if (!userDoc.exists) {
        return const Left(UnknownFailure('User data not found'));
      }

      final user = domain_user.User.fromJson(userDoc.data()!, firebaseUser.uid);
      return Right(user);
    } on firebase_auth.FirebaseAuthException catch (e) {
      return Left(_mapFirebaseAuthExceptionToFailure(e));
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<AuthFailure, Unit>> signOut() async {
    try {
      await _firebaseAuth.signOut();
      return const Right(unit);
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Option<domain_user.User>> getCurrentUser() async {
    try {
      final firebaseUser = _firebaseAuth.currentUser;
      if (firebaseUser == null) {
        return const None();
      }

      final userDoc = await _firestore.collection('users').doc(firebaseUser.uid).get();
      if (!userDoc.exists) {
        return const None();
      }

      final user = domain_user.User.fromJson(userDoc.data()!, firebaseUser.uid);
      return Some(user);
    } catch (e) {
      return const None();
    }
  }

  @override
  Future<bool> isAuthenticated() async {
    return _firebaseAuth.currentUser != null;
  }

  @override
  Future<Either<AuthFailure, Unit>> updateFcmToken(String fcmToken) async {
    try {
      final firebaseUser = _firebaseAuth.currentUser;
      if (firebaseUser == null) {
        return const Left(UnknownFailure('No authenticated user'));
      }

      // Update FCM token in Firestore
      await _firestore.collection('users').doc(firebaseUser.uid).update({
        'fcmToken': fcmToken,
      });

      return const Right(unit);
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<AuthFailure, domain_user.User>> getUserById(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        return const Left(UnknownFailure('User not found'));
      }

      final user = domain_user.User.fromJson(userDoc.data()!, userId);
      return Right(user);
    } catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  AuthFailure _mapFirebaseAuthExceptionToFailure(firebase_auth.FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return const EmailAlreadyInUseFailure();
      case 'weak-password':
        return const WeakPasswordFailure();
      case 'invalid-email':
        return const InvalidEmailFailure();
      case 'network-request-failed':
        return const NetworkFailure();
      default:
        return UnknownFailure(e.message ?? 'Unknown error');
    }
  }
}
