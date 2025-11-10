import 'package:dartz/dartz.dart';
import '../entities/user.dart';

/// Failure types for authentication operations
abstract class AuthFailure {
  const AuthFailure();
}

class EmailAlreadyInUseFailure extends AuthFailure {
  const EmailAlreadyInUseFailure();
}

class WeakPasswordFailure extends AuthFailure {
  const WeakPasswordFailure();
}

class InvalidEmailFailure extends AuthFailure {
  const InvalidEmailFailure();
}

class NetworkFailure extends AuthFailure {
  const NetworkFailure();
}

class UnknownFailure extends AuthFailure {
  const UnknownFailure(this.message);
  final String message;
}

/// Authentication repository interface
abstract class AuthRepository {
  /// Register a new user with email and password, then store user data in Firestore
  Future<Either<AuthFailure, User>> registerUser({
    required String email,
    required String password,
    required String userName,
    required String fullName,
    required String address,
    required String avatar,
    required String birthday,
  });

  /// Sign in with email and password
  Future<Either<AuthFailure, User>> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  /// Sign out current user
  Future<Either<AuthFailure, Unit>> signOut();

  /// Get current user
  Future<Option<User>> getCurrentUser();

  /// Check if user is authenticated
  Future<bool> isAuthenticated();

  /// Update FCM token for current user
  Future<Either<AuthFailure, Unit>> updateFcmToken(String fcmToken);

  /// Get user by ID
  Future<Either<AuthFailure, User>> getUserById(String userId);
}
