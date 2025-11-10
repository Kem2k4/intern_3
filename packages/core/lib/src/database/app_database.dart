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

  /// Get the currently logged in user
  Future<UserLogin?> getCurrentUser() {
    return (select(userLogins)
          ..where((tbl) => tbl.isLoggedIn.equals(true))
          ..limit(1))
        .getSingleOrNull();
  }

  /// Save or update user login information
  Future<void> saveUserLogin(UserLogin userLogin) async {
    await into(userLogins).insertOnConflictUpdate(userLogin);
  }

  /// Set user as logged in
  Future<void> setUserLoggedIn(String userId) async {
    await (update(userLogins)..where((tbl) => tbl.id.equals(userId))).write(
      UserLoginsCompanion(isLoggedIn: const Value(true), lastLogin: Value(DateTime.now())),
    );
  }

  /// Set all users as logged out
  Future<void> setAllUsersLoggedOut() async {
    await (update(userLogins)).write(const UserLoginsCompanion(isLoggedIn: Value(false)));
  }

  /// Delete user login information
  Future<void> deleteUserLogin(String userId) async {
    await (delete(userLogins)..where((tbl) => tbl.id.equals(userId))).go();
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
