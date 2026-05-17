import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
    required String email,
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

    // ── 2. Authenticate ───────────────────────────────────────────────────
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        return LoginResult.err('Login failed. Please try again.');
      }

      final userId = response.user!.id;

      // ── 3. Fetch profile ────────────────────────────────────────────────
      final profileData = await _supabase
          .from('profiles')
          .select('role')
          .eq('id', userId)
          .maybeSingle();

      if (profileData == null) {
        return LoginResult.err('Profile not found. Please contact support.');
      }

      final roleStr = profileData['role'] as String?;
      if (roleStr == null) {
        return LoginResult.err('Profile not found. Please contact support.');
      }

      final role = roleStr == 'admin' ? Role.admin : Role.business;

      // ── 4. Business: check approval status ─────────────────────────────
      if (role == Role.business) {
        final businessData = await _supabase
            .from('businesses')
            .select('status')
            .eq('profile_id', userId)
            .maybeSingle();

        if (businessData == null) {
          return LoginResult.err(
            'Business profile not found. Please contact support.',
          );
        }

        final status = businessData['status'] as String? ?? 'pending';

        if (status == 'pending') {
          return LoginResult.err(
            'Your account is still pending approval. '
            'Please wait for an administrator to review your application.',
          );
        }

        if (status == 'rejected') {
          return LoginResult.err(
            'Your account application was not approved. '
            'Please contact support for assistance.',
          );
        }
      }

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
      return 'Incorrect email or password.';
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
    await _supabase.auth.signOut();
  }
}