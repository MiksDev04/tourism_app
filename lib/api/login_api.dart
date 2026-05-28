// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tourism_app/core/database/local_database.dart';
import 'package:tourism_app/core/services/offline_service.dart';
import 'package:tourism_app/core/services/session_service.dart';

enum Role { business, admin }

class LoginResult {
  final bool success;
  final String? error;
  final Role? role;

  const LoginResult._({required this.success, this.error, this.role});

  factory LoginResult.ok(Role role) => LoginResult._(success: true, role: role);
  factory LoginResult.err(String error) =>
      LoginResult._(success: false, error: error);
}

// ─────────────────────────────────────────────────────────────────────────────
//  LoginApiException
//  Thrown by all forgot-password methods.
// ─────────────────────────────────────────────────────────────────────────────

class LoginApiException implements Exception {
  const LoginApiException(this.message);
  final String message;
  @override
  String toString() => 'LoginApiException: $message';
}

// ─────────────────────────────────────────────────────────────────────────────
//  LoginApi
// ─────────────────────────────────────────────────────────────────────────────

class LoginApi {
  final _supabase = Supabase.instance.client;

  // ===========================================================================
  // SIGN IN
  // ===========================================================================

  Future<LoginResult> login({
    required String username,
    required String password,
  }) async {
    final isOnline = ConnectivityService.instance.isOnline;

    // =========================================================================
    // OFFLINE PATH
    // =========================================================================
    if (!isOnline) {
      return _offlineLogin(username: username, password: password);
    }

    // =========================================================================
    // ONLINE PATH
    // =========================================================================
    try {
      // ── 1. Resolve username → email via RPC ────────────────────────────────
      final email =
          await _supabase.rpc(
                'get_email_by_username',
                params: {'p_username': username.trim().toLowerCase()},
              )
              as String?;

      if (email == null || email.isEmpty) {
        return LoginResult.err('No account found with that username.');
      }

      // ── 2. Authenticate with Supabase ──────────────────────────────────────
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        return LoginResult.err('Login failed. Please try again.');
      }

      final userId = response.user!.id;

      // ── 3. Fetch profile ───────────────────────────────────────────────────
      final profileData = await _supabase
          .from('profiles')
          .select('full_name, phone, role, email, username')
          .eq('id', userId)
          .maybeSingle();

      if (profileData == null) {
        return LoginResult.err(
          'Account does not exist. Please register first.',
        );
      }

      final roleStr = profileData['role'] as String?;
      if (roleStr == null) {
        return LoginResult.err('Profile not found. Please contact support.');
      }

      final role = roleStr == 'admin' ? Role.admin : Role.business;

      // ── 4. Business: check approval + fetch business row ───────────────────
      String? businessId;
      String? businessName;
      String? permitNumber;
      String? registrationNumber;
      String? street;
      int? totalRooms;
      String? permitFileUrl;
      String? validIdUrl;
      String? businessType;
      String? status;
      String? remarks;
      String? region;
      String? cityMunicipality;
      String? province;
      String? barangay;
      String? tradename;
      List<String>? businessLine;
      String? ownerFirstName;
      String? ownerLastName;
      String? ownerMiddleName;

      if (role == Role.admin) {
        await _cacheProfileLocally(
          userId: userId,
          username: username,
          password: password,
          profileData: profileData,
          roleStr: roleStr,
        );
      } else {
        final businessData = await _supabase
            .from('businesses')
            .select(
              'id, business_name, permit_number, registration_number, street, '
              'total_rooms, permit_file_url, valid_id_url, status, remarks, '
              'region, city_municipality, province, barangay, tradename, '
              'business_line, owner_first_name, owner_last_name, '
              'owner_middle_name, business_type',
            )
            .eq('profile_id', userId)
            .maybeSingle();

        if (businessData == null) {
          return LoginResult.err(
            'Business profile not found. Please contact support.',
          );
        }

        status = businessData['status'] as String? ?? 'pending';

        if (status == 'pending') {
          return LoginResult.err(
            'Your account is still pending approval. '
            'Please wait for an administrator to review your application.',
          );
        }
        if (status == 'suspended') {
          return LoginResult.err(
            'Your account is suspended because of violations. '
            'Please go to tourism office for more information.',
          );
        }
        if (status == 'rejected') {
          return LoginResult.err(
            'Your account application was not approved. '
            'Please visit the tourism office for more information.',
          );
        }

        businessId = businessData['id'] as String?;
        businessName = businessData['business_name'] as String?;
        permitNumber = businessData['permit_number'] as String?;
        registrationNumber = businessData['registration_number'] as String?;
        street = businessData['street'] as String?;
        totalRooms = businessData['total_rooms'] as int?;
        permitFileUrl = businessData['permit_file_url'] as String?;
        validIdUrl = businessData['valid_id_url'] as String?;
        businessType = businessData['business_type'] as String?;
        remarks = businessData['remarks'] as String?;
        region = businessData['region'] as String?;
        cityMunicipality = businessData['city_municipality'] as String?;
        province = businessData['province'] as String?;
        barangay = businessData['barangay'] as String?;
        tradename = businessData['tradename'] as String?;
        businessLine = (businessData['business_line'] as List<dynamic>?)
            ?.map((v) => v.toString())
            .toList();
        ownerFirstName = businessData['owner_first_name'] as String?;
        ownerLastName = businessData['owner_last_name'] as String?;
        ownerMiddleName = businessData['owner_middle_name'] as String?;

        // ── 5. Cache credentials + business to SQLite ──────────────────────
        await _cacheProfileLocally(
          userId: userId,
          username: username,
          password: password,
          profileData: profileData,
          roleStr: roleStr,
        );

        if (businessId != null) {
          await _cacheBusinessLocally(
            profileId: userId,
            businessId: businessId,
            businessData: businessData,
            businessLine: businessLine,
          );
        }
      }

      // ── 6. Save session ────────────────────────────────────────────────────
      final session = SessionData(
        userId: userId,
        fullName: profileData['full_name'] as String? ?? '',
        username: profileData['username'] as String?,
        email: profileData['email'] as String? ?? email,
        phone: profileData['phone'] as String? ?? '',
        role: roleStr,
        isOfflineSession: false,
        businessId: businessId,
        businessName: businessName,
        permitNumber: permitNumber,
        registrationNumber: registrationNumber,
        street: street,
        totalRooms: totalRooms,
        permitFileUrl: permitFileUrl,
        validIdUrl: validIdUrl,
        businessType: businessType,
        status: status,
        remarks: remarks,
        region: region,
        cityMunicipality: cityMunicipality,
        province: province,
        barangay: barangay,
        tradename: tradename,
        businessLine: businessLine,
        ownerFirstName: ownerFirstName,
        ownerLastName: ownerLastName,
        ownerMiddleName: ownerMiddleName,
      );

      await SessionService.instance.save(session);
      await SessionService.instance.loadAndCache();

      return LoginResult.ok(role);
    } on AuthException catch (e) {
      return LoginResult.err(_friendlyAuthError(e.message));
    } catch (e) {
      debugPrint('❌ Login error: ${e.runtimeType} — $e');
      final msg = e.toString().toLowerCase();
      if (msg.contains('network')) {
        return LoginResult.err(
          'Network problem. Please check your internet and try again.',
        );
      }
      if (msg.contains('socket') ||
          msg.contains('database') ||
          msg.contains('db') ||
          msg.contains('postgres')) {
        return LoginResult.err(
          'Server connection problem. The app could not reach the database service. Please try again later.',
        );
      }
      if (msg.contains('connection')) {
        return LoginResult.err(
          'Connection problem. Please check your internet and try again.',
        );
      }
      return LoginResult.err('Something went wrong. Please try again.');
    }
  }

  // ===========================================================================
  // FORGOT PASSWORD  ─  Step 1: Validate email + send OTP
  //
  // Accepts the email address directly (no username lookup).
  // Returns the trimmed email so the OTP modal can use it for verify/resend.
  //
  // Throws [LoginApiException] on any error.
  // ===========================================================================

  Future<String> sendForgotPasswordOtp({required String email}) async {
    final trimmed = email.trim().toLowerCase();
    if (trimmed.isEmpty) {
      throw const LoginApiException('Please enter your email address.');
    }
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(trimmed)) {
      throw const LoginApiException('Please enter a valid email address.');
    }

    // ── Send 6-digit OTP directly to the provided email ────────────────────
    try {
      await _supabase.auth.signInWithOtp(
        email: trimmed,
        shouldCreateUser: false,
      );
    } on AuthException catch (e) {
      throw LoginApiException('Could not send OTP: ${e.message}');
    } catch (e) {
      throw const LoginApiException('Failed to send OTP. Please try again.');
    }

    return trimmed;
  }

  // ===========================================================================
  // FORGOT PASSWORD  ─  Step 1b: Resend OTP (uses email directly)
  // ===========================================================================

  Future<void> resendForgotPasswordOtp({required String email}) async {
    try {
      await _supabase.auth.signInWithOtp(
        email: email,
        shouldCreateUser: false,
      );
    } on AuthException catch (e) {
      throw LoginApiException('Could not resend OTP: ${e.message}');
    } catch (e) {
      throw const LoginApiException('Failed to resend OTP. Please try again.');
    }
  }

  // ===========================================================================
  // FORGOT PASSWORD  ─  Step 2: Verify OTP
  // ===========================================================================

  Future<void> verifyForgotPasswordOtp({
    required String email,
    required String otp,
  }) async {
    final code = otp.trim();
    if (code.isEmpty) {
      throw const LoginApiException(
        'Please enter the 6-digit code sent to your email.',
      );
    }
    if (code.length != 6 || !RegExp(r'^\d{6}$').hasMatch(code)) {
      throw const LoginApiException('OTP must be exactly 6 digits.');
    }

    try {
      final response = await _supabase.auth.verifyOTP(
        email: email,
        token: code,
        type: OtpType.email,
      );
      if (response.user == null) {
        throw const LoginApiException(
          'OTP verification failed. Please request a new code.',
        );
      }
    } on LoginApiException {
      rethrow;
    } on AuthException catch (e) {
      final msg = e.message.toLowerCase();
      if (msg.contains('expired')) {
        throw const LoginApiException(
          'OTP has expired. Please request a new code.',
        );
      }
      if (msg.contains('invalid')) {
        throw const LoginApiException(
          'Incorrect OTP. Please check the code and try again.',
        );
      }
      throw LoginApiException('OTP verification failed: ${e.message}');
    } catch (e) {
      throw LoginApiException('Unexpected error during OTP verification: $e');
    }
  }

  // ===========================================================================
  // FORGOT PASSWORD  ─  Step 3: Reset password (no old password required)
  //
  // The user is already authenticated via OTP at this point, so
  // updateUser() works without the old credential.
  // ===========================================================================

  Future<void> resetPassword({
    required String newPassword,
    required String confirmPassword,
  }) async {
    // ── Client-side validation ─────────────────────────────────────────────
    if (newPassword.isEmpty) {
      throw const LoginApiException('New password is required.');
    }
    if (newPassword.length < 8) {
      throw const LoginApiException(
        'Password must be at least 8 characters long.',
      );
    }
    if (!RegExp(r'[A-Z]').hasMatch(newPassword)) {
      throw const LoginApiException(
        'Password must contain at least one uppercase letter.',
      );
    }
    if (!RegExp(r'[0-9]').hasMatch(newPassword)) {
      throw const LoginApiException(
        'Password must contain at least one number.',
      );
    }
    if (!RegExp(r"[!@#$%^&*()\-_=+\[\]{};:',.<>?/\\|`~]")
        .hasMatch(newPassword)) {
      throw const LoginApiException(
        'Password must contain at least one special character (e.g. @, #, !).',
      );
    }
    if (newPassword != confirmPassword) {
      throw const LoginApiException('Passwords do not match.');
    }

    // ── Update via Supabase Auth ───────────────────────────────────────────
    try {
      await _supabase.auth.updateUser(UserAttributes(password: newPassword));
    } on AuthException catch (e) {
      throw LoginApiException('Password reset failed: ${e.message}');
    } catch (e) {
      throw LoginApiException('Unexpected error resetting password: $e');
    }
  }

  // ===========================================================================
  // OFFLINE LOGIN
  // ===========================================================================

  Future<LoginResult> _offlineLogin({
    required String username,
    required String password,
  }) async {
    try {
      final profile = await OfflineAuthService.instance.verifyOfflineLogin(
        username: username,
        password: password,
      );

      if (profile == null) {
        return LoginResult.err(
          'You\'re offline. Please connect to the internet to sign in for the first time.',
        );
      }

      final roleStr = profile['role'] as String? ?? 'business';

      if (roleStr == 'admin') {
        return LoginResult.err(
          'Offline login is only available for business accounts. Please connect to the internet to sign in as admin.',
        );
      }

      final userId = profile['id'] as String;
      final role = roleStr == 'admin' ? Role.admin : Role.business;

      final db = await LocalDatabase.instance.database;
      final businesses = await db.query(
        LocalDatabase.tableLocalBusinesses,
        where: 'profile_id = ?',
        whereArgs: [userId],
        limit: 1,
      );

      String? businessId;
      String? businessName;
      String? permitNumber;
      String? registrationNumber;
      String? street;
      int? totalRooms;
      String? businessType;
      String? status;
      String? remarks;
      String? region;
      String? cityMunicipality;
      String? province;
      String? barangay;
      String? tradename;
      List<String>? businessLine;
      String? ownerFirstName;
      String? ownerLastName;
      String? ownerMiddleName;

      if (businesses.isNotEmpty) {
        final b = businesses.first;
        businessId = b['id'] as String?;
        businessName = b['business_name'] as String?;
        permitNumber = b['permit_number'] as String?;
        registrationNumber = b['registration_number'] as String?;
        street = b['street'] as String?;
        totalRooms = b['total_rooms'] as int?;
        businessType = b['business_type'] as String?;
        status = b['status'] as String?;
        remarks = null;
        region = b['region'] as String?;
        cityMunicipality = b['city_municipality'] as String?;
        province = b['province'] as String?;
        barangay = b['barangay'] as String?;
        tradename = b['tradename'] as String?;
        ownerFirstName = b['owner_first_name'] as String?;
        ownerLastName = b['owner_last_name'] as String?;
        ownerMiddleName = b['owner_middle_name'] as String?;

        final rawLine = b['business_line'] as String?;
        if (rawLine != null) {
          try {
            businessLine = (jsonDecode(rawLine) as List<dynamic>)
                .map((v) => v.toString())
                .toList();
          } catch (_) {
            businessLine = null;
          }
        }
      }

      final session = SessionData(
        userId: userId,
        fullName: profile['full_name'] as String? ?? '',
        username: profile['username'] as String?,
        email: profile['email'] as String? ?? '',
        phone: profile['phone'] as String? ?? '',
        role: roleStr,
        isOfflineSession: true,
        businessId: businessId,
        businessName: businessName,
        permitNumber: permitNumber,
        registrationNumber: registrationNumber,
        street: street,
        totalRooms: totalRooms,
        businessType: businessType,
        status: status,
        remarks: remarks,
        region: region,
        cityMunicipality: cityMunicipality,
        province: province,
        barangay: barangay,
        tradename: tradename,
        businessLine: businessLine,
        ownerFirstName: ownerFirstName,
        ownerLastName: ownerLastName,
        ownerMiddleName: ownerMiddleName,
      );

      await SessionService.instance.save(session);
      await SessionService.instance.loadAndCache();

      return LoginResult.ok(role);
    } catch (e) {
      debugPrint('❌ Offline login error: $e');
      return LoginResult.err('Offline login failed. Please try again.');
    }
  }

  // ===========================================================================
  // Cache helpers
  // ===========================================================================

  Future<void> _cacheProfileLocally({
    required String userId,
    required String username,
    required String password,
    required Map<String, dynamic> profileData,
    required String roleStr,
  }) async {
    await OfflineAuthService.instance.cacheProfile(
      id: userId,
      username: username,
      password: password,
      fullName: profileData['full_name'] as String?,
      email: profileData['email'] as String?,
      phone: profileData['phone'] as String?,
      role: roleStr,
    );
  }

  Future<void> _cacheBusinessLocally({
    required String profileId,
    required String businessId,
    required Map<String, dynamic> businessData,
    required List<String>? businessLine,
  }) async {
    final db = await LocalDatabase.instance.database;
    await db.insert(
      LocalDatabase.tableLocalBusinesses,
      {
        'id': businessId,
        'profile_id': profileId,
        'business_name': businessData['business_name'],
        'status': businessData['status'],
        'permit_number': businessData['permit_number'],
        'registration_number': businessData['registration_number'],
        'street': businessData['street'],
        'total_rooms': businessData['total_rooms'],
        'region': businessData['region'],
        'city_municipality': businessData['city_municipality'],
        'province': businessData['province'],
        'barangay': businessData['barangay'],
        'tradename': businessData['tradename'],
        'business_line': businessLine != null ? jsonEncode(businessLine) : null,
        'owner_first_name': businessData['owner_first_name'],
        'owner_last_name': businessData['owner_last_name'],
        'owner_middle_name': businessData['owner_middle_name'],
        'business_type': businessData['business_type'],
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ===========================================================================
  // Helpers
  // ===========================================================================

  String _friendlyAuthError(String message) {
    final m = message.toLowerCase();
    if (m.contains('invalid') || m.contains('credentials')) {
      return 'Incorrect username or password.';
    }
    if (m.contains('email not confirmed')) {
      return 'Please confirm your email before signing in.';
    }
    if (m.contains('too many requests')) {
      return 'Too many attempts. Please wait a moment and try again.';
    }
    return message;
  }

  Future<void> logout() async {
    await SessionService.instance.clear();
    if (ConnectivityService.instance.isOnline) {
      await _supabase.auth.signOut();
    }
  }
}