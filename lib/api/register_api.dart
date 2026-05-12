import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tourism_app/brick/repository.dart';
import 'package:tourism_app/models/business.model.dart';
import 'package:tourism_app/models/profile.model.dart';

class RegisterResult {
  final bool success;
  final String? error;

  const RegisterResult({required this.success, this.error});
}

class RegisterApi {
  final _supabase = Supabase.instance.client;
  final _storage = Supabase.instance.client.storage;

  static const _bucket = 'business-documents';

  Future<RegisterResult> register({
    // Step 1 — Account
    required String fullName,
    required String email,
    required String password,
    // Step 2 — Business
    required String businessName,
    required BusinessType businessType,
    required String ownerName,
    required int totalRooms,
    required String permitNumber,
    required String registrationNumber,
    required String address,
    required String contactNumber,
    required File permitFile,
    required File validIdFile,
  }) async {
    try {
      // ── 1. Create auth user ──────────────────────────────────────────────
      final authResponse = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'contact_number': contactNumber, // store here instead
        },
      );

      final authUser = authResponse.user;
      if (authUser == null) {
        return const RegisterResult(
          success: false,
          error: 'Registration failed. Please try again.',
        );
      }

      final userId = authUser.id;
      final now = DateTime.now().toIso8601String();

      // ── 2. Upload files ──────────────────────────────────────────────────
      final permitFileUrl = await _uploadFile(
        file: permitFile,
        path: 'permits/$userId/${_fileName(permitFile)}',
      );

      final validIdUrl = await _uploadFile(
        file: validIdFile,
        path: 'valid-ids/$userId/${_fileName(validIdFile)}',
      );

      // ── 3. Create Profile ────────────────────────────────────────────────
      final profile = Profile(
        id: userId, // matches auth.users id
        fullName: fullName,
        role: 'business',
        createdAt: now,
        updatedAt: now,
      );

      await Repository().upsert<Profile>(profile);

      // ── 4. Create Business ───────────────────────────────────────────────
      final business = Business(
        profile: profile,
        businessName: businessName,
        businessType: businessType,
        ownerName: ownerName,
        totalRooms: totalRooms,
        permitNumber: permitNumber,
        registrationNumber: registrationNumber,
        address: address,
        permitFileUrl: permitFileUrl,
        validIdUrl: validIdUrl,
        status: BusinessStatus.pending,
        createdAt: now,
        updatedAt: now,
      );

      await Repository().upsert<Business>(business);

      return const RegisterResult(success: true);
    } on AuthException catch (e) {
      return RegisterResult(success: false, error: e.message);
    } on StorageException catch (e) {
      return RegisterResult(
        success: false,
        error: 'File upload failed: ${e.message}',
      );
    } catch (e) {
      return RegisterResult(success: false, error: e.toString());
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Future<String> _uploadFile({required File file, required String path}) async {
    final bytes = await file.readAsBytes();
    final mimeType = _mimeType(file.path.split('.').last);

    await _storage
        .from(_bucket)
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: mimeType, upsert: true),
        );

    return _storage.from(_bucket).getPublicUrl(path);
  }

  String _fileName(File file) {
    final ext = file.path.split('.').last;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '$timestamp.$ext';
  }

  String _mimeType(String ext) {
    switch (ext.toLowerCase()) {
      case 'pdf':
        return 'application/pdf';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      default:
        return 'application/octet-stream';
    }
  }
}
