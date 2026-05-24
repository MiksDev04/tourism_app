import 'package:shared_preferences/shared_preferences.dart';

/// Holds the in-memory snapshot of the logged-in user's data.
class SessionData {
  final String userId;
  final String fullName;
  final String? username;
  final String email;
  final String phone;
  final String role;

  /// True when the user logged in without an internet connection.
  /// Certain routes are restricted while this is true.
  final bool isOfflineSession;

  // Business fields (null for admin accounts)
  final String? businessId;
  final String? businessName;
  final String? permitNumber;
  final String? registrationNumber;
  final String? street;
  final int? totalRooms;
  final String? permitFileUrl;
  final String? validIdUrl;
  final String? businessType;
  final String? status;
  final String? remarks;
  final String? region;
  final String? cityMunicipality;
  final String? province;
  final String? barangay;
  final String? tradename;
  final List<String>? businessLine;
  final String? ownerFirstName;
  final String? ownerLastName;
  final String? ownerMiddleName;

  const SessionData({
    required this.userId,
    required this.fullName,
    this.username,
    required this.email,
    required this.phone,
    required this.role,
    this.isOfflineSession = false,
    this.businessId,
    this.businessName,
    this.permitNumber,
    this.registrationNumber,
    this.street,
    this.totalRooms,
    this.permitFileUrl,
    this.validIdUrl,
    this.businessType,
    this.status,
    this.remarks,
    this.region,
    this.cityMunicipality,
    this.province,
    this.barangay,
    this.tradename,
    this.businessLine,
    this.ownerFirstName,
    this.ownerLastName,
    this.ownerMiddleName,
  });

  /// Initials derived from full name, e.g. "Juan Dela Cruz" → "JD"
  String get initials {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  String get displayName => fullName;

  /// Concatenated owner name from the business record.
  String get ownerName {
    final parts = <String?>[
      ownerFirstName,
      ownerMiddleName,
      ownerLastName,
    ].where((p) => p != null && p.trim().isNotEmpty).cast<String>();
    return parts.join(' ').trim();
  }
}

/// Persists and retrieves session data via SharedPreferences.
class SessionService {
  // ── Keys ──────────────────────────────────────────────────────────────────
  static const _kUserId             = 'session_user_id';
  static const _kFullName           = 'session_full_name';
  static const _kUsername           = 'session_username';
  static const _kEmail              = 'session_email';
  static const _kPhone              = 'session_phone';
  static const _kRole               = 'session_role';
  static const _kIsOfflineSession   = 'session_is_offline';
  static const _kBusinessId         = 'session_business_id';
  static const _kBusinessName       = 'session_business_name';
  static const _kPermitNumber       = 'session_permit_number';
  static const _kRegistrationNumber = 'session_registration_number';
  static const _kStreet             = 'session_street';
  static const _kTotalRooms         = 'session_total_rooms';
  static const _kPermitFileUrl      = 'session_permit_file_url';
  static const _kValidIdUrl         = 'session_valid_id_url';
  static const _kBusinessType       = 'session_business_type';
  static const _kStatus             = 'session_status';
  static const _kRemarks            = 'session_remarks';
  static const _kRegion             = 'session_region';
  static const _kCityMunicipality   = 'session_city_municipality';
  static const _kProvince           = 'session_province';
  static const _kBarangay           = 'session_barangay';
  static const _kTradename          = 'session_tradename';
  static const _kBusinessLine       = 'session_business_line';
  static const _kOwnerFirstName     = 'session_owner_first_name';
  static const _kOwnerLastName      = 'session_owner_last_name';
  static const _kOwnerMiddleName    = 'session_owner_middle_name';

  // ── Singleton ─────────────────────────────────────────────────────────────
  SessionService._();
  static final SessionService instance = SessionService._();

  // ── Save ──────────────────────────────────────────────────────────────────
  Future<void> save(SessionData data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kUserId, data.userId);
    await prefs.setString(_kFullName, data.fullName);
    if (data.username != null) await prefs.setString(_kUsername, data.username!);
    await prefs.setString(_kEmail, data.email);
    await prefs.setString(_kPhone, data.phone);
    await prefs.setString(_kRole, data.role);
    await prefs.setBool(_kIsOfflineSession, data.isOfflineSession);

    if (data.businessId != null)         await prefs.setString(_kBusinessId, data.businessId!);
    if (data.businessName != null)        await prefs.setString(_kBusinessName, data.businessName!);
    if (data.permitNumber != null)        await prefs.setString(_kPermitNumber, data.permitNumber!);
    if (data.registrationNumber != null)  await prefs.setString(_kRegistrationNumber, data.registrationNumber!);
    if (data.street != null)              await prefs.setString(_kStreet, data.street!);
    if (data.totalRooms != null)          await prefs.setInt(_kTotalRooms, data.totalRooms!);
    if (data.permitFileUrl != null)       await prefs.setString(_kPermitFileUrl, data.permitFileUrl!);
    if (data.validIdUrl != null)          await prefs.setString(_kValidIdUrl, data.validIdUrl!);
    if (data.businessType != null)        await prefs.setString(_kBusinessType, data.businessType!);
    if (data.status != null)              await prefs.setString(_kStatus, data.status!);
    if (data.remarks != null)             await prefs.setString(_kRemarks, data.remarks!);
    if (data.region != null)              await prefs.setString(_kRegion, data.region!);
    if (data.cityMunicipality != null)    await prefs.setString(_kCityMunicipality, data.cityMunicipality!);
    if (data.province != null)            await prefs.setString(_kProvince, data.province!);
    if (data.barangay != null)            await prefs.setString(_kBarangay, data.barangay!);
    if (data.tradename != null)           await prefs.setString(_kTradename, data.tradename!);
    if (data.businessLine != null)        await prefs.setStringList(_kBusinessLine, data.businessLine!);
    if (data.ownerFirstName != null)      await prefs.setString(_kOwnerFirstName, data.ownerFirstName!);
    if (data.ownerLastName != null)       await prefs.setString(_kOwnerLastName, data.ownerLastName!);
    if (data.ownerMiddleName != null)     await prefs.setString(_kOwnerMiddleName, data.ownerMiddleName!);
  }

  // ── Load ──────────────────────────────────────────────────────────────────
  Future<SessionData?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString(_kUserId);
    if (userId == null) return null;

    return SessionData(
      userId:             userId,
      fullName:           prefs.getString(_kFullName) ?? '',
      username:           prefs.getString(_kUsername),
      email:              prefs.getString(_kEmail) ?? '',
      phone:              prefs.getString(_kPhone) ?? '',
      role:               prefs.getString(_kRole) ?? 'business',
      isOfflineSession:   prefs.getBool(_kIsOfflineSession) ?? false,
      businessId:         prefs.getString(_kBusinessId),
      businessName:       prefs.getString(_kBusinessName),
      permitNumber:       prefs.getString(_kPermitNumber),
      registrationNumber: prefs.getString(_kRegistrationNumber),
      street:             prefs.getString(_kStreet),
      totalRooms:         prefs.getInt(_kTotalRooms),
      permitFileUrl:      prefs.getString(_kPermitFileUrl),
      validIdUrl:         prefs.getString(_kValidIdUrl),
      businessType:       prefs.getString(_kBusinessType),
      status:             prefs.getString(_kStatus),
      remarks:            prefs.getString(_kRemarks),
      region:             prefs.getString(_kRegion),
      cityMunicipality:   prefs.getString(_kCityMunicipality),
      province:           prefs.getString(_kProvince),
      barangay:           prefs.getString(_kBarangay),
      tradename:          prefs.getString(_kTradename),
      businessLine:       prefs.getStringList(_kBusinessLine),
      ownerFirstName:     prefs.getString(_kOwnerFirstName),
      ownerLastName:      prefs.getString(_kOwnerLastName),
      ownerMiddleName:    prefs.getString(_kOwnerMiddleName),
    );
  }

  // ── Clear (on logout) ─────────────────────────────────────────────────────
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    // Note: we intentionally do NOT wipe SharedPreferences entirely here
    // so that the SQLite local_profiles data (managed separately) stays intact
    // for future offline logins.
    for (final key in [
      _kUserId, _kFullName, _kUsername, _kEmail, _kPhone, _kRole,
      _kIsOfflineSession,
      _kBusinessId, _kBusinessName, _kPermitNumber, _kRegistrationNumber,
      _kStreet, _kTotalRooms, _kPermitFileUrl, _kValidIdUrl, _kBusinessType,
      _kStatus, _kRemarks, _kRegion, _kCityMunicipality, _kProvince,
      _kBarangay, _kTradename, _kBusinessLine, _kOwnerFirstName,
      _kOwnerLastName, _kOwnerMiddleName,
    ]) {
      await prefs.remove(key);
    }
    _cached = null;
  }

  // ── In-memory cache ───────────────────────────────────────────────────────
  SessionData? _cached;
  SessionData? get current => _cached;

  Future<SessionData?> loadAndCache() async {
    _cached = await load();
    return _cached;
  }
}