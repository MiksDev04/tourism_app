import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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

class LoginApi {
  final _supabase = Supabase.instance.client;

  Future<LoginResult> login({
    required String username,
    required String password,
  }) async {
    // ── 1. Check internet ─────────────────────────────────────────────────
    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isEmpty || result.first.rawAddress.isEmpty) {
        return LoginResult.err(
          'No internet connection. Please go online to sign in.',
        );
      }
    } on SocketException catch (_) {
      return LoginResult.err(
        'No internet connection. Please go online to sign in.',
      );
    }

    try {
      // ── 2. Resolve username → email directly from profiles ────────────
      // ── 2. Resolve username → email via RPC ───────────────────────────
      final email =
          await _supabase.rpc(
                'get_email_by_username',
                params: {'p_username': username.trim().toLowerCase()},
              )
              as String?;

      if (email == null || email.isEmpty) {
        return LoginResult.err('No account found with that username.');
      }

      // ignore: unnecessary_null_comparison
      if (email == null || email.isEmpty) {
        return LoginResult.err(
          'Account has no email linked. Please contact support.',
        );
      }

      // ── 3. Authenticate with resolved email ───────────────────────────
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        return LoginResult.err('Login failed. Please try again.');
      }

      final userId = response.user!.id;

      // ── 4. Fetch full profile ──────────────────────────────────────────
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

      // ── 5. Business: check approval + fetch business row ───────────────
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

      if (role == Role.business) {
        final businessData = await _supabase
            .from('businesses')
            .select(
              'id, business_name, permit_number, registration_number, street, total_rooms, permit_file_url, valid_id_url, status, remarks, region, city_municipality, province, barangay, tradename, business_line, owner_first_name, owner_last_name, owner_middle_name, business_type',
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
            ?.map((value) => value.toString())
            .toList();
        ownerFirstName = businessData['owner_first_name'] as String?;
        ownerLastName = businessData['owner_last_name'] as String?;
        ownerMiddleName = businessData['owner_middle_name'] as String?;
      }

      // ── 6. Persist session locally ─────────────────────────────────────
      final session = SessionData(
        userId: userId,
        fullName: profileData['full_name'] as String? ?? '',
        username: profileData['username'] as String?,
        email: profileData['email'] as String? ?? email,
        phone: profileData['phone'] as String? ?? '',
        role: roleStr,
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
      return LoginResult.err('Something went wrong. Please try again.');
    }
  }

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
    await _supabase.auth.signOut();
  }
}
