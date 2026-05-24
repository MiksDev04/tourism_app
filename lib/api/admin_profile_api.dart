// ignore_for_file: avoid_print

import 'package:supabase_flutter/supabase_flutter.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  AdminProfileApi
//
//  PASSWORD CHANGE FLOW:
//    Step 1 — sendPasswordChangeOtp()        → 6-digit OTP to current email
//    Step 2 — verifyPasswordChangeOtp(otp)   → validates code, refreshes session
//    Step 3 — verifyOldPassword(oldPass)     → re-auth check
//           + updatePassword(new, confirm)   → sets new password
//
//  EMAIL CHANGE FLOW  (OTP goes to the CURRENT email):
//    Step 1 — sendEmailChangeOtp()           → 6-digit OTP to current email
//    Step 2 — verifyEmailChangeOtp(otp)      → validates code, refreshes session
//    Step 3 — updateEmail(newEmail)          → updates auth.users + auth.identities
//                                               + public.profiles via RPC
//
//  NOTE: signInWithOtp fires a 6-digit code (not a login link) because
//  shouldCreateUser:false and no redirectTo is set. ✔ Desktop-safe.
//
//  Other methods:
//    • fetchProfile()       → load current admin from public.profiles
//    • updateAccountInfo()  → update name / username / phone only
//
//  Exception contract:
//    Every public method throws [ProfileApiException] on error.
//
//  SQL DEPENDENCY — run this in Supabase before using updateEmail():
//
//    CREATE OR REPLACE FUNCTION update_auth_email(new_email text)
//    RETURNS void LANGUAGE plpgsql SECURITY DEFINER
//    SET search_path = auth, public AS $$
//    DECLARE v_uid uuid := auth.uid();
//    BEGIN
//      IF v_uid IS NULL THEN RAISE EXCEPTION 'Not authenticated'; END IF;
//      UPDATE auth.users
//        SET email = new_email, updated_at = now() WHERE id = v_uid;
//      UPDATE auth.identities
//        SET identity_data = identity_data
//                            || jsonb_build_object(
//                                 'email', new_email,
//                                 'email_verified', true,
//                                 'sub', v_uid::text),
//            email      = new_email,
//            updated_at = now()
//        WHERE user_id = v_uid AND provider = 'email';
//    END; $$;
// ─────────────────────────────────────────────────────────────────────────────

class AdminProfileApi {
  AdminProfileApi() : _client = Supabase.instance.client;

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
      throw ProfileApiException(_postgrestMessage(e));
    } catch (e) {
      throw ProfileApiException('Failed to load profile: $e');
    }
  }

  // ────────────────────────────────────────────────────────────────────────────
  //  2. UPDATE ACCOUNT INFO  (name / username / phone only)
  // ────────────────────────────────────────────────────────────────────────────

  Future<void> updateAccountInfo({
    required String fullName,
    required String username,
    required String phone,
  }) async {
    _validators.fullName(fullName);
    _validators.username(username);
    _validators.phone(phone);

    await _assertUsernameAvailable(username, _uid);

    try {
      await _client.from('profiles').update({
        'full_name': fullName.trim(),
        'username': username.trim(),
        'phone': phone.trim(),
      }).eq('id', _uid);
      await _client.auth.refreshSession();
    } on PostgrestException catch (e) {
      throw ProfileApiException(_postgrestMessage(e));
    }
  }

  // ────────────────────────────────────────────────────────────────────────────
  //  3. SEND OTP  — PASSWORD CHANGE STEP 1
  // ────────────────────────────────────────────────────────────────────────────

  Future<void> sendPasswordChangeOtp() async {
    try {
      await _client.auth.signInWithOtp(
        email: _currentEmail,
        shouldCreateUser: false,
      );
    } on AuthException catch (e) {
      throw ProfileApiException('Could not send OTP: ${e.message}');
    } catch (e) {
      throw ProfileApiException('Failed to send OTP. Please try again.');
    }
  }

  // ────────────────────────────────────────────────────────────────────────────
  //  4. VERIFY OTP  — PASSWORD CHANGE STEP 2
  // ────────────────────────────────────────────────────────────────────────────

  Future<void> verifyPasswordChangeOtp({required String otp}) async {
    await _verifyOtp(otp);
  }

  // ────────────────────────────────────────────────────────────────────────────
  //  5. VERIFY OLD PASSWORD  — PASSWORD CHANGE STEP 3a
  // ────────────────────────────────────────────────────────────────────────────

  Future<void> verifyOldPassword({required String oldPassword}) async {
    if (oldPassword.isEmpty) {
      throw const ProfileApiException('Current password is required.');
    }
    try {
      final response = await _client.auth.signInWithPassword(
        email: _currentEmail,
        password: oldPassword,
      );
      if (response.user == null) {
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
      throw ProfileApiException('Unexpected error verifying current password: $e');
    }
  }

  // ────────────────────────────────────────────────────────────────────────────
  //  6. UPDATE PASSWORD  — PASSWORD CHANGE STEP 3b
  // ────────────────────────────────────────────────────────────────────────────

  Future<void> updatePassword({
    required String newPassword,
    required String confirmPassword,
  }) async {
    _validators.password(newPassword, confirmPassword);
    try {
      await _client.auth.updateUser(UserAttributes(password: newPassword));
    } on AuthException catch (e) {
      throw ProfileApiException('Password update failed: ${e.message}');
    } catch (e) {
      throw ProfileApiException('Unexpected error updating password: $e');
    }
  }

  // ────────────────────────────────────────────────────────────────────────────
  //  7. SEND OTP  — EMAIL CHANGE STEP 1
  // ────────────────────────────────────────────────────────────────────────────

  Future<void> sendEmailChangeOtp() async {
    try {
      await _client.auth.signInWithOtp(
        email: _currentEmail,
        shouldCreateUser: false,
      );
    } on AuthException catch (e) {
      throw ProfileApiException('Could not send OTP: ${e.message}');
    } catch (e) {
      throw ProfileApiException('Failed to send OTP. Please try again.');
    }
  }

  // ────────────────────────────────────────────────────────────────────────────
  //  8. VERIFY OTP  — EMAIL CHANGE STEP 2
  // ────────────────────────────────────────────────────────────────────────────

  Future<void> verifyEmailChangeOtp({required String otp}) async {
    await _verifyOtp(otp);
  }

  // ────────────────────────────────────────────────────────────────────────────
  //  9. UPDATE EMAIL  — EMAIL CHANGE STEP 3
  //
  //  Updates all three places the email is stored:
  //    • auth.users          → email column
  //    • auth.identities     → identity_data JSONB + email column  ← was missing
  //    • public.profiles     → email column
  //
  //  After the RPC succeeds the session is refreshed so _currentEmail
  //  immediately reflects the new address without requiring a re-login.
  // ────────────────────────────────────────────────────────────────────────────

  Future<void> updateEmail({required String newEmail}) async {
    final trimmed = newEmail.trim().toLowerCase();
    _validators.email(trimmed);

    if (trimmed == _currentEmail.toLowerCase()) {
      throw const ProfileApiException(
        'New email address must be different from your current one.',
      );
    }

    // Ensure the new address isn't already used by another account
    try {
      final existing = await _client
          .from('profiles')
          .select('id')
          .eq('email', trimmed)
          .neq('id', _uid)
          .maybeSingle();
      if (existing != null) {
        throw const ProfileApiException(
          'That email address is already in use by another account.',
        );
      }
    } on ProfileApiException {
      rethrow;
    } on PostgrestException catch (e) {
      throw ProfileApiException(_postgrestMessage(e));
    }

    // ── RPC: updates auth.users AND auth.identities atomically ──────────────
    //
    //  The previous bug: only auth.users was updated, leaving auth.identities
    //  with the old email. This caused the old address to still be treated as
    //  a valid login identity, and future signInWithPassword calls would
    //  silently resolve against the stale identity row.
    //
    //  The SQL function (update_auth_email) now does:
    //    1. UPDATE auth.users        SET email = new_email
    //    2. UPDATE auth.identities   SET identity_data = identity_data
    //                                    || '{"email": new_email, ...}',
    //                                    email = new_email
    //       WHERE provider = 'email' AND user_id = auth.uid()
    // ────────────────────────────────────────────────────────────────────────
    try {
      await _client.rpc('update_auth_email', params: {'new_email': trimmed});
    } on PostgrestException catch (e) {
      throw ProfileApiException(_postgrestMessage(e));
    } catch (e) {
      throw ProfileApiException('Failed to update auth email: $e');
    }

    // Update public.profiles
    try {
      await _client.from('profiles').update({'email': trimmed}).eq('id', _uid);
    } on PostgrestException catch (e) {
      throw ProfileApiException(_postgrestMessage(e));
    }

    // Refresh session so _currentEmail and the JWT both reflect the new address
    try {
      await _client.auth.refreshSession();
    } catch (_) {
      // Non-fatal — the DB changes succeeded; the app can re-auth on next launch
    }
  }

  // ────────────────────────────────────────────────────────────────────────────
  //  PRIVATE HELPERS
  // ────────────────────────────────────────────────────────────────────────────

  final _validators = _Validators();

  Future<void> _verifyOtp(String otp) async {
    final code = otp.trim();
    if (code.isEmpty) {
      throw const ProfileApiException(
        'Please enter the 6-digit OTP code sent to your email.',
      );
    }
    if (code.length != 6 || !RegExp(r'^\d{6}$').hasMatch(code)) {
      throw const ProfileApiException('OTP must be exactly 6 digits.');
    }
    try {
      final response = await _client.auth.verifyOTP(
        email: _currentEmail,
        token: code,
        type: OtpType.email,
      );
      if (response.user == null) {
        throw const ProfileApiException(
          'OTP verification failed. Please request a new code.',
        );
      }
    } on ProfileApiException {
      rethrow;
    } on AuthException catch (e) {
      final msg = e.message.toLowerCase();
      if (msg.contains('expired')) {
        throw const ProfileApiException(
          'OTP has expired. Please request a new code.',
        );
      }
      if (msg.contains('invalid')) {
        throw const ProfileApiException(
          'Incorrect OTP. Please check the code and try again.',
        );
      }
      throw ProfileApiException('OTP verification failed: ${e.message}');
    } catch (e) {
      throw ProfileApiException('Unexpected error during OTP verification: $e');
    }
  }

  Future<void> _assertUsernameAvailable(String username, String currentUid) async {
    try {
      final existing = await _client
          .from('profiles')
          .select('id')
          .eq('username', username.trim())
          .neq('id', currentUid)
          .maybeSingle();
      if (existing != null) {
        throw ProfileApiException(
          'Username "${username.trim()}" is already taken. Please choose another.',
        );
      }
    } on ProfileApiException {
      rethrow;
    } on PostgrestException catch (e) {
      throw ProfileApiException(_postgrestMessage(e));
    }
  }

  String _postgrestMessage(PostgrestException e) {
    final detail = e.details?.toString().toLowerCase() ?? '';
    final code = e.code ?? '';
    if (code == '23505') {
      if (detail.contains('username')) return 'That username is already in use.';
      if (detail.contains('email')) return 'That email is already registered.';
      return 'A duplicate value already exists.';
    }
    if (code == '23503') return 'Related record not found (foreign key error).';
    if (code == '42501') {
      return 'Permission denied. You may not have access to this resource.';
    }
    return e.message.isNotEmpty ? e.message : 'A database error occurred.';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Validators
// ─────────────────────────────────────────────────────────────────────────────

class _Validators {
  void fullName(String v) {
    final s = v.trim();
    if (s.isEmpty) throw const ProfileApiException('Full name is required.');
    if (s.length < 2) {
      throw const ProfileApiException('Full name must be at least 2 characters.');
    }
    if (s.length > 100) {
      throw const ProfileApiException('Full name must not exceed 100 characters.');
    }
    if (!RegExp(r"^[a-zA-Z\s\-'.]+$").hasMatch(s)) {
      throw const ProfileApiException(
        "Full name may only contain letters, spaces, hyphens ( - ) and apostrophes ( ' ).",
      );
    }
  }

  void username(String v) {
    final s = v.trim();
    if (s.isEmpty) throw const ProfileApiException('Username is required.');
    if (s.length < 3) {
      throw const ProfileApiException('Username must be at least 3 characters.');
    }
    if (s.length > 30) {
      throw const ProfileApiException('Username must not exceed 30 characters.');
    }
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(s)) {
      throw const ProfileApiException(
        'Username may only contain letters, numbers and underscores.',
      );
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
      throw const ProfileApiException('Use format 09XX-XXX-XXXX or +639XXXXXXXXX.');
    }
  }

  void password(String pass, String confirm) {
    if (pass.isEmpty) throw const ProfileApiException('New password is required.');
    if (pass.length < 8) {
      throw const ProfileApiException('Password must be at least 8 characters long.');
    }
    if (!RegExp(r'[A-Z]').hasMatch(pass)) {
      throw const ProfileApiException(
        'Password must contain at least one uppercase letter.',
      );
    }
    if (!RegExp(r'[0-9]').hasMatch(pass)) {
      throw const ProfileApiException(
        'Password must contain at least one number.',
      );
    }
    if (!RegExp(r"[!@#$%^&*()\-_=+\[\]{};:',.<>?/\\|`~@]").hasMatch(pass)) {
      throw const ProfileApiException(
        'Password must contain at least one special character (e.g. @, #, !).',
      );
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

  factory ProfileModel.fromMap(Map<String, dynamic> map) {
    return ProfileModel(
      id: map['id'] as String,
      fullName: map['full_name'] as String,
      username: map['username'] as String,
      email: (map['email'] ?? '') as String,
      phone: map['phone'] as String,
      role: map['role'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  ProfileModel copyWith({
    String? fullName,
    String? username,
    String? email,
    String? phone,
  }) {
    return ProfileModel(
      id: id,
      fullName: fullName ?? this.fullName,
      username: username ?? this.username,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
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