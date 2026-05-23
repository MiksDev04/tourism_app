// ignore_for_file: avoid_print

import 'package:supabase_flutter/supabase_flutter.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Enums
// ─────────────────────────────────────────────────────────────────────────────

enum BusinessLine {
  hotel,
  resort,
  motel,
  pensionInn,
  youthHostel,
  others;

  String get dbValue => switch (this) {
    BusinessLine.youthHostel => 'pensionHouse',
    _ => name,
  };

  String get label => switch (this) {
    BusinessLine.hotel        => 'Hotel',
    BusinessLine.resort       => 'Resort',
    BusinessLine.motel   => 'Motel',
    BusinessLine.pensionInn         => 'Pension Inn',
    BusinessLine.youthHostel => 'Youth Hostel',
    BusinessLine.others        => 'Others',
  };

  static BusinessLine fromDb(String v) => BusinessLine.values.firstWhere(
    (e) => e.dbValue == v,
    orElse: () => BusinessLine.others,
  );
}

enum BusinessType {
  soleProprietorship,
  partnership,
  corporation,
  cooperative;

  String get dbValue => switch (this) {
    BusinessType.soleProprietorship => 'sole_proprietorship',
    _ => name,
  };

  String get label => switch (this) {
    BusinessType.soleProprietorship => 'Sole Proprietorship',
    BusinessType.partnership        => 'Partnership',
    BusinessType.corporation        => 'Corporation',
    BusinessType.cooperative        => 'Cooperative',
  };

  static BusinessType fromDb(String v) => BusinessType.values.firstWhere(
    (e) => e.dbValue == v,
    orElse: () => BusinessType.soleProprietorship,
  );
}

enum BusinessStatus {
  pending,
  approved,
  rejected,
  suspended;

  static BusinessStatus fromDb(String v) => BusinessStatus.values.firstWhere(
    (e) => e.name == v,
    orElse: () => BusinessStatus.pending,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
//  BusinessProfileApi
//
//  PASSWORD CHANGE FLOW:
//    Step 1 — sendPasswordChangeOtp()        → 6-digit OTP to current email
//    Step 2 — verifyPasswordChangeOtp(otp)   → validates code, refreshes session
//    Step 3 — verifyOldPassword(oldPass)     → re-auth check
//           + updatePassword(new, confirm)   → sets new password
//
//  EMAIL CHANGE FLOW (OTP goes to CURRENT email, RPC skips confirmation email):
//    Step 1 — sendEmailChangeOtp()           → 6-digit OTP to current email
//    Step 2 — verifyEmailChangeOtp(otp)      → validates code, refreshes session
//    Step 3 — updateEmail(newEmail)          → RPC direct write to auth.users
//
//  PROFILE / BUSINESS:
//    fetchProfile()        → public.profiles row for current user
//    fetchBusiness()       → public.businesses row for current user
//    updateAccountInfo()   → update name / username / phone in profiles
//    updateBusinessInfo()  → update all editable fields in businesses
//
//  Exception contract: every public method throws [ProfileApiException].
// ─────────────────────────────────────────────────────────────────────────────

class BusinessProfileApi {
  BusinessProfileApi() : _client = Supabase.instance.client;

  final SupabaseClient _client;

  // ── Convenience ─────────────────────────────────────────────────────────────

  String get _uid {
    final id = _client.auth.currentUser?.id;
    if (id == null) throw const ProfileApiException('No authenticated user found.');
    return id;
  }

  String get _currentEmail {
    final email = _client.auth.currentUser?.email;
    if (email == null || email.isEmpty) {
      throw const ProfileApiException('Authenticated user has no email address.');
    }
    return email;
  }

  // ────────────────────────────────────────────────────────────────────────────
  //  1. FETCH PROFILE
  // ────────────────────────────────────────────────────────────────────────────

  Future<ProfileModel> fetchProfile() async {
    try {
      final row = await _client
          .from('profiles')
          .select('id, full_name, username, email, phone, role, created_at, updated_at')
          .eq('id', _uid)
          .single();
      return ProfileModel.fromMap(row);
    } on ProfileApiException {
      rethrow;
    } on PostgrestException catch (e) {
      throw ProfileApiException(_pgMsg(e));
    } catch (e) {
      throw ProfileApiException('Failed to load profile: $e');
    }
  }

  // ────────────────────────────────────────────────────────────────────────────
  //  2. FETCH BUSINESS
  // ────────────────────────────────────────────────────────────────────────────

  Future<BusinessModel?> fetchBusiness() async {
    try {
      final row = await _client
          .from('businesses')
          .select()
          .eq('profile_id', _uid)
          .isFilter('deleted_at', null)
          .maybeSingle();
      if (row == null) return null;
      return BusinessModel.fromMap(row);
    } on PostgrestException catch (e) {
      throw ProfileApiException(_pgMsg(e));
    } catch (e) {
      throw ProfileApiException('Failed to load business: $e');
    }
  }

  // ────────────────────────────────────────────────────────────────────────────
  //  3. UPDATE ACCOUNT INFO  (name / username / phone only)
  // ────────────────────────────────────────────────────────────────────────────

  Future<void> updateAccountInfo({
    required String fullName,
    required String username,
    required String phone,
  }) async {
    _v.fullName(fullName);
    _v.username(username);
    _v.phone(phone);
    await _assertUsernameAvailable(username, _uid);
    try {
      await _client.from('profiles').update({
        'full_name': fullName.trim(),
        'username':  username.trim(),
        'phone':     phone.trim(),
      }).eq('id', _uid);
      await _client.auth.refreshSession();

    } on PostgrestException catch (e) {
      throw ProfileApiException(_pgMsg(e));
    }
  }

  // ────────────────────────────────────────────────────────────────────────────
  //  4. UPDATE BUSINESS INFO
  // ────────────────────────────────────────────────────────────────────────────

  Future<void> updateBusinessInfo({
    required String businessId,
    required String businessName,
    String? tradename,
    String? ownerFirstName,
    String? ownerMiddleName,
    String? ownerLastName,
    required BusinessType businessType,
    required List<BusinessLine> businessLine,
    required int totalRooms,
    String? street,
    String? barangay,
    String? cityMunicipality,
    String? province,
    String? region,
    String? permitNumber,
    String? registrationNumber,
  }) async {
    if (businessName.trim().isEmpty) {
      throw const ProfileApiException('Business name is required.');
    }
    if (businessLine.isEmpty) {
      throw const ProfileApiException(
          'At least one business line must be selected.');
    }

    String? _nul(String? v) {
      final s = v?.trim();
      return (s == null || s.isEmpty) ? null : s;
    }

    try {
      await _client.from('businesses').update({
        'business_name':       businessName.trim(),
        'tradename':           _nul(tradename),
        'owner_first_name':    _nul(ownerFirstName),
        'owner_middle_name':   _nul(ownerMiddleName),
        'owner_last_name':     _nul(ownerLastName),
        'business_type':       businessType.dbValue,
        'business_line':       businessLine.map((e) => e.dbValue).toList(),
        'total_rooms':         totalRooms,
        'street':              _nul(street),
        'barangay':            _nul(barangay),
        'city_municipality':   _nul(cityMunicipality),
        'province':            _nul(province),
        'region':              _nul(region),
        'permit_number':       _nul(permitNumber),
        'registration_number': _nul(registrationNumber),
      }).eq('id', businessId);
      await _client.auth.refreshSession();

    } on PostgrestException catch (e) {
      throw ProfileApiException(_pgMsg(e));
    }
  }

  // ────────────────────────────────────────────────────────────────────────────
  //  5. SEND OTP  — PASSWORD CHANGE STEP 1
  // ────────────────────────────────────────────────────────────────────────────

  Future<void> sendPasswordChangeOtp() async {
    try {
      await _client.auth.signInWithOtp(
        email: _currentEmail,
        shouldCreateUser: false,
      );
    } on AuthException catch (e) {
      throw ProfileApiException('Could not send OTP: ${e.message}');
    } catch (_) {
      throw const ProfileApiException('Failed to send OTP. Please try again.');
    }
  }

  // ────────────────────────────────────────────────────────────────────────────
  //  6. VERIFY OTP  — PASSWORD CHANGE STEP 2
  // ────────────────────────────────────────────────────────────────────────────

  Future<void> verifyPasswordChangeOtp({required String otp}) =>
      _verifyOtp(otp);

  // ────────────────────────────────────────────────────────────────────────────
  //  7. VERIFY OLD PASSWORD  — PASSWORD CHANGE STEP 3a
  // ────────────────────────────────────────────────────────────────────────────

  Future<void> verifyOldPassword({required String oldPassword}) async {
    if (oldPassword.isEmpty) {
      throw const ProfileApiException('Current password is required.');
    }
    try {
      final res = await _client.auth.signInWithPassword(
        email: _currentEmail,
        password: oldPassword,
      );
      if (res.user == null) {
        throw const ProfileApiException('Current password is incorrect.');
      }
    } on ProfileApiException {
      rethrow;
    } on AuthException catch (e) {
      final msg = e.message.toLowerCase();
      if (msg.contains('invalid') ||
          msg.contains('credentials') ||
          msg.contains('password')) {
        throw const ProfileApiException('Current password is incorrect.');
      }
      throw ProfileApiException('Verification failed: ${e.message}');
    } catch (e) {
      throw ProfileApiException('Unexpected error verifying password: $e');
    }
  }

  // ────────────────────────────────────────────────────────────────────────────
  //  8. UPDATE PASSWORD  — PASSWORD CHANGE STEP 3b
  // ────────────────────────────────────────────────────────────────────────────

  Future<void> updatePassword({
    required String newPassword,
    required String confirmPassword,
  }) async {
    _v.password(newPassword, confirmPassword);
    try {
      await _client.auth.updateUser(UserAttributes(password: newPassword));
    } on AuthException catch (e) {
      throw ProfileApiException('Password update failed: ${e.message}');
    } catch (e) {
      throw ProfileApiException('Unexpected error: $e');
    }
  }

  // ────────────────────────────────────────────────────────────────────────────
  //  9. SEND OTP  — EMAIL CHANGE STEP 1
  // ────────────────────────────────────────────────────────────────────────────

  Future<void> sendEmailChangeOtp() async {
    try {
      await _client.auth.signInWithOtp(
        email: _currentEmail,
        shouldCreateUser: false,
      );
    } on AuthException catch (e) {
      throw ProfileApiException('Could not send OTP: ${e.message}');
    } catch (_) {
      throw const ProfileApiException('Failed to send OTP. Please try again.');
    }
  }

  // ────────────────────────────────────────────────────────────────────────────
  //  10. VERIFY OTP  — EMAIL CHANGE STEP 2
  // ────────────────────────────────────────────────────────────────────────────

  Future<void> verifyEmailChangeOtp({required String otp}) => _verifyOtp(otp);

  // ────────────────────────────────────────────────────────────────────────────
  //  11. UPDATE EMAIL  — EMAIL CHANGE STEP 3
  //      Uses SECURITY DEFINER RPC to bypass Supabase confirmation email.
  //      Requires SQL function: update_auth_email(new_email TEXT)
  // ────────────────────────────────────────────────────────────────────────────

  Future<void> updateEmail({required String newEmail}) async {
    final trimmed = newEmail.trim().toLowerCase();
    _v.email(trimmed);

    if (trimmed == _currentEmail.toLowerCase()) {
      throw const ProfileApiException(
          'New email must be different from your current one.');
    }

    try {
      final existing = await _client
          .from('profiles')
          .select('id')
          .eq('email', trimmed)
          .neq('id', _uid)
          .maybeSingle();
      if (existing != null) {
        throw const ProfileApiException(
            'That email is already in use by another account.');
      }
    } on ProfileApiException {
      rethrow;
    } on PostgrestException catch (e) {
      throw ProfileApiException(_pgMsg(e));
    }

    try {
      await _client.from('profiles').update({'email': trimmed}).eq('id', _uid);

    } on PostgrestException catch (e) {
      throw ProfileApiException(_pgMsg(e));
    }

    try {
      await _client.rpc('update_auth_email', params: {'new_email': trimmed});
      await _client.auth.refreshSession();
    } on PostgrestException catch (e) {
      throw ProfileApiException(_pgMsg(e));
    } on AuthException catch (e) {
      throw ProfileApiException('Session refresh failed: ${e.message}');
    } catch (e) {
      throw ProfileApiException('Failed to update auth email: $e');
    }
  }

  // ────────────────────────────────────────────────────────────────────────────
  //  PRIVATE HELPERS
  // ────────────────────────────────────────────────────────────────────────────

  final _v = _Validators();

  Future<void> _verifyOtp(String otp) async {
    final code = otp.trim();
    if (code.isEmpty) {
      throw const ProfileApiException(
          'Please enter the 6-digit OTP code sent to your email.');
    }
    if (code.length != 6 || !RegExp(r'^\d{6}$').hasMatch(code)) {
      throw const ProfileApiException('OTP must be exactly 6 digits.');
    }
    try {
      final res = await _client.auth.verifyOTP(
        email: _currentEmail,
        token: code,
        type: OtpType.email,
      );
      if (res.user == null) {
        throw const ProfileApiException(
            'OTP verification failed. Please request a new code.');
      }
    } on ProfileApiException {
      rethrow;
    } on AuthException catch (e) {
      final msg = e.message.toLowerCase();
      if (msg.contains('expired')) {
        throw const ProfileApiException(
            'OTP has expired. Please request a new code.');
      }
      if (msg.contains('invalid')) {
        throw const ProfileApiException(
            'Incorrect OTP. Please check and try again.');
      }
      throw ProfileApiException('OTP verification failed: ${e.message}');
    } catch (e) {
      throw ProfileApiException('Unexpected error during OTP verification: $e');
    }
  }

  Future<void> _assertUsernameAvailable(String username, String uid) async {
    try {
      final existing = await _client
          .from('profiles')
          .select('id')
          .eq('username', username.trim())
          .neq('id', uid)
          .maybeSingle();
      if (existing != null) {
        throw ProfileApiException(
            'Username "${username.trim()}" is already taken.');
      }
    } on ProfileApiException {
      rethrow;
    } on PostgrestException catch (e) {
      throw ProfileApiException(_pgMsg(e));
    }
  }

  String _pgMsg(PostgrestException e) {
    final detail = e.details?.toString().toLowerCase() ?? '';
    final code   = e.code ?? '';
    if (code == '23505') {
      if (detail.contains('username')) return 'That username is already in use.';
      if (detail.contains('email'))    return 'That email is already registered.';
      return 'A duplicate value already exists.';
    }
    if (code == '23503') return 'Related record not found.';
    if (code == '42501') return 'Permission denied.';
    return e.message.isNotEmpty ? e.message : 'A database error occurred.';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Validators (identical to admin)
// ─────────────────────────────────────────────────────────────────────────────

class _Validators {
  void fullName(String v) {
    final s = v.trim();
    if (s.isEmpty)      throw const ProfileApiException('Full name is required.');
    if (s.length < 2)   throw const ProfileApiException('Full name must be at least 2 characters.');
    if (s.length > 100) throw const ProfileApiException('Full name must not exceed 100 characters.');
    if (!RegExp(r"^[a-zA-Z\s\-'.]+$").hasMatch(s)) {
      throw const ProfileApiException(
          "Full name may only contain letters, spaces, hyphens and apostrophes.");
    }
  }

  void username(String v) {
    final s = v.trim();
    if (s.isEmpty)     throw const ProfileApiException('Username is required.');
    if (s.length < 3)  throw const ProfileApiException('Username must be at least 3 characters.');
    if (s.length > 30) throw const ProfileApiException('Username must not exceed 30 characters.');
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(s)) {
      throw const ProfileApiException(
          'Username may only contain letters, numbers and underscores.');
    }
  }

  void email(String v) {
    final s = v.trim();
    if (s.isEmpty) throw const ProfileApiException('Email address is required.');
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s)) {
      throw const ProfileApiException('Please enter a valid email address.');
    }
  }

  static final _phoneRe = RegExp(r'^(09\d{9}|639\d{9}|\+639\d{9})$');

  void phone(String v) {
    final stripped = v.trim().replaceAll(RegExp(r'[-\s]'), '');
    if (stripped.isEmpty) throw const ProfileApiException('Phone number is required.');
    if (!_phoneRe.hasMatch(stripped)) {
      throw const ProfileApiException(
          'Use format 09XX-XXX-XXXX or +639XXXXXXXXX.');
    }
  }

  void password(String pass, String confirm) {
    if (pass.isEmpty)    throw const ProfileApiException('New password is required.');
    if (pass.length < 8) throw const ProfileApiException('Password must be at least 8 characters long.');
    if (!RegExp(r'[A-Z]').hasMatch(pass)) {
      throw const ProfileApiException(
          'Password must contain at least one uppercase letter.');
    }
    if (!RegExp(r'[0-9]').hasMatch(pass)) {
      throw const ProfileApiException('Password must contain at least one number.');
    }
    if (!RegExp(r"[!@#$%^&*()\-_=+\[\]{};:',.<>?/\\|`~@]").hasMatch(pass)) {
      throw const ProfileApiException(
          'Password must contain at least one special character (e.g. @, #, !).');
    }
    if (pass != confirm) throw const ProfileApiException('Passwords do not match.');
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  ProfileModel
// ─────────────────────────────────────────────────────────────────────────────

class ProfileModel {
  const ProfileModel({
    required this.id,
    required this.fullName,
    required this.username,
    required this.email,
    required this.phone,
    required this.role,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String fullName;
  final String username;
  final String email;
  final String phone;
  final String role;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory ProfileModel.fromMap(Map<String, dynamic> map) => ProfileModel(
    id:        map['id']        as String,
    fullName:  map['full_name'] as String,
    username:  map['username']  as String,
    email:     (map['email'] ?? '') as String,
    phone:     map['phone']     as String,
    role:      map['role']      as String,
    createdAt: DateTime.parse(map['created_at'] as String),
    updatedAt: DateTime.parse(map['updated_at'] as String),
  );

  ProfileModel copyWith({
    String? fullName, String? username, String? email, String? phone,
  }) => ProfileModel(
    id: id, fullName: fullName ?? this.fullName,
    username: username ?? this.username, email: email ?? this.email,
    phone: phone ?? this.phone, role: role,
    createdAt: createdAt, updatedAt: DateTime.now(),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
//  BusinessModel
// ─────────────────────────────────────────────────────────────────────────────

class BusinessModel {
  const BusinessModel({
    required this.id,
    required this.profileId,
    required this.businessName,
    this.tradename,
    this.permitNumber,
    this.registrationNumber,
    this.street,
    this.barangay,
    this.cityMunicipality,
    this.province,
    this.region,
    required this.totalRooms,
    this.permitFileUrl,
    this.validIdUrl,
    required this.status,
    this.remarks,
    required this.businessLine,
    this.ownerFirstName,
    this.ownerMiddleName,
    this.ownerLastName,
    required this.businessType,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String profileId;
  final String businessName;
  final String? tradename;
  final String? permitNumber;
  final String? registrationNumber;
  final String? street;
  final String? barangay;
  final String? cityMunicipality;
  final String? province;
  final String? region;
  final int totalRooms;
  final String? permitFileUrl;
  final String? validIdUrl;
  final BusinessStatus status;
  final String? remarks;
  final List<BusinessLine> businessLine;
  final String? ownerFirstName;
  final String? ownerMiddleName;
  final String? ownerLastName;
  final BusinessType businessType;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory BusinessModel.fromMap(Map<String, dynamic> map) {
    final lineRaw = (map['business_line'] as List?)?.cast<String>() ?? [];
    return BusinessModel(
      id:                 map['id'] as String,
      profileId:          map['profile_id'] as String,
      businessName:       map['business_name'] as String,
      tradename:          map['tradename'] as String?,
      permitNumber:       map['permit_number'] as String?,
      registrationNumber: map['registration_number'] as String?,
      street:             map['street'] as String?,
      barangay:           map['barangay'] as String?,
      cityMunicipality:   map['city_municipality'] as String?,
      province:           map['province'] as String?,
      region:             map['region'] as String?,
      totalRooms:         (map['total_rooms'] as num?)?.toInt() ?? 0,
      permitFileUrl:      map['permit_file_url'] as String?,
      validIdUrl:         map['valid_id_url'] as String?,
      status:             BusinessStatus.fromDb(
                            map['status'] as String? ?? 'pending'),
      remarks:            map['remarks'] as String?,
      businessLine:       lineRaw.map(BusinessLine.fromDb).toList(),
      ownerFirstName:     map['owner_first_name'] as String?,
      ownerMiddleName:    map['owner_middle_name'] as String?,
      ownerLastName:      map['owner_last_name'] as String?,
      businessType:       BusinessType.fromDb(
                            map['business_type'] as String? ??
                            'sole_proprietorship'),
      createdAt:          DateTime.parse(map['created_at'] as String),
      updatedAt:          DateTime.parse(map['updated_at'] as String),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  ProfileApiException
// ─────────────────────────────────────────────────────────────────────────────

class ProfileApiException implements Exception {
  const ProfileApiException(this.message);
  final String message;
  @override
  String toString() => 'ProfileApiException: $message';
}