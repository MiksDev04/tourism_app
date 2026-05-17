import 'package:brick_offline_first_with_supabase/brick_offline_first_with_supabase.dart';
import 'package:brick_sqlite/brick_sqlite.dart';
import 'package:brick_supabase/brick_supabase.dart';
import 'package:tourism_app/brick/models/profile.model.dart';
import 'package:uuid/uuid.dart';

enum BusinessType { hotel, resort, inn, other }

enum BusinessStatus { pending, approved, rejected }

@ConnectOfflineFirstWithSupabase(
  supabaseConfig: SupabaseSerializable(tableName: 'businesses'),
)
class Business extends OfflineFirstWithSupabaseModel {
  @Supabase(unique: true)
  @Sqlite(index: true, unique: true)
  final String id;

  @Supabase(foreignKey: 'profile_id') // ← add this
  final Profile profile;

  final String businessName;

  @Supabase(enumAsString: true) // ← add
  final BusinessType businessType;

  final String? ownerName;
  final String? permitNumber;
  final String? registrationNumber;
  final String? address;
  final int totalRooms;
  final String? permitFileUrl;
  final String? validIdUrl;

  @Supabase(enumAsString: true) // ← add
  final BusinessStatus status;

  final String? remarks;
  final String createdAt;
  final String updatedAt;

  Business({
    String? id,
    required this.profile,
    required this.businessName,
    this.businessType = BusinessType.hotel,
    this.ownerName,
    this.permitNumber,
    this.registrationNumber,
    this.address,
    this.totalRooms = 0,
    this.permitFileUrl,
    this.validIdUrl,
    this.status = BusinessStatus.pending,
    this.remarks,
    String? createdAt,
    String? updatedAt,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now().toIso8601String(),
       updatedAt = updatedAt ?? DateTime.now().toIso8601String();
}
