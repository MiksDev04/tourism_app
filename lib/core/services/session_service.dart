import 'package:shared_preferences/shared_preferences.dart';

/// Holds the in-memory snapshot of the logged-in user's data.
class SessionData {
  final String userId;
  final String fullName;
  final String email;
  final String phone;
  final String role;

  // Business fields (null for admin accounts)
  final String? businessId;
  final String? businessName;
  final String? businessType;
  final String? ownerName;
  final String? status;

  const SessionData({
    required this.userId,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.role,
    this.businessId,
    this.businessName,
    this.businessType,
    this.ownerName,
    this.status,
  });

  /// Initials derived from full name, e.g. "Juan Dela Cruz" → "JD"
  String get initials {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  /// First name only, used as the short display name in the header.
  String get displayName {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    return parts.isNotEmpty ? parts.first : fullName;
  }
}

/// Persists and retrieves session data via SharedPreferences.
class SessionService {
  // ── Keys ──────────────────────────────────────────────────────────────────
  static const _kUserId       = 'session_user_id';
  static const _kFullName     = 'session_full_name';
  static const _kEmail        = 'session_email';
  static const _kPhone        = 'session_phone';
  static const _kRole         = 'session_role';
  static const _kBusinessId   = 'session_business_id';
  static const _kBusinessName = 'session_business_name';
  static const _kBusinessType = 'session_business_type';
  static const _kOwnerName    = 'session_owner_name';
  static const _kStatus       = 'session_status';

  // ── Singleton ─────────────────────────────────────────────────────────────
  SessionService._();
  static final SessionService instance = SessionService._();

  // ── Save ──────────────────────────────────────────────────────────────────

  Future<void> save(SessionData data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kUserId, data.userId);
    await prefs.setString(_kFullName, data.fullName);
    await prefs.setString(_kEmail, data.email);
    await prefs.setString(_kPhone, data.phone);
    await prefs.setString(_kRole, data.role);

    if (data.businessId != null) {
      await prefs.setString(_kBusinessId, data.businessId!);
    }
    if (data.businessName != null) {
      await prefs.setString(_kBusinessName, data.businessName!);
    }
    if (data.businessType != null) {
      await prefs.setString(_kBusinessType, data.businessType!);
    }
    if (data.ownerName != null) {
      await prefs.setString(_kOwnerName, data.ownerName!);
    }
    if (data.status != null) {
      await prefs.setString(_kStatus, data.status!);
    }
  }

  // ── Load ──────────────────────────────────────────────────────────────────
  Future<SessionData?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString(_kUserId);
    if (userId == null) return null; // nothing saved

    return SessionData(
      userId:       userId,
      fullName:     prefs.getString(_kFullName)     ?? '',
      email:        prefs.getString(_kEmail)        ?? '',
      phone:        prefs.getString(_kPhone)        ?? '',
      role:         prefs.getString(_kRole)         ?? 'business',
      businessId:   prefs.getString(_kBusinessId),
      businessName: prefs.getString(_kBusinessName),
      businessType: prefs.getString(_kBusinessType),
      ownerName:    prefs.getString(_kOwnerName),
      status:       prefs.getString(_kStatus),
    );
  }

  // ── Clear (on logout) ─────────────────────────────────────────────────────
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kUserId);
    await prefs.remove(_kFullName);
    await prefs.remove(_kEmail);
    await prefs.remove(_kPhone);
    await prefs.remove(_kRole);
    await prefs.remove(_kBusinessId);
    await prefs.remove(_kBusinessName);
    await prefs.remove(_kBusinessType);
    await prefs.remove(_kOwnerName);
    await prefs.remove(_kStatus);
  }

  // ── Quick in-memory getter (after load is called once) ───────────────────
  SessionData? _cached;
  SessionData? get current => _cached;

  Future<SessionData?> loadAndCache() async {
    _cached = await load();
    return _cached;
  }
}