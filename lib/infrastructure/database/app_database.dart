import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

/// Table for storing user login information
class UserLogins extends Table {
  TextColumn get id => text()();
  TextColumn get email => text()();
  TextColumn get userName => text()();
  TextColumn get fullName => text()();
  BoolColumn get isLoggedIn => boolean().withDefault(const Constant(false))();
  DateTimeColumn get lastLogin => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// App database using Drift
@DriftDatabase(tables: [UserLogins])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  // Cache for current user to reduce database queries
  UserLogin? _cachedCurrentUser;
  DateTime? _cacheTime;
  static const Duration _cacheExpiry = Duration(minutes: 5);

  /// Check if cache is valid
  bool get _isCacheValid {
    if (_cachedCurrentUser == null || _cacheTime == null) return false;
    return DateTime.now().difference(_cacheTime!) < _cacheExpiry;
  }

  /// Clear user cache
  void _clearCache() {
    _cachedCurrentUser = null;
    _cacheTime = null;
  }

  /// Get the currently logged in user (with caching)
  Future<UserLogin?> getCurrentUser() async {
    // Return cached value if valid
    if (_isCacheValid) {
      return _cachedCurrentUser;
    }

    // Query from database
    final user = await (select(userLogins)
          ..where((tbl) => tbl.isLoggedIn.equals(true))
          ..limit(1))
        .getSingleOrNull();

    // Update cache
    _cachedCurrentUser = user;
    _cacheTime = DateTime.now();

    return user;
  }

  /// Save or update user login information
  Future<void> saveUserLogin(UserLogin userLogin) async {
    await into(userLogins).insertOnConflictUpdate(userLogin);
    _clearCache(); // Invalidate cache
  }

  /// Set user as logged in
  Future<void> setUserLoggedIn(String userId) async {
    await (update(userLogins)..where((tbl) => tbl.id.equals(userId))).write(
      UserLoginsCompanion(isLoggedIn: const Value(true), lastLogin: Value(DateTime.now())),
    );
    _clearCache(); // Invalidate cache
  }

  /// Set all users as logged out
  Future<void> setAllUsersLoggedOut() async {
    await (update(userLogins)).write(const UserLoginsCompanion(isLoggedIn: Value(false)));
    _clearCache(); // Invalidate cache
  }

  /// Delete user login information
  Future<void> deleteUserLogin(String userId) async {
    await (delete(userLogins)..where((tbl) => tbl.id.equals(userId))).go();
    _clearCache(); // Invalidate cache
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    try {
      // Wait for path_provider to be ready
      final dbFolder = await getApplicationDocumentsDirectory();
      final file = File(p.join(dbFolder.path, 'app.db'));

      // Ensure parent directory exists
      if (!await file.parent.exists()) {
        await file.parent.create(recursive: true);
      }

      return NativeDatabase.createInBackground(file);
    } catch (e) {
      // If path_provider fails, try to use a fallback location
      try {
        // Try to get a fallback directory
        final tempDir = Directory.systemTemp;
        final fallbackPath = p.join(tempDir.path, 'vietravel_app');
        final fallbackDir = Directory(fallbackPath);

        if (!await fallbackDir.exists()) {
          await fallbackDir.create(recursive: true);
        }

        final file = File(p.join(fallbackPath, 'app.db'));
        return NativeDatabase(file);
      } catch (fallbackError) {
        // Last resort: use system temp directly
        final file = File(p.join(Directory.systemTemp.path, 'vietravel_app.db'));
        return NativeDatabase(file);
      }
    }
  });
}
