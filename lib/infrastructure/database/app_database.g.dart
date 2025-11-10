// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $UserLoginsTable extends UserLogins
    with TableInfo<$UserLoginsTable, UserLogin> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserLoginsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
      'email', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userNameMeta =
      const VerificationMeta('userName');
  @override
  late final GeneratedColumn<String> userName = GeneratedColumn<String>(
      'user_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _fullNameMeta =
      const VerificationMeta('fullName');
  @override
  late final GeneratedColumn<String> fullName = GeneratedColumn<String>(
      'full_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _isLoggedInMeta =
      const VerificationMeta('isLoggedIn');
  @override
  late final GeneratedColumn<bool> isLoggedIn = GeneratedColumn<bool>(
      'is_logged_in', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_logged_in" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _lastLoginMeta =
      const VerificationMeta('lastLogin');
  @override
  late final GeneratedColumn<DateTime> lastLogin = GeneratedColumn<DateTime>(
      'last_login', aliasedName, true,
      type: DriftSqlType.dateTime, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns =>
      [id, email, userName, fullName, isLoggedIn, lastLogin];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_logins';
  @override
  VerificationContext validateIntegrity(Insertable<UserLogin> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('email')) {
      context.handle(
          _emailMeta, email.isAcceptableOrUnknown(data['email']!, _emailMeta));
    } else if (isInserting) {
      context.missing(_emailMeta);
    }
    if (data.containsKey('user_name')) {
      context.handle(_userNameMeta,
          userName.isAcceptableOrUnknown(data['user_name']!, _userNameMeta));
    } else if (isInserting) {
      context.missing(_userNameMeta);
    }
    if (data.containsKey('full_name')) {
      context.handle(_fullNameMeta,
          fullName.isAcceptableOrUnknown(data['full_name']!, _fullNameMeta));
    } else if (isInserting) {
      context.missing(_fullNameMeta);
    }
    if (data.containsKey('is_logged_in')) {
      context.handle(
          _isLoggedInMeta,
          isLoggedIn.isAcceptableOrUnknown(
              data['is_logged_in']!, _isLoggedInMeta));
    }
    if (data.containsKey('last_login')) {
      context.handle(_lastLoginMeta,
          lastLogin.isAcceptableOrUnknown(data['last_login']!, _lastLoginMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UserLogin map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserLogin(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      email: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}email'])!,
      userName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_name'])!,
      fullName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}full_name'])!,
      isLoggedIn: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_logged_in'])!,
      lastLogin: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}last_login']),
    );
  }

  @override
  $UserLoginsTable createAlias(String alias) {
    return $UserLoginsTable(attachedDatabase, alias);
  }
}

class UserLogin extends DataClass implements Insertable<UserLogin> {
  final String id;
  final String email;
  final String userName;
  final String fullName;
  final bool isLoggedIn;
  final DateTime? lastLogin;
  const UserLogin(
      {required this.id,
      required this.email,
      required this.userName,
      required this.fullName,
      required this.isLoggedIn,
      this.lastLogin});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['email'] = Variable<String>(email);
    map['user_name'] = Variable<String>(userName);
    map['full_name'] = Variable<String>(fullName);
    map['is_logged_in'] = Variable<bool>(isLoggedIn);
    if (!nullToAbsent || lastLogin != null) {
      map['last_login'] = Variable<DateTime>(lastLogin);
    }
    return map;
  }

  UserLoginsCompanion toCompanion(bool nullToAbsent) {
    return UserLoginsCompanion(
      id: Value(id),
      email: Value(email),
      userName: Value(userName),
      fullName: Value(fullName),
      isLoggedIn: Value(isLoggedIn),
      lastLogin: lastLogin == null && nullToAbsent
          ? const Value.absent()
          : Value(lastLogin),
    );
  }

  factory UserLogin.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserLogin(
      id: serializer.fromJson<String>(json['id']),
      email: serializer.fromJson<String>(json['email']),
      userName: serializer.fromJson<String>(json['userName']),
      fullName: serializer.fromJson<String>(json['fullName']),
      isLoggedIn: serializer.fromJson<bool>(json['isLoggedIn']),
      lastLogin: serializer.fromJson<DateTime?>(json['lastLogin']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'email': serializer.toJson<String>(email),
      'userName': serializer.toJson<String>(userName),
      'fullName': serializer.toJson<String>(fullName),
      'isLoggedIn': serializer.toJson<bool>(isLoggedIn),
      'lastLogin': serializer.toJson<DateTime?>(lastLogin),
    };
  }

  UserLogin copyWith(
          {String? id,
          String? email,
          String? userName,
          String? fullName,
          bool? isLoggedIn,
          Value<DateTime?> lastLogin = const Value.absent()}) =>
      UserLogin(
        id: id ?? this.id,
        email: email ?? this.email,
        userName: userName ?? this.userName,
        fullName: fullName ?? this.fullName,
        isLoggedIn: isLoggedIn ?? this.isLoggedIn,
        lastLogin: lastLogin.present ? lastLogin.value : this.lastLogin,
      );
  UserLogin copyWithCompanion(UserLoginsCompanion data) {
    return UserLogin(
      id: data.id.present ? data.id.value : this.id,
      email: data.email.present ? data.email.value : this.email,
      userName: data.userName.present ? data.userName.value : this.userName,
      fullName: data.fullName.present ? data.fullName.value : this.fullName,
      isLoggedIn:
          data.isLoggedIn.present ? data.isLoggedIn.value : this.isLoggedIn,
      lastLogin: data.lastLogin.present ? data.lastLogin.value : this.lastLogin,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserLogin(')
          ..write('id: $id, ')
          ..write('email: $email, ')
          ..write('userName: $userName, ')
          ..write('fullName: $fullName, ')
          ..write('isLoggedIn: $isLoggedIn, ')
          ..write('lastLogin: $lastLogin')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, email, userName, fullName, isLoggedIn, lastLogin);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserLogin &&
          other.id == this.id &&
          other.email == this.email &&
          other.userName == this.userName &&
          other.fullName == this.fullName &&
          other.isLoggedIn == this.isLoggedIn &&
          other.lastLogin == this.lastLogin);
}

class UserLoginsCompanion extends UpdateCompanion<UserLogin> {
  final Value<String> id;
  final Value<String> email;
  final Value<String> userName;
  final Value<String> fullName;
  final Value<bool> isLoggedIn;
  final Value<DateTime?> lastLogin;
  final Value<int> rowid;
  const UserLoginsCompanion({
    this.id = const Value.absent(),
    this.email = const Value.absent(),
    this.userName = const Value.absent(),
    this.fullName = const Value.absent(),
    this.isLoggedIn = const Value.absent(),
    this.lastLogin = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UserLoginsCompanion.insert({
    required String id,
    required String email,
    required String userName,
    required String fullName,
    this.isLoggedIn = const Value.absent(),
    this.lastLogin = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        email = Value(email),
        userName = Value(userName),
        fullName = Value(fullName);
  static Insertable<UserLogin> custom({
    Expression<String>? id,
    Expression<String>? email,
    Expression<String>? userName,
    Expression<String>? fullName,
    Expression<bool>? isLoggedIn,
    Expression<DateTime>? lastLogin,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (email != null) 'email': email,
      if (userName != null) 'user_name': userName,
      if (fullName != null) 'full_name': fullName,
      if (isLoggedIn != null) 'is_logged_in': isLoggedIn,
      if (lastLogin != null) 'last_login': lastLogin,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UserLoginsCompanion copyWith(
      {Value<String>? id,
      Value<String>? email,
      Value<String>? userName,
      Value<String>? fullName,
      Value<bool>? isLoggedIn,
      Value<DateTime?>? lastLogin,
      Value<int>? rowid}) {
    return UserLoginsCompanion(
      id: id ?? this.id,
      email: email ?? this.email,
      userName: userName ?? this.userName,
      fullName: fullName ?? this.fullName,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      lastLogin: lastLogin ?? this.lastLogin,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (userName.present) {
      map['user_name'] = Variable<String>(userName.value);
    }
    if (fullName.present) {
      map['full_name'] = Variable<String>(fullName.value);
    }
    if (isLoggedIn.present) {
      map['is_logged_in'] = Variable<bool>(isLoggedIn.value);
    }
    if (lastLogin.present) {
      map['last_login'] = Variable<DateTime>(lastLogin.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserLoginsCompanion(')
          ..write('id: $id, ')
          ..write('email: $email, ')
          ..write('userName: $userName, ')
          ..write('fullName: $fullName, ')
          ..write('isLoggedIn: $isLoggedIn, ')
          ..write('lastLogin: $lastLogin, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $UserLoginsTable userLogins = $UserLoginsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [userLogins];
}

typedef $$UserLoginsTableCreateCompanionBuilder = UserLoginsCompanion Function({
  required String id,
  required String email,
  required String userName,
  required String fullName,
  Value<bool> isLoggedIn,
  Value<DateTime?> lastLogin,
  Value<int> rowid,
});
typedef $$UserLoginsTableUpdateCompanionBuilder = UserLoginsCompanion Function({
  Value<String> id,
  Value<String> email,
  Value<String> userName,
  Value<String> fullName,
  Value<bool> isLoggedIn,
  Value<DateTime?> lastLogin,
  Value<int> rowid,
});

class $$UserLoginsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $UserLoginsTable,
    UserLogin,
    $$UserLoginsTableFilterComposer,
    $$UserLoginsTableOrderingComposer,
    $$UserLoginsTableCreateCompanionBuilder,
    $$UserLoginsTableUpdateCompanionBuilder> {
  $$UserLoginsTableTableManager(_$AppDatabase db, $UserLoginsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer:
              $$UserLoginsTableFilterComposer(ComposerState(db, table)),
          orderingComposer:
              $$UserLoginsTableOrderingComposer(ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> email = const Value.absent(),
            Value<String> userName = const Value.absent(),
            Value<String> fullName = const Value.absent(),
            Value<bool> isLoggedIn = const Value.absent(),
            Value<DateTime?> lastLogin = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              UserLoginsCompanion(
            id: id,
            email: email,
            userName: userName,
            fullName: fullName,
            isLoggedIn: isLoggedIn,
            lastLogin: lastLogin,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String email,
            required String userName,
            required String fullName,
            Value<bool> isLoggedIn = const Value.absent(),
            Value<DateTime?> lastLogin = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              UserLoginsCompanion.insert(
            id: id,
            email: email,
            userName: userName,
            fullName: fullName,
            isLoggedIn: isLoggedIn,
            lastLogin: lastLogin,
            rowid: rowid,
          ),
        ));
}

class $$UserLoginsTableFilterComposer
    extends FilterComposer<_$AppDatabase, $UserLoginsTable> {
  $$UserLoginsTableFilterComposer(super.$state);
  ColumnFilters<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get email => $state.composableBuilder(
      column: $state.table.email,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get userName => $state.composableBuilder(
      column: $state.table.userName,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<String> get fullName => $state.composableBuilder(
      column: $state.table.fullName,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<bool> get isLoggedIn => $state.composableBuilder(
      column: $state.table.isLoggedIn,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get lastLogin => $state.composableBuilder(
      column: $state.table.lastLogin,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$UserLoginsTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $UserLoginsTable> {
  $$UserLoginsTableOrderingComposer(super.$state);
  ColumnOrderings<String> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get email => $state.composableBuilder(
      column: $state.table.email,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get userName => $state.composableBuilder(
      column: $state.table.userName,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get fullName => $state.composableBuilder(
      column: $state.table.fullName,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<bool> get isLoggedIn => $state.composableBuilder(
      column: $state.table.isLoggedIn,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get lastLogin => $state.composableBuilder(
      column: $state.table.lastLogin,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$UserLoginsTableTableManager get userLogins =>
      $$UserLoginsTableTableManager(_db, _db.userLogins);
}
