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
    required this.street,
    required this.barangay,
    required this.cityMunicipality,
    required this.province,
    required this.region,
    required this.dotAccreditationClassification,
    required this.aeIdCodeLgu,
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
  // Structured address + DOT fields (database updated)
  final String street;
  final String barangay;
  final String cityMunicipality;
  final String province;
  final String region;
  final String dotAccreditationClassification;
  final String aeIdCodeLgu;
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
      // Prefer new `street` column, fall back to legacy `address` if present
      address: (map['street'] as String?)?.isNotEmpty == true
          ? (map['street'] as String)
          : (map['address'] as String? ?? '—'),
      street: map['street'] as String? ?? (map['address'] as String? ?? '—'),
      barangay: map['barangay'] as String? ?? '—',
      cityMunicipality: map['city_municipality'] as String? ?? '—',
      province: map['province'] as String? ?? '—',
      region: map['region'] as String? ?? '—',
      dotAccreditationClassification: map['dot_accreditation_classification'] as String? ?? '—',
      aeIdCodeLgu: map['ae_id_code_lgu'] as String? ?? map['ae_id_code'] as String? ?? '—',
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
      street: street,
      barangay: barangay,
      cityMunicipality: cityMunicipality,
      province: province,
      region: region,
      dotAccreditationClassification: dotAccreditationClassification,
      aeIdCodeLgu: aeIdCodeLgu,
      permitNumber: permitNumber,
      registrationNumber: registrationNumber,
      permitFileUrl: permitFileUrl,
      validIdUrl: validIdUrl,
      remarks: remarks ?? this.remarks,
      createdAt: createdAt,
    );
  }
}
