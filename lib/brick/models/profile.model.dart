import 'package:brick_offline_first_with_supabase/brick_offline_first_with_supabase.dart';
import 'package:brick_sqlite/brick_sqlite.dart';
import 'package:brick_supabase/brick_supabase.dart';

enum Role { business, admin }

@ConnectOfflineFirstWithSupabase(
  supabaseConfig: SupabaseSerializable(tableName: 'profiles'),
)
class Profile extends OfflineFirstWithSupabaseModel {
  @Supabase(unique: true)
  @Sqlite(index: true, unique: true)
  final String id;

  final String fullName;
  final String phone;
  final String email; // ← add this

  @Supabase(enumAsString: true)  // ← add here
  final Role role;

  final String createdAt;
  final String updatedAt;

  Profile({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.email, // ← add this
    this.role = Role.business,
    String? createdAt,
    String? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now().toIso8601String(),
        updatedAt = updatedAt ?? DateTime.now().toIso8601String();
}