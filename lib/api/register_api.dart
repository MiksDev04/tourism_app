import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tourism_app/core/enums/business_enums.dart';
import 'package:uuid/uuid.dart';

class RegisterResult {
  final bool success;
  final String? error;

  const RegisterResult.ok() : success = true, error = null;
  const RegisterResult.err(this.error) : success = false;
}

class RegisterApi {
  final _supabase = Supabase.instance.client;

  Future<RegisterResult> register({
    required String fullName,
    required String username,
    required String email,
    required String password,
    required String phoneNumber,
    required String businessName,
    required BusinessType businessType,
    required List<String> businessLine,
    required String ownerFirstName,
    required String ownerMiddleName,
    required String ownerLastName,
    required int totalRooms,
    required String permitNumber,
    required String registrationNumber,
    required String street,
    required String barangay,
    required String cityMunicipality,
    required String province,
    required String region,
    required File permitFile,
    required File validIdFile,
  }) async {
    try {
      // ── 1. Validate inputs before any network call ─────────────────────
      final validationError = _validate(
        fullName: fullName,
        username: username,
        email: email,
        phoneNumber: phoneNumber,
        businessName: businessName,
        ownerFirstName: ownerFirstName,
        ownerLastName: ownerLastName,
        businessLine: businessLine,
        totalRooms: totalRooms,
        permitNumber: permitNumber,
        registrationNumber: registrationNumber,
        street: street,
        barangay: barangay,
        cityMunicipality: cityMunicipality,
        province: province,
        region: region,
      );
      if (validationError != null) return RegisterResult.err(validationError);

      final normalizedUsername = username.trim().toLowerCase();

      final usernameLookup = await _supabase
          .from('profiles')
          .select('id')
          .eq('username', normalizedUsername)
          .maybeSingle();

      if (usernameLookup != null) {
        return const RegisterResult.err('Username is already taken.');
      }

      // ── 2. Sign up via Supabase Auth ───────────────────────────────────
      final authResponse = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName, 'phone': phoneNumber},
      );

      final authUser = authResponse.user;
      if (authUser == null) {
        return const RegisterResult.err(
          'Registration failed. Please try again.',
        );
      }

      // ── 3. Upload files to Supabase Storage ────────────────────────────
      final permitUrl = await _uploadFile(
        file: permitFile,
        bucket: 'business-permits',
        userId: authUser.id,
        label: 'permit',
      );
      if (permitUrl == null) {
        return const RegisterResult.err('Failed to upload business permit.');
      }

      final validIdUrl = await _uploadFile(
        file: validIdFile,
        bucket: 'valid-ids',
        userId: authUser.id,
        label: 'valid_id',
      );
      if (validIdUrl == null) {
        return const RegisterResult.err("Failed to upload owner's valid ID.");
      }

      // ── 4. Upsert Profile directly via Supabase ────────────────────────
      await _supabase.from('profiles').upsert({
        'id': authUser.id,
        'full_name': fullName,
        'username': normalizedUsername,
        'email': email,
        'phone': phoneNumber,
        'role': 'business',
      });

      // ── 5. Insert Business directly via Supabase ───────────────────────
      final businessId = const Uuid().v4();
      await _supabase.from('businesses').insert({
        'id': businessId,
        'profile_id': authUser.id,
        'business_name': businessName,
        'business_type': _businessTypeDbValue(businessType),
        'owner_first_name': ownerFirstName,
        'owner_middle_name': ownerMiddleName.trim().isEmpty
            ? null
            : ownerMiddleName,
        'owner_last_name': ownerLastName,
        'business_line': businessLine,
        'total_rooms': totalRooms,
        'permit_number': permitNumber,
        'registration_number': registrationNumber,
        'street': street,
        'barangay': barangay,
        'city_municipality': cityMunicipality,
        'province': province,
        'region': region,
        'permit_file_url': permitUrl,
        'valid_id_url': validIdUrl,
        'status': 'pending',
      });

      debugPrint('✅ Profile and Business saved to Supabase');
      return const RegisterResult.ok();
    } on AuthException catch (e) {
      return RegisterResult.err(_friendlyAuthError(e.message));
    } catch (e) {
      final message = e.toString().toLowerCase();
      if (message.contains('username') &&
          (message.contains('duplicate') ||
              message.contains('unique') ||
              message.contains('already exists'))) {
        return const RegisterResult.err('Username is already taken.');
      }
      return RegisterResult.err('An unexpected error occurred: $e');
    }
  }

  String _businessTypeDbValue(BusinessType businessType) {
    switch (businessType) {
      case BusinessType.corporation:
        return 'corporation';
      case BusinessType.partnership:
        return 'partnership';
      case BusinessType.soleProprietorship:
        return 'sole_proprietorship';
    }
  }

  // ── File upload helper ───────────────────────────────────────────────────

  Future<String?> _uploadFile({
    required File file,
    required String bucket,
    required String userId,
    required String label,
  }) async {
    try {
      final ext = file.path.split('.').last;
      final path =
          '$userId/${label}_${DateTime.now().millisecondsSinceEpoch}.$ext';

      await _supabase.storage
          .from(bucket)
          .upload(path, file, fileOptions: const FileOptions(upsert: true));

      return _supabase.storage.from(bucket).getPublicUrl(path);
    } catch (e) {
      debugPrint('❌ Upload failed [$bucket/$label]: $e');
      return null;
    }
  }

  // ── Field-level validation ───────────────────────────────────────────────

  String? _validate({
    required String fullName,
    required String username,
    required String email,
    required String phoneNumber,
    required String businessName,
    required String ownerFirstName,
    required String ownerLastName,
    required List<String> businessLine,
    required int totalRooms,
    required String permitNumber,
    required String registrationNumber,
    required String street,
    required String barangay,
    required String cityMunicipality,
    required String province,
    required String region,
  }) {
    final usernameRe = RegExp(r'^[a-zA-Z0-9_]{3,20}$');
    final emailRe = RegExp(r'^[\w.+\-]+@[\w\-]+\.[a-zA-Z]{2,}$');
    final phoneRe = RegExp(r'^(09|\+639)\d{9}$');
    const allowedBusinessLines = {
      'hotel',
      'resort',
      'motel',
      'pension_inn',
      'youth_hostel',
      'apartment',
      'others',
    };
    final strippedPhone = phoneNumber.replaceAll(RegExp(r'[-\s]'), '');

    if (fullName.trim().isEmpty) return 'Full name is required.';
    if (username.trim().isEmpty) return 'Username is required.';
    if (!usernameRe.hasMatch(username.trim())) {
      return 'Username must be 3-20 characters using letters, numbers, or underscores.';
    }
    if (!emailRe.hasMatch(email.trim())) return 'Enter a valid email address.';
    if (!phoneRe.hasMatch(strippedPhone)) return 'Invalid phone number format.';
    if (businessName.trim().isEmpty) return 'Business name is required.';
    if (businessLine.isEmpty) return 'Select at least one business line.';
    if (businessLine.any((line) => !allowedBusinessLines.contains(line))) {
      return 'Invalid business line selected.';
    }
    if (ownerFirstName.trim().isEmpty) return 'Owner first name is required.';
    if (ownerLastName.trim().isEmpty) return 'Owner last name is required.';
    if (totalRooms <= 0) return 'Total rooms must be at least 1.';
    if (permitNumber.trim().isEmpty) return 'Permit number is required.';
    if (registrationNumber.trim().isEmpty) {
      return 'Registration number is required.';
    }
    if (street.trim().isEmpty) return 'Street is required.';
    if (barangay.trim().isEmpty) return 'Barangay is required.';
    if (cityMunicipality.trim().isEmpty)
      return 'City / Municipality is required.';
    if (province.trim().isEmpty) return 'Province is required.';
    if (region.trim().isEmpty) return 'Region is required.';
    return null;
  }

  // ── Human-readable Supabase Auth errors ─────────────────────────────────

  String _friendlyAuthError(String message) {
    final m = message.toLowerCase();
    if (m.contains('username') &&
        (m.contains('duplicate') || m.contains('already exists'))) {
      return 'Username is already taken.';
    }
    if (m.contains('already registered') ||
        m.contains('already been registered')) {
      return 'An account with this email already exists.';
    }
    if (m.contains('invalid email')) {
      return 'Please enter a valid email address.';
    }
    if (m.contains('password')) {
      return 'Password must be at least 6 characters.';
    }
    return message;
  }
}
