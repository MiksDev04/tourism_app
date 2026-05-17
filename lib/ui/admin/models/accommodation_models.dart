// lib/ui/admin/models/accommodation_models.dart

enum AccommodationStatus { approved, pending, rejected, warning }

class Accommodation {
  const Accommodation({
    required this.id,
    required this.profileId,
    required this.name,
    required this.type,
    required this.owner,
    required this.email,
    required this.contact,
    required this.rooms,
    required this.status,
    required this.address,
    required this.permitNumber,
    required this.registrationNumber,
    required this.permitFileUrl,
    required this.validIdUrl,
    this.remarks,
    this.createdAt,
  });

  final String id;
  final String profileId;
  final String name;
  final String type;
  final String owner;
  final String? email;
  final String contact;
  final int rooms;
  final AccommodationStatus status;
  final String address;
  final String permitNumber;
  final String registrationNumber;
  final String permitFileUrl;
  final String validIdUrl;
  final String? remarks;
  final String? createdAt;

  static AccommodationStatus _parseStatus(String s) {
    switch (s) {
      case 'approved':
        return AccommodationStatus.approved;
      case 'rejected':
        return AccommodationStatus.rejected;
      case 'warning':
        return AccommodationStatus.warning;
      default:
        return AccommodationStatus.pending;
    }
  }

  factory Accommodation.fromMap(Map<String, dynamic> map) {
    final profile = map['profiles'] as Map<String, dynamic>?;

    return Accommodation(
      id: map['id'] as String,
      profileId: map['profile_id'] as String,
      name: map['business_name'] as String,
      type: map['business_type'] as String,
      owner: map['owner_name'] as String? ?? '—',
      email: profile?['email'] as String? ?? '—', // We'll fetch this on demand in the details modal
      contact: profile?['phone'] as String? ?? '—',
      rooms: map['total_rooms'] as int,
      status: _parseStatus(map['status'] as String),
      address: map['address'] as String? ?? '—',
      permitNumber: map['permit_number'] as String? ?? '—',
      registrationNumber: map['registration_number'] as String? ?? '—',
      permitFileUrl: map['permit_file_url'] as String? ?? '',
      validIdUrl: map['valid_id_url'] as String? ?? '',
      remarks: map['remarks'] as String?,
      createdAt: map['created_at'] as String?,
    );
  }

  Accommodation copyWith({AccommodationStatus? status, String? remarks}) {
    return Accommodation(
      id: id,
      profileId: profileId,
      name: name,
      type: type,
      owner: owner,
      email: email,
      contact: contact,
      rooms: rooms,
      status: status ?? this.status,
      address: address,
      permitNumber: permitNumber,
      registrationNumber: registrationNumber,
      permitFileUrl: permitFileUrl,
      validIdUrl: validIdUrl,
      remarks: remarks ?? this.remarks,
      createdAt: createdAt,
    );
  }
}
