
import 'package:brick_offline_first_with_supabase/brick_offline_first_with_supabase.dart';
import 'package:brick_sqlite/brick_sqlite.dart';
import 'package:brick_supabase/brick_supabase.dart';
import 'package:uuid/uuid.dart';

@ConnectOfflineFirstWithSupabase(
  supabaseConfig: SupabaseSerializable(tableName: 'profiles'),
)
class Profile extends OfflineFirstWithSupabaseModel {
  final String fullName;
  final String role;
  final String createdAt;
  final String updatedAt;

  @Supabase(unique: true)
  @Sqlite(index: true, unique: true)
  final String id;

  @Supabase(name: 'deleted_at')
  @Sqlite(name: 'deleted_at')
  final String? deletedAt;

  Profile({
    String? id,
    required this.fullName,
    required this.role,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  }) : id = id ?? const Uuid().v4();
}
