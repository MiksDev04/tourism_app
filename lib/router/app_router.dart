import 'package:flutter/material.dart';
import 'package:tourism_app/core/services/session_service.dart';

import '../ui/shared/pages/login_page.dart';
import '../ui/shared/pages/register_page.dart';
import '../ui/admin/pages/admin_dashboard_page.dart';
import '../ui/admin/pages/admin_accommodations_page.dart';
import '../ui/admin/pages/admin_reports_page.dart';
import '../ui/admin/pages/admin_messages_page.dart';
import '../ui/admin/pages/admin_compliance_page.dart';
import '../ui/admin/pages/admin_profile_page.dart';
import '../ui/business/pages/business_dashboard_page.dart';
import '../ui/business/pages/business_guest_entry_page.dart';
import '../ui/business/pages/business_guest_records_page.dart';
import '../ui/business/pages/business_reports_page.dart';
import '../ui/business/pages/business_messages_page.dart';
import '../ui/business/pages/business_profile_page.dart';

// ─── Route Names ──────────────────────────────────────────────────────────────

abstract final class AppRoutes {
  static const login = '/login';
  static const register = '/register';
  static const adminDashboard = '/admin/dashboard';
  static const adminAccommodations = '/admin/accommodations';
  static const adminMessages = '/admin/messages';
  static const adminReports = '/admin/reports';
  static const adminCompliance = '/admin/compliance';
  static const adminProfile = '/admin/profile';
  static const businessDashboard = '/business/dashboard';
  static const businessGuestEntry = '/business/guest-entry';
  static const businessGuestRecord = '/business/guest-records';
  static const businessReports = '/business/reports';
  static const businessMessages = '/business/messages';
  static const businessProfile = '/business/profile';
}

// ─── Offline-allowed routes ───────────────────────────────────────────────────
//
// Business users in offline mode may only visit these routes.
// Everything else shows OfflineRestrictedPage.

const _offlineAllowedRoutes = {
  AppRoutes.businessDashboard,
  AppRoutes.businessGuestEntry,
  AppRoutes.businessGuestRecord,
};

// ─── Route Permissions ────────────────────────────────────────────────────────

abstract final class _RoutePermissions {
  static const Map<String, Set<String>> _map = {
    AppRoutes.login: {},
    AppRoutes.register: {},
    AppRoutes.adminDashboard: {'admin'},
    AppRoutes.adminAccommodations: {'admin'},
    AppRoutes.adminMessages: {'admin'},
    AppRoutes.adminReports: {'admin'},
    AppRoutes.adminCompliance: {'admin'},
    AppRoutes.adminProfile: {'admin'},
    AppRoutes.businessDashboard: {'business'},
    AppRoutes.businessGuestEntry: {'business'},
    AppRoutes.businessGuestRecord: {'business'},
    AppRoutes.businessReports: {'business'},
    AppRoutes.businessMessages: {'business'},
    AppRoutes.businessProfile: {'business'},
  };

  /// Returns null if allowed, or a sentinel string if blocked.
  static String? guard(String routeName) {
    final allowed = _map[routeName];
    if (allowed == null) return null;
    if (allowed.isEmpty) return null; // public route

    final session = SessionService.instance.current;
    if (session == null) return '__login__';
    if (!allowed.contains(session.role)) return '__denied__';

    // ── Offline guard ──────────────────────────────────────────────────────
    // Admin never uses offline mode, so we only check business sessions.
    if (session.isOfflineSession &&
        !_offlineAllowedRoutes.contains(routeName)) {
      return '__offline__';
    }

    return null;
  }
}

// ─── Router ───────────────────────────────────────────────────────────────────

abstract final class AppRouter {
  static String get initialRoute {
    final session = SessionService.instance.current;
    if (session == null) return AppRoutes.login;
    return session.role == 'admin'
        ? AppRoutes.adminDashboard
        : AppRoutes.businessDashboard;
  }

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final routeName = settings.name ?? '';

    // ── Auth + offline guard ─────────────────────────────────────────────────
    final guardResult = _RoutePermissions.guard(routeName);

    if (guardResult == '__login__') {
      return _fade(
        const LoginPage(),
        const RouteSettings(name: AppRoutes.login),
      );
    }
    if (guardResult == '__denied__') {
      return _fade(AccessDeniedPage(attemptedRoute: routeName), settings);
    }
    if (guardResult == '__offline__') {
      return _fade(OfflineRestrictedPage(), settings);
    }

    // ── Normal routing ───────────────────────────────────────────────────────
    return switch (routeName) {
      AppRoutes.login => _fade(const LoginPage(), settings),
      AppRoutes.register => _fade(const RegisterPage(), settings),
      AppRoutes.adminDashboard => _fade(const AdminDashboardPage(), settings),
      AppRoutes.adminAccommodations => _fade(
        const AdminAccommodationsPage(),
        settings,
      ),
      AppRoutes.adminMessages => _fade(const AdminMessagesPage(), settings),
      AppRoutes.adminReports => _fade(const AdminReportsPage(), settings),
      AppRoutes.adminProfile => _fade(const AdminProfilePage(), settings),
      AppRoutes.adminCompliance => _fade(const AdminCompliancePage(), settings),
      AppRoutes.businessDashboard => _fade(
        const BusinessDashboardPage(),
        settings,
      ),
      AppRoutes.businessGuestEntry => _fade(
        const BusinessGuestEntryPage(),
        settings,
      ),
      AppRoutes.businessGuestRecord => _fade(
        const BusinessGuestRecordsPage(),
        settings,
      ),
      AppRoutes.businessMessages => _fade(
        const BusinessMessagesPage(),
        settings,
      ),
      AppRoutes.businessReports => _fade(const BusinessReportsPage(), settings),
      AppRoutes.businessProfile => _fade(const BusinessProfilePage(), settings),
      _ => _notFound(settings),
    };
  }

  static PageRouteBuilder<dynamic> _fade(Widget page, RouteSettings settings) =>
      PageRouteBuilder(
        settings: settings,
        pageBuilder: (_, __, ___) => page,
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 180),
      );

  static Route<dynamic> _notFound(RouteSettings settings) => MaterialPageRoute(
    settings: settings,
    builder: (_) => _NotFoundPage(routeName: settings.name ?? '?'),
  );
}

// ─── Offline Restricted Page ──────────────────────────────────────────────────

class OfflineRestrictedPage extends StatelessWidget {
  const OfflineRestrictedPage({super.key});

  String? get role => SessionService.instance.current?.role;


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050D1A),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.wifi_off_rounded,
                color: Color(0xFF8A9BB5),
                size: 52,
              ),
              const SizedBox(height: 16),
              const Text(
                'No Internet Connection',
                style: TextStyle(
                  color: Color(0xFFFFFFFF),
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'This feature requires an internet connection.\nPlease reconnect to access it.',
                style: TextStyle(
                  color: Color(0xFF8A9BB5),
                  fontSize: 13,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              TextButton(
                onPressed: () => Navigator.pushReplacementNamed(
                  context,
                  role == 'admin'
                      ? AppRoutes.login
                      : AppRoutes.businessDashboard,
                ),
                child: const Text(
                  '← Back to Dashboard',
                  style: TextStyle(color: Color(0xFF00D4FF)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Access Denied Page ───────────────────────────────────────────────────────

class AccessDeniedPage extends StatelessWidget {
  const AccessDeniedPage({super.key, required this.attemptedRoute});
  final String attemptedRoute;

  String get _homeRoute {
    final role = SessionService.instance.current?.role;
    return role == 'admin'
        ? AppRoutes.adminDashboard
        : AppRoutes.businessDashboard;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050D1A),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.lock_outline_rounded,
              color: Color(0xFFFF4D6A),
              size: 52,
            ),
            const SizedBox(height: 16),
            const Text(
              'Access Denied',
              style: TextStyle(
                color: Color(0xFFFFFFFF),
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You don\'t have permission to view "$attemptedRoute".',
              style: const TextStyle(color: Color(0xFF8A9BB5), fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            TextButton(
              onPressed: () =>
                  Navigator.pushReplacementNamed(context, _homeRoute),
              child: const Text(
                'Go to my Dashboard',
                style: TextStyle(color: Color(0xFF00D4FF)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── 404 Page ─────────────────────────────────────────────────────────────────

class _NotFoundPage extends StatelessWidget {
  const _NotFoundPage({required this.routeName});
  final String routeName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050D1A),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Color(0xFFFF4D6A), size: 48),
            const SizedBox(height: 16),
            Text(
              'Route not found: $routeName',
              style: const TextStyle(color: Color(0xFF8A9BB5), fontSize: 14),
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () => Navigator.pushReplacementNamed(
                context,
                AppRouter.initialRoute,
              ),
              child: const Text(
                'Go to Dashboard',
                style: TextStyle(color: Color(0xFF00D4FF)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
