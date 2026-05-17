// GENERATED CODE DO NOT EDIT
part of '../brick.g.dart';

Future<Business> _$BusinessFromSupabase(
  Map<String, dynamic> data, {
  required SupabaseProvider provider,
  OfflineFirstWithSupabaseRepository? repository,
}) async {
  return Business(
    id: data['id'] as String?,
    profile: await ProfileAdapter().fromSupabase(
      data['profile'],
      provider: provider,
      repository: repository,
    ),
    businessName: data['business_name'] as String,
    businessType: BusinessType.values.byName(data['business_type']),
    ownerName: data['owner_name'] == null
        ? null
        : data['owner_name'] as String?,
    permitNumber: data['permit_number'] == null
        ? null
        : data['permit_number'] as String?,
    registrationNumber: data['registration_number'] == null
        ? null
        : data['registration_number'] as String?,
    address: data['address'] == null ? null : data['address'] as String?,
    totalRooms: data['total_rooms'] as int,
    permitFileUrl: data['permit_file_url'] == null
        ? null
        : data['permit_file_url'] as String?,
    validIdUrl: data['valid_id_url'] == null
        ? null
        : data['valid_id_url'] as String?,
    status: BusinessStatus.values.byName(data['status']),
    remarks: data['remarks'] == null ? null : data['remarks'] as String?,
    createdAt: data['created_at'] as String?,
    updatedAt: data['updated_at'] as String?,
  );
}

Future<Map<String, dynamic>> _$BusinessToSupabase(
  Business instance, {
  required SupabaseProvider provider,
  OfflineFirstWithSupabaseRepository? repository,
}) async {
  return {
    'id': instance.id,
    'profile': await ProfileAdapter().toSupabase(
      instance.profile,
      provider: provider,
      repository: repository,
    ),
    'business_name': instance.businessName,
    'business_type': instance.businessType.name,
    'owner_name': instance.ownerName,
    'permit_number': instance.permitNumber,
    'registration_number': instance.registrationNumber,
    'address': instance.address,
    'total_rooms': instance.totalRooms,
    'permit_file_url': instance.permitFileUrl,
    'valid_id_url': instance.validIdUrl,
    'status': instance.status.name,
    'remarks': instance.remarks,
    'created_at': instance.createdAt,
    'updated_at': instance.updatedAt,
  };
}

Future<Business> _$BusinessFromSqlite(
  Map<String, dynamic> data, {
  required SqliteProvider provider,
  OfflineFirstWithSupabaseRepository? repository,
}) async {
  return Business(
    id: data['id'] as String,
    profile: (await repository!.getAssociation<Profile>(
      Query.where(
        'primaryKey',
        data['profile_Profile_brick_id'] as int,
        limit1: true,
      ),
    ))!.first,
    businessName: data['business_name'] as String,
    businessType: BusinessType.values[data['business_type'] as int],
    ownerName: data['owner_name'] == null
        ? null
        : data['owner_name'] as String?,
    permitNumber: data['permit_number'] == null
        ? null
        : data['permit_number'] as String?,
    registrationNumber: data['registration_number'] == null
        ? null
        : data['registration_number'] as String?,
    address: data['address'] == null ? null : data['address'] as String?,
    totalRooms: data['total_rooms'] as int,
    permitFileUrl: data['permit_file_url'] == null
        ? null
        : data['permit_file_url'] as String?,
    validIdUrl: data['valid_id_url'] == null
        ? null
        : data['valid_id_url'] as String?,
    status: BusinessStatus.values[data['status'] as int],
    remarks: data['remarks'] == null ? null : data['remarks'] as String?,
    createdAt: data['created_at'] as String,
    updatedAt: data['updated_at'] as String,
  )..primaryKey = data['_brick_id'] as int;
}

Future<Map<String, dynamic>> _$BusinessToSqlite(
  Business instance, {
  required SqliteProvider provider,
  OfflineFirstWithSupabaseRepository? repository,
}) async {
  return {
    'id': instance.id,
    'profile_Profile_brick_id':
        instance.profile.primaryKey ??
        await provider.upsert<Profile>(
          instance.profile,
          repository: repository,
        ),
    'business_name': instance.businessName,
    'business_type': BusinessType.values.indexOf(instance.businessType),
    'owner_name': instance.ownerName,
    'permit_number': instance.permitNumber,
    'registration_number': instance.registrationNumber,
    'address': instance.address,
    'total_rooms': instance.totalRooms,
    'permit_file_url': instance.permitFileUrl,
    'valid_id_url': instance.validIdUrl,
    'status': BusinessStatus.values.indexOf(instance.status),
    'remarks': instance.remarks,
    'created_at': instance.createdAt,
    'updated_at': instance.updatedAt,
  };
}

/// Construct a [Business]
class BusinessAdapter extends OfflineFirstWithSupabaseAdapter<Business> {
  BusinessAdapter();

  @override
  final supabaseTableName = 'businesses';
  @override
  final defaultToNull = true;
  @override
  final fieldsToSupabaseColumns = {
    'id': const RuntimeSupabaseColumnDefinition(
      association: false,
      columnName: 'id',
    ),
    'profile': const RuntimeSupabaseColumnDefinition(
      association: true,
      columnName: 'profile',
      associationType: Profile,
      associationIsNullable: false,
      foreignKey: 'profile_id',
    ),
    'businessName': const RuntimeSupabaseColumnDefinition(
      association: false,
      columnName: 'business_name',
    ),
    'businessType': const RuntimeSupabaseColumnDefinition(
      association: false,
      columnName: 'business_type',
    ),
    'ownerName': const RuntimeSupabaseColumnDefinition(
      association: false,
      columnName: 'owner_name',
    ),
    'permitNumber': const RuntimeSupabaseColumnDefinition(
      association: false,
      columnName: 'permit_number',
    ),
    'registrationNumber': const RuntimeSupabaseColumnDefinition(
      association: false,
      columnName: 'registration_number',
    ),
    'address': const RuntimeSupabaseColumnDefinition(
      association: false,
      columnName: 'address',
    ),
    'totalRooms': const RuntimeSupabaseColumnDefinition(
      association: false,
      columnName: 'total_rooms',
    ),
    'permitFileUrl': const RuntimeSupabaseColumnDefinition(
      association: false,
      columnName: 'permit_file_url',
    ),
    'validIdUrl': const RuntimeSupabaseColumnDefinition(
      association: false,
      columnName: 'valid_id_url',
    ),
    'status': const RuntimeSupabaseColumnDefinition(
      association: false,
      columnName: 'status',
    ),
    'remarks': const RuntimeSupabaseColumnDefinition(
      association: false,
      columnName: 'remarks',
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
    'profile': const RuntimeSqliteColumnDefinition(
      association: true,
      columnName: 'profile_Profile_brick_id',
      iterable: false,
      type: Profile,
    ),
    'businessName': const RuntimeSqliteColumnDefinition(
      association: false,
      columnName: 'business_name',
      iterable: false,
      type: String,
    ),
    'businessType': const RuntimeSqliteColumnDefinition(
      association: false,
      columnName: 'business_type',
      iterable: false,
      type: BusinessType,
    ),
    'ownerName': const RuntimeSqliteColumnDefinition(
      association: false,
      columnName: 'owner_name',
      iterable: false,
      type: String,
    ),
    'permitNumber': const RuntimeSqliteColumnDefinition(
      association: false,
      columnName: 'permit_number',
      iterable: false,
      type: String,
    ),
    'registrationNumber': const RuntimeSqliteColumnDefinition(
      association: false,
      columnName: 'registration_number',
      iterable: false,
      type: String,
    ),
    'address': const RuntimeSqliteColumnDefinition(
      association: false,
      columnName: 'address',
      iterable: false,
      type: String,
    ),
    'totalRooms': const RuntimeSqliteColumnDefinition(
      association: false,
      columnName: 'total_rooms',
      iterable: false,
      type: int,
    ),
    'permitFileUrl': const RuntimeSqliteColumnDefinition(
      association: false,
      columnName: 'permit_file_url',
      iterable: false,
      type: String,
    ),
    'validIdUrl': const RuntimeSqliteColumnDefinition(
      association: false,
      columnName: 'valid_id_url',
      iterable: false,
      type: String,
    ),
    'status': const RuntimeSqliteColumnDefinition(
      association: false,
      columnName: 'status',
      iterable: false,
      type: BusinessStatus,
    ),
    'remarks': const RuntimeSqliteColumnDefinition(
      association: false,
      columnName: 'remarks',
      iterable: false,
      type: String,
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
    Business instance,
    DatabaseExecutor executor,
  ) async {
    final results = await executor.rawQuery(
      '''
        SELECT * FROM `Business` WHERE id = ? LIMIT 1''',
      [instance.id],
    );

    // SQFlite returns [{}] when no results are found
    if (results.isEmpty || (results.length == 1 && results.first.isEmpty)) {
      return null;
    }

    return results.first['_brick_id'] as int;
  }

  @override
  final String tableName = 'Business';

  @override
  Future<Business> fromSupabase(
    Map<String, dynamic> input, {
    required provider,
    covariant OfflineFirstWithSupabaseRepository? repository,
  }) async => await _$BusinessFromSupabase(
    input,
    provider: provider,
    repository: repository,
  );
  @override
  Future<Map<String, dynamic>> toSupabase(
    Business input, {
    required provider,
    covariant OfflineFirstWithSupabaseRepository? repository,
  }) async => await _$BusinessToSupabase(
    input,
    provider: provider,
    repository: repository,
  );
  @override
  Future<Business> fromSqlite(
    Map<String, dynamic> input, {
    required provider,
    covariant OfflineFirstWithSupabaseRepository? repository,
  }) async => await _$BusinessFromSqlite(
    input,
    provider: provider,
    repository: repository,
  );
  @override
  Future<Map<String, dynamic>> toSqlite(
    Business input, {
    required provider,
    covariant OfflineFirstWithSupabaseRepository? repository,
  }) async => await _$BusinessToSqlite(
    input,
    provider: provider,
    repository: repository,
  );
}
