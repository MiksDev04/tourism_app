// GENERATED CODE DO NOT EDIT
part of '../brick.g.dart';

Future<Profile> _$ProfileFromSupabase(
  Map<String, dynamic> data, {
  required SupabaseProvider provider,
  OfflineFirstWithSupabaseRepository? repository,
}) async {
  return Profile(
    id: data['id'] as String,
    fullName: data['full_name'] as String,
    phone: data['phone'] as String,
    email: data['email'] as String,
    role: Role.values.byName(data['role']),
    createdAt: data['created_at'] as String?,
    updatedAt: data['updated_at'] as String?,
  );
}

Future<Map<String, dynamic>> _$ProfileToSupabase(
  Profile instance, {
  required SupabaseProvider provider,
  OfflineFirstWithSupabaseRepository? repository,
}) async {
  return {
    'id': instance.id,
    'full_name': instance.fullName,
    'phone': instance.phone,
    'email': instance.email,
    'role': instance.role.name,
    'created_at': instance.createdAt,
    'updated_at': instance.updatedAt,
  };
}

Future<Profile> _$ProfileFromSqlite(
  Map<String, dynamic> data, {
  required SqliteProvider provider,
  OfflineFirstWithSupabaseRepository? repository,
}) async {
  return Profile(
    id: data['id'] as String,
    fullName: data['full_name'] as String,
    phone: data['phone'] as String,
    email: data['email'] as String,
    role: Role.values[data['role'] as int],
    createdAt: data['created_at'] as String,
    updatedAt: data['updated_at'] as String,
  )..primaryKey = data['_brick_id'] as int;
}

Future<Map<String, dynamic>> _$ProfileToSqlite(
  Profile instance, {
  required SqliteProvider provider,
  OfflineFirstWithSupabaseRepository? repository,
}) async {
  return {
    'id': instance.id,
    'full_name': instance.fullName,
    'phone': instance.phone,
    'email': instance.email,
    'role': Role.values.indexOf(instance.role),
    'created_at': instance.createdAt,
    'updated_at': instance.updatedAt,
  };
}

/// Construct a [Profile]
class ProfileAdapter extends OfflineFirstWithSupabaseAdapter<Profile> {
  ProfileAdapter();

  @override
  final supabaseTableName = 'profiles';
  @override
  final defaultToNull = true;
  @override
  final fieldsToSupabaseColumns = {
    'id': const RuntimeSupabaseColumnDefinition(
      association: false,
      columnName: 'id',
    ),
    'fullName': const RuntimeSupabaseColumnDefinition(
      association: false,
      columnName: 'full_name',
    ),
    'phone': const RuntimeSupabaseColumnDefinition(
      association: false,
      columnName: 'phone',
    ),
    'email': const RuntimeSupabaseColumnDefinition(
      association: false,
      columnName: 'email',
    ),
    'role': const RuntimeSupabaseColumnDefinition(
      association: false,
      columnName: 'role',
    ),
    'createdAt': const RuntimeSupabaseColumnDefinition(
      association: false,
      columnName: 'created_at',
    ),
    'updatedAt': const RuntimeSupabaseColumnDefinition(
      association: false,
      columnName: 'updated_at',
    ),
  };
  @override
  final ignoreDuplicates = false;
  @override
  final uniqueFields = {'id'};
  @override
  final Map<String, RuntimeSqliteColumnDefinition> fieldsToSqliteColumns = {
    'primaryKey': const RuntimeSqliteColumnDefinition(
      association: false,
      columnName: '_brick_id',
      iterable: false,
      type: int,
    ),
    'id': const RuntimeSqliteColumnDefinition(
      association: false,
      columnName: 'id',
      iterable: false,
      type: String,
    ),
    'fullName': const RuntimeSqliteColumnDefinition(
      association: false,
      columnName: 'full_name',
      iterable: false,
      type: String,
    ),
    'phone': const RuntimeSqliteColumnDefinition(
      association: false,
      columnName: 'phone',
      iterable: false,
      type: String,
    ),
    'email': const RuntimeSqliteColumnDefinition(
      association: false,
      columnName: 'email',
      iterable: false,
      type: String,
    ),
    'role': const RuntimeSqliteColumnDefinition(
      association: false,
      columnName: 'role',
      iterable: false,
      type: Role,
    ),
    'createdAt': const RuntimeSqliteColumnDefinition(
      association: false,
      columnName: 'created_at',
      iterable: false,
      type: String,
    ),
    'updatedAt': const RuntimeSqliteColumnDefinition(
      association: false,
      columnName: 'updated_at',
      iterable: false,
      type: String,
    ),
  };
  @override
  Future<int?> primaryKeyByUniqueColumns(
    Profile instance,
    DatabaseExecutor executor,
  ) async {
    final results = await executor.rawQuery(
      '''
        SELECT * FROM `Profile` WHERE id = ? LIMIT 1''',
      [instance.id],
    );

    // SQFlite returns [{}] when no results are found
    if (results.isEmpty || (results.length == 1 && results.first.isEmpty)) {
      return null;
    }

    return results.first['_brick_id'] as int;
  }

  @override
  final String tableName = 'Profile';

  @override
  Future<Profile> fromSupabase(
    Map<String, dynamic> input, {
    required provider,
    covariant OfflineFirstWithSupabaseRepository? repository,
  }) async => await _$ProfileFromSupabase(
    input,
    provider: provider,
    repository: repository,
  );
  @override
  Future<Map<String, dynamic>> toSupabase(
    Profile input, {
    required provider,
    covariant OfflineFirstWithSupabaseRepository? repository,
  }) async => await _$ProfileToSupabase(
    input,
    provider: provider,
    repository: repository,
  );
  @override
  Future<Profile> fromSqlite(
    Map<String, dynamic> input, {
    required provider,
    covariant OfflineFirstWithSupabaseRepository? repository,
  }) async => await _$ProfileFromSqlite(
    input,
    provider: provider,
    repository: repository,
  );
  @override
  Future<Map<String, dynamic>> toSqlite(
    Profile input, {
    required provider,
    covariant OfflineFirstWithSupabaseRepository? repository,
  }) async => await _$ProfileToSqlite(
    input,
    provider: provider,
    repository: repository,
  );
}
