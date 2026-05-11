import 'package:brick_offline_first_with_supabase/brick_offline_first_with_supabase.dart';
import 'package:brick_sqlite/brick_sqlite.dart';
import 'package:brick_supabase/brick_supabase.dart';
import 'package:tourism_app/models/profile.model.dart';
import 'package:uuid/uuid.dart';

@ConnectOfflineFirstWithSupabase(
  supabaseConfig: SupabaseSerializable(tableName: 'businesses'),
)
class Business extends OfflineFirstWithSupabaseModel {
  @Supabase(unique: true)
  @Sqlite(index: true, unique: true)
  final String id;

  // Brick resolves the FK (user_id) automatically from the association
  // Only add @Supabase(foreignKey: 'user_id') if there are multiple User FKs
  final Profile profile; // The associated Profile (the "user")

  final String businessName;
  final BusinessType businessType;
  final String? ownerName;
  final String? permitNumber;
  final String? registrationNumber;
  final String? address;
  final int totalRooms;
  final String? permitFileUrl;
  final String? validIdUrl;
  final BusinessStatus status;
  final String? remarks;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;

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
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  }) : id = id ?? const Uuid().v4();
}

enum BusinessType {
  @Supabase(name: 'hotel')
  hotel,
  @Supabase(name: 'resort')
  resort,
  @Supabase(name: 'inn')
  inn,
  @Supabase(name: 'other')
  other,
}

enum BusinessStatus {
  @Supabase(name: 'pending')
  pending,
  @Supabase(name: 'approved')
  approved,
  @Supabase(name: 'rejected')
  rejected,
  @Supabase(name: 'warning')
  warning,
}