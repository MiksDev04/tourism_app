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
          .select('full_name, phone, role, email')
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
      String? businessType;
      String? ownerName;
      String? status;

      if (role == Role.business) {
        final businessData = await _supabase
            .from('businesses')
            .select(
              'id, business_name, business_type, status, owner_first_name, owner_last_name',
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

        if (status == 'rejected') {
          return LoginResult.err(
            'Your account application was not approved. '
            'Please visit the tourism office for more information.',
          );
        }

        businessId = businessData['id'] as String?;
        businessName = businessData['business_name'] as String?;
        businessType = businessData['business_type'] as String?;

        // Combine first + last name since schema has no single owner_name column
        final firstName = businessData['owner_first_name'] as String? ?? '';
        final lastName = businessData['owner_last_name'] as String? ?? '';
        ownerName = '$firstName $lastName'.trim();
      }

      // ── 6. Persist session locally ─────────────────────────────────────
      final session = SessionData(
        userId: userId,
        fullName: profileData['full_name'] as String? ?? '',
        email: profileData['email'] as String? ?? email,
        phone: profileData['phone'] as String? ?? '',
        role: roleStr,
        businessId: businessId,
        businessName: businessName,
        businessType: businessType,
        ownerName: ownerName,
        status: status,
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
